import Foundation

class GoogleBooksService {
    static func fetchBookByISBN(isbn: String) async throws -> LibrarianBook {
        // Format the ISBN by removing any spaces or hyphens
        let formattedISBN = isbn.replacingOccurrences(of: "[- ]", with: "", options: .regularExpression)
        
        // Create the URL for Google Books API request
        guard let url = URL(string: "https://www.googleapis.com/books/v1/volumes?q=isbn:\(formattedISBN)") else {
            throw URLError(.badURL)
        }
        
        // Create a URLRequest with timeout
        var request = URLRequest(url: url)
        request.timeoutInterval = 15 // Set a reasonable timeout
        
        // Use a custom URLSession with better timeout handling
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 15
        sessionConfig.timeoutIntervalForResource = 30
        let session = URLSession(configuration: sessionConfig)
        
        do {
            // Fetch the data from the API
            let (data, httpResponse) = try await session.data(for: request)
            
            // Check for valid HTTP response
            guard let httpResponse = httpResponse as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            // Check for successful response code
            guard (200...299).contains(httpResponse.statusCode) else {
                throw NSError(
                    domain: "GoogleBooksService", 
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "Google Books API error with status code: \(httpResponse.statusCode)"]
                )
            }
            
            // Decode the response using the GoogleBooksAPIResponse format needed for this specific endpoint
            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(GoogleBooksAPIResponse.self, from: data)
            
            // Check if we got any results
            guard let bookItem = apiResponse.items?.first else {
                throw NSError(domain: "BookService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No book found with this ISBN"])
            }
            
            let bookInfo = bookItem.volumeInfo
            
            // Process the image URL: convert HTTP to HTTPS and ensure proper encoding
            var imageLink: String? = nil
            if let thumbnail = bookInfo.imageLinks?.thumbnail {
                // Convert HTTP URLs to HTTPS for App Transport Security
                let processedURL = thumbnail.replacingOccurrences(of: "http://", with: "https://")
                
                // Handle common URL encoding issues
                if let urlComponents = URLComponents(string: processedURL) {
                    // Properly encode URL components
                    imageLink = urlComponents.url?.absoluteString
                } else {
                    // If URLComponents fails, try percent-encoding the URL
                    imageLink = processedURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                }
                
                // Print the processed URL for debugging (can be removed later)
                print("Original thumbnail URL: \(thumbnail)")
                print("Processed image URL: \(imageLink ?? "nil")")
            }
            
            // Common book genres list
            let availableGenres = ["Science", "Humanities", "Business", "Medicine", "Law", 
                                   "Education", "Arts", "Religion", "Mathematics", "Technology", 
                                   "Reference", "Fiction", "Non-Fiction", "Literature"]
            
            // Enhance the description with additional information for genre prediction
            var enhancedDescription = bookInfo.description ?? ""
            
            // Append categories from Google Books if available
            if let categories = bookInfo.categories, !categories.isEmpty {
                enhancedDescription += " Categories: " + categories.joined(separator: ", ")
            }
            
            // If we have authors, try to fetch more information about their typical genres
            var authorContext = ""
            if let authors = bookInfo.authors, !authors.isEmpty {
                // Only process the first author for efficiency
                let authorName = authors[0]
                
                do {
                    // Try to fetch more books by this author to determine their typical genre
                    let authorInfo = try await fetchAuthorInformation(authorName: authorName)
                    if !authorInfo.isEmpty {
                        authorContext = " Author context: " + authorInfo
                        enhancedDescription += authorContext
                    }
                } catch {
                    print("Could not fetch additional author information: \(error.localizedDescription)")
                }
            }
            
            // Predict the genre using the GenrePredictionService with enhanced description
            let predictedGenre = try await GenrePredictionService.shared.predictGenre(
                title: bookInfo.title,
                description: enhancedDescription,
                authors: bookInfo.authors ?? [],
                availableGenres: availableGenres
            )
            
            return LibrarianBook(
                title: bookInfo.title,
                author: bookInfo.authors ?? [],
                genre: predictedGenre, // Using predicted genre instead of "Uncategorized"
                publicationDate: bookInfo.publishedDate ?? "Unknown Date",
                totalCopies: 1, // Default value
                availableCopies: 1, // Default value
                ISBN: formattedISBN,
                Description: bookInfo.description,
                shelfLocation: nil, // To be set by librarian
                dateAdded: Date(),
                publisher: bookInfo.publisher,
                imageLink: imageLink
            )
        } catch let urlError as URLError {
            if urlError.code == .timedOut {
                throw NSError(domain: "GoogleBooksService", code: 408, 
                              userInfo: [NSLocalizedDescriptionKey: "Google Books request timed out. Please try again."])
            } else if urlError.code == .notConnectedToInternet {
                throw NSError(domain: "GoogleBooksService", code: 503, 
                              userInfo: [NSLocalizedDescriptionKey: "No internet connection available."])
            } 
            throw urlError
        } catch let decodingError as DecodingError {
            throw NSError(
                domain: "GoogleBooksService", 
                code: 422, 
                userInfo: [NSLocalizedDescriptionKey: "Error parsing book data: \(decodingError.localizedDescription)"]
            )
        } catch {
            throw error
        }
    }

    /// Fetches additional information about an author to help with genre prediction
    private static func fetchAuthorInformation(authorName: String) async throws -> String {
        // Create a URL-safe version of the author name
        guard let encodedAuthor = authorName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return ""
        }
        
        // Create the URL for Google Books API request for author's works
        guard let url = URL(string: "https://www.googleapis.com/books/v1/volumes?q=inauthor:\(encodedAuthor)&maxResults=5") else {
            return ""
        }
        
        // Create a URLRequest with timeout
        var request = URLRequest(url: url)
        request.timeoutInterval = 10 // Shorter timeout for secondary requests
        
        // Use a custom URLSession with better timeout handling
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 10
        sessionConfig.timeoutIntervalForResource = 20
        let session = URLSession(configuration: sessionConfig)
        
        do {
            // Fetch the data from the API
            let (data, httpResponse) = try await session.data(for: request)
            
            // Check for valid HTTP response
            guard let httpResponse = httpResponse as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                // Return empty string instead of throwing an error for this optional enhancement
                print("HTTP error when fetching author information")
                return ""
            }
            
            // Decode the response
            let decoder = JSONDecoder()
            let authorBooksResponse = try decoder.decode(GoogleBooksAPIResponse.self, from: data)
            
            // Extract categories from the author's books
            var categories = Set<String>()
            var bookTitles = [String]()
            
            if let items = authorBooksResponse.items {
                for item in items {
                    if let bookCategories = item.volumeInfo.categories {
                        for category in bookCategories {
                            categories.insert(category)
                        }
                    }
                    bookTitles.append(item.volumeInfo.title)
                }
            }
            
            // Construct the author context
            var authorContext = "Author \(authorName) has written: " + bookTitles.joined(separator: ", ")
            
            if !categories.isEmpty {
                authorContext += ". Their books are typically categorized as: " + categories.joined(separator: ", ")
            }
            
            return authorContext
        } catch {
            // Since this is an enhancement and not critical, return empty string instead of throwing
            print("Error fetching author information: \(error.localizedDescription)")
            return ""
        }
    }
}

// Response models specifically for the Google Books API volumes endpoint
// This is different from the GoogleBooksResponse in Models.swift
struct GoogleBooksAPIResponse: Decodable {
    let items: [BookItem]?
}

struct BookItem: Decodable {
    let volumeInfo: VolumeInfo
}

struct VolumeInfo: Decodable {
    let title: String
    let authors: [String]?
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let categories: [String]?
    let imageLinks: ImageLinks?
}

struct ImageLinks: Decodable {
    let thumbnail: String?
} 
