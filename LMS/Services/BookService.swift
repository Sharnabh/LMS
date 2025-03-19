import Foundation
import Supabase

class BookService {
    static let shared = BookService()
    private let supabase: SupabaseClient
    
    private init() {
        // Initialize Supabase client
        self.supabase = SupabaseConfig.client
    }
    
    // Add a single book
    func addBook(title: String, author: String, genre: String, ISBN: String, publicationYear: Int, totalCopies: Int) async throws {
        let book = Book(
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
            .insert(book)
            .execute()
    }
    
    // Add multiple books from CSV
    func addBooksFromCSV(books: [Book]) async throws {
        for book in books {
            try await addBook(
                title: book.title,
                author: book.author,
                genre: book.genre,
                ISBN: book.ISBN,
                publicationYear: book.publicationYear,
                totalCopies: book.totalCopies
            )
        }
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
