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
    private func findExistingBook(title: String, author: String, genre: String, ISBN: String, publicationDate: String) async throws -> Book? {
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
        let books = try decoder.decode([Book].self, from: response.data)
        return books.first
    }
    
    // Find books by ISBN
    func findBooksByISBN(_ isbn: String) async throws -> [Book] {
        let response = try await supabase
            .from("Books")
            .select()
            .eq("ISBN", value: isbn)
            .execute()
        
        let decoder = JSONDecoder()
        let books = try decoder.decode([Book].self, from: response.data)
        return books
    }
    
    // Update existing book's copies - made public
    func updateBookCopies(id: UUID, totalCopies: Int, availableCopies: Int) async throws {
        try await supabase
            .from("Books")
            .update([
                "totalCopies": totalCopies,
                "availableCopies": availableCopies
            ])
            .eq("id", value: id)
            .execute()
    }
    
    // Add a single book with duplicate check
    func addBook(title: String, author: String, genre: String, ISBN: String, publicationDate: String, totalCopies: Int) async throws -> (isNewBook: Bool, book: Book) {
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
                availableCopies: newAvailableCopies
            )
            
            // Return updated book information
            let updatedBook = Book(
                id: existingBook.id,
                title: existingBook.title,
                author: existingBook.author,
                genre: existingBook.genre,
                ISBN: existingBook.ISBN,
                publicationDate: existingBook.publicationDate,
                totalCopies: newTotalCopies,
                availableCopies: newAvailableCopies
            )
            return (false, updatedBook)
        }
        
        // If no existing book found, add new book
        let newBook = Book(
            id: UUID(),
            title: title,
            author: authorArray,
            genre: genre,
            ISBN: ISBN,
            publicationDate: publicationDate,
            totalCopies: totalCopies,
            availableCopies: totalCopies
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
        }
        
        let bookData = BookData(
            id: newBook.id.uuidString,
            title: title,
            author: authorArray,
            genre: genre,
            ISBN: ISBN,
            publicationDate: publicationDate,
            totalCopies: totalCopies,
            availableCopies: totalCopies
        )
        
        try await supabase
            .from("Books")
            .insert(bookData)
            .execute()
        
        return (true, newBook)
    }
    
    // Add multiple books from CSV with duplicate check
    func addBooksFromCSV(books: [Book]) async throws -> (newBooks: Int, updatedBooks: Int) {
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
                totalCopies: book.totalCopies
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
    func parseCSVFile(url: URL) throws -> [Book] {
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
            
            return Book(
                id: UUID(),
                title: columns[0].trimmingCharacters(in: .whitespaces),
                author: authorArray,
                genre: columns[2].trimmingCharacters(in: .whitespaces),
                ISBN: columns[3].trimmingCharacters(in: .whitespaces),
                publicationDate: columns[4].trimmingCharacters(in: .whitespaces),
                totalCopies: Int(columns[5]) ?? 1,
                availableCopies: Int(columns[5]) ?? 1
            )
        }
    }
}

enum BookError: Error {
    case invalidCSVFormat
    case invalidData
} 
