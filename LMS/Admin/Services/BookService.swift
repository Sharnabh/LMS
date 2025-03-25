import Foundation
import Supabase

class BookService {
    static let shared = BookService()
    private let supabase: SupabaseClient
    
    private init() {
        // Initialize Supabase client
        self.supabase = SupabaseConfig.client
    }
    
    // Check if a book already exists
    private func findExistingBook(title: String, author: String, genre: String, ISBN: String, publicationDate: String) async throws -> AdminBook? {
        // Convert author string to Postgres array format
        let authorArray = "{" + author.split(separator: ";").map { "\"\($0.trimmingCharacters(in: .whitespaces))\"" }.joined(separator: ",") + "}"
        
        let response = try await supabase
            .from("Books")
            .select()
            .eq("title", value: title)
            .eq("author", value: authorArray)  // Use formatted array
            .eq("genre", value: genre)
            .eq("ISBN", value: ISBN)
            .eq("publicationDate", value: publicationDate)
            .execute()
        
        let decoder = JSONDecoder()
        let books = try decoder.decode([AdminBook].self, from: response.data)
        return books.first
    }
    
    // Find books by ISBN
    func findBooksByISBN(_ isbn: String) async throws -> [AdminBook] {
        let response = try await supabase
            .from("Books")
            .select()
            .eq("ISBN", value: isbn)
            .execute()
        
        let decoder = JSONDecoder()
        let books = try decoder.decode([AdminBook].self, from: response.data)
        return books
    }
    
    // Update existing book's copies - made public
    func updateBookCopies(id: UUID, totalCopies: Int, availableCopies: Int, Description: String? = nil, shelfLocation: String? = nil, publisher: String? = nil, imageLink: String? = nil) async throws {
        struct UpdateData: Encodable {
            let totalCopies: Int
            let availableCopies: Int
            let Description: String?
            let shelfLocation: String?
            let publisher: String?
            let imageLink: String?
        }
        
        let updateData = UpdateData(
            totalCopies: totalCopies,
            availableCopies: availableCopies,
            Description: Description,
            shelfLocation: shelfLocation,
            publisher: publisher,
            imageLink: imageLink
        )
        
        try await supabase
            .from("Books")
            .update(updateData)
            .eq("id", value: id)
            .execute()
    }
    
    // Add a single book with duplicate check
    func addBook(title: String, author: String, genre: String, ISBN: String, publicationDate: String, totalCopies: Int, Description: String? = nil, shelfLocation: String? = nil, publisher: String? = nil, imageLink: String? = nil) async throws -> (isNewBook: Bool, book: AdminBook) {
        // Convert author string to array, splitting by semicolons
        let authorArray = author.split(separator: ";").map { String($0.trimmingCharacters(in: .whitespaces)) }
        
        // Check for existing book
        if let existingBook = try await findExistingBook(
            title: title,
            author: author,
            genre: genre,
            ISBN: ISBN,
            publicationDate: publicationDate
        ) {
            // Update copies of existing book
            let newTotalCopies = existingBook.totalCopies + totalCopies
            let newAvailableCopies = existingBook.availableCopies + totalCopies
            
            try await updateBookCopies(
                id: existingBook.id,
                totalCopies: newTotalCopies,
                availableCopies: newAvailableCopies,
                Description: Description,
                shelfLocation: shelfLocation,
                publisher: publisher,
                imageLink: imageLink
            )
            
            // Return updated book information
            let updatedBook = AdminBook(
                id: existingBook.id,
                title: existingBook.title,
                author: existingBook.author,
                genre: existingBook.genre,
                ISBN: existingBook.ISBN,
                publicationDate: existingBook.publicationDate,
                totalCopies: newTotalCopies,
                availableCopies: newAvailableCopies,
                Description: existingBook.Description,
                shelfLocation: existingBook.shelfLocation,
                dateAdded: existingBook.dateAdded,
                publisher: existingBook.publisher,
                imageLink: existingBook.imageLink
            )
            return (false, updatedBook)
        }
        
        // If no existing book found, add new book
        let newBook = AdminBook(
            id: UUID(),
            title: title,
            author: authorArray,
            genre: genre,
            ISBN: ISBN,
            publicationDate: publicationDate,
            totalCopies: totalCopies,
            availableCopies: totalCopies,
            Description: Description,
            shelfLocation: shelfLocation,
            dateAdded: Date(),
            publisher: publisher,
            imageLink: imageLink
        )
        
        // Create an encodable book data structure
        struct BookData: Encodable {
            let id: String
            let title: String
            let author: [String]
            let genre: String
            let ISBN: String
            let publicationDate: String
            let totalCopies: Int
            let availableCopies: Int
            let Description: String?
            let shelfLocation: String?
            let dateAdded: String
            let publisher: String?
            let imageLink: String?
        }
        
        let bookData = BookData(
            id: newBook.id.uuidString,
            title: title,
            author: authorArray,
            genre: genre,
            ISBN: ISBN,
            publicationDate: publicationDate,
            totalCopies: totalCopies,
            availableCopies: totalCopies,
            Description: Description,
            shelfLocation: shelfLocation,
            dateAdded: ISO8601DateFormatter().string(from: Date()),
            publisher: publisher,
            imageLink: imageLink
        )
        
        try await supabase
            .from("Books")
            .insert(bookData)
            .execute()
        
        return (true, newBook)
    }
    
    // Add multiple books from CSV with duplicate check
    func addBooksFromCSV(books: [AdminBook]) async throws -> (newBooks: Int, updatedBooks: Int) {
        var newBooksCount = 0
        var updatedBooksCount = 0
        
        for book in books {
            let authorString = book.author.joined(separator: "; ")
            let result = try await addBook(
                title: book.title,
                author: authorString,
                genre: book.genre,
                ISBN: book.ISBN,
                publicationDate: book.publicationDate,
                totalCopies: book.totalCopies,
                Description: book.Description,
                shelfLocation: book.shelfLocation,
                publisher: book.publisher,
                imageLink: book.imageLink
            )
            
            if result.isNewBook {
                newBooksCount += 1
            } else {
                updatedBooksCount += 1
            }
        }
        
        return (newBooksCount, updatedBooksCount)
    }
    
    // Parse CSV file
    func parseCSVFile(url: URL) throws -> [AdminBook] {
        let csvContent = try String(contentsOf: url, encoding: .utf8)
        let rows = csvContent.components(separatedBy: .newlines)
        
        // Skip header row and empty rows
        let dataRows = rows.dropFirst().filter { !$0.isEmpty }
        
        return try dataRows.map { row in
            let columns = row.components(separatedBy: ",")
            guard columns.count >= 6 else {
                throw BookError.invalidCSVFormat
            }
            
            // Get author string and split into array by semicolons
            let authorString = columns[1].trimmingCharacters(in: .whitespaces)
            let authorArray = authorString.split(separator: ";").map { String($0.trimmingCharacters(in: .whitespaces)) }
            
            return AdminBook(
                id: UUID(),
                title: columns[0].trimmingCharacters(in: .whitespaces),
                author: authorArray,
                genre: columns[2].trimmingCharacters(in: .whitespaces),
                ISBN: columns[3].trimmingCharacters(in: .whitespaces),
                publicationDate: columns[4].trimmingCharacters(in: .whitespaces),
                totalCopies: Int(columns[5]) ?? 1,
                availableCopies: Int(columns[5]) ?? 1,
                Description: nil,
                shelfLocation: nil,
                dateAdded: Date(),
                publisher: nil,
                imageLink: nil
            )
        }
    }
}

enum BookError: Error {
    case invalidCSVFormat
    case invalidData
}

struct AdminBook: Codable, Identifiable {
    var id: UUID
    var title: String
    var author: [String]
    var genre: String
    var ISBN: String
    var publicationDate: String
    var totalCopies: Int
    var availableCopies: Int
    var Description: String?
    var shelfLocation: String?
    var dateAdded: Date?
    var publisher: String?
    var imageLink: String?
} 
