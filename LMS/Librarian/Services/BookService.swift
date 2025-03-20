import Foundation

class BookService {
    static func fetchBookByISBN(isbn: String) async throws -> LibrarianBook {
        // Format the ISBN by removing any spaces or hyphens
        let formattedISBN = isbn.replacingOccurrences(of: "[- ]", with: "", options: .regularExpression)
        
        // Create the URL for Google Books API request
        guard let url = URL(string: "https://www.googleapis.com/books/v1/volumes?q=isbn:\(formattedISBN)") else {
            throw URLError(.badURL)
        }
        
        // Fetch the data from the API
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // Decode the response
        let response = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
        
        // Check if we got any results
        guard let bookItem = response.items?.first else {
            throw NSError(domain: "BookService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No book found with this ISBN"])
        }
        
        let bookInfo = bookItem.volumeInfo
        
        // Convert HTTP URLs to HTTPS for App Transport Security
        var imageLink: String? = nil
        if let thumbnail = bookInfo.imageLinks?.thumbnail {
            imageLink = thumbnail.replacingOccurrences(of: "http://", with: "https://")
        }
        
        return LibrarianBook(
            title: bookInfo.title,
            author: bookInfo.authors ?? [],
            genre: "Uncategorized", // Default genre, can be updated later
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
    }
} 
