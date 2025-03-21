import Foundation

class GoogleBooksService {
    static func fetchBookByISBN(isbn: String) async throws -> LibrarianBook {
        // Format the ISBN by removing any spaces or hyphens
        let formattedISBN = isbn.replacingOccurrences(of: "[- ]", with: "", options: .regularExpression)
        
        // Create the URL for Google Books API request
        guard let url = URL(string: "https://www.googleapis.com/books/v1/volumes?q=isbn:\(formattedISBN)") else {
            throw URLError(.badURL)
        }
        
        // Fetch the data from the API
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // Decode the response using the GoogleBooksAPIResponse format needed for this specific endpoint
        let decoder = JSONDecoder()
        let response = try decoder.decode(GoogleBooksAPIResponse.self, from: data)
        
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
    let imageLinks: ImageLinks?
}

struct ImageLinks: Decodable {
    let thumbnail: String?
} 