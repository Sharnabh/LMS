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
    private func findExistingBook(title: String, author: String, genre: String, ISBN: String, publicationYear: Int) async throws -> Book? {
        let response = try await supabase
            .from("Books")
            .select()
            .eq("title", value: title)
            .eq("author", value: author)
            .eq("genre", value: genre)
            .eq("ISBN", value: ISBN)
            .eq("publicationYear", value: publicationYear)
            .execute()
        
        let decoder = JSONDecoder()
        let books = try decoder.decode([Book].self, from: response.data)
        return books.first
    }
    
    // Update existing book's copies
    private func updateBookCopies(id: UUID, totalCopies: Int, availableCopies: Int) async throws {
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
    func addBook(title: String, author: String, genre: String, ISBN: String, publicationYear: Int, totalCopies: Int) async throws -> (isNewBook: Bool, book: Book) {
        // Check for existing book
        if let existingBook = try await findExistingBook(
            title: title,
            author: author,
            genre: genre,
            ISBN: ISBN,
            publicationYear: publicationYear
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
                publicationYear: existingBook.publicationYear,
                totalCopies: newTotalCopies,
                availableCopies: newAvailableCopies
            )
            return (false, updatedBook)
        }
        
        // If no existing book found, add new book
        let newBook = Book(
            id: UUID(),
            title: title,
            author: author,
            genre: genre,
            ISBN: ISBN,
            publicationYear: publicationYear,
            totalCopies: totalCopies,
            availableCopies: totalCopies
        )
        
        try await supabase
            .from("Books")
            .insert(newBook)
            .execute()
        
        return (true, newBook)
    }
    
    // Add multiple books from CSV with duplicate check
    func addBooksFromCSV(books: [Book]) async throws -> (newBooks: Int, updatedBooks: Int) {
        var newBooksCount = 0
        var updatedBooksCount = 0
        
        for book in books {
            let result = try await addBook(
                title: book.title,
                author: book.author,
                genre: book.genre,
                ISBN: book.ISBN,
                publicationYear: book.publicationYear,
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
            
            guard let publicationYear = Int(columns[4]),
                  let totalCopies = Int(columns[5]) else {
                throw BookError.invalidData
            }
            
            return Book(
                id: UUID(),
                title: columns[0].trimmingCharacters(in: .whitespaces),
                author: columns[1].trimmingCharacters(in: .whitespaces),
                genre: columns[2].trimmingCharacters(in: .whitespaces),
                ISBN: columns[3].trimmingCharacters(in: .whitespaces),
                publicationYear: publicationYear,
                totalCopies: totalCopies,
                availableCopies: totalCopies
            )
        }
    }
}

enum BookError: Error {
    case invalidCSVFormat
    case invalidData
} 
