import Foundation
import SwiftUI

class BookStore: ObservableObject {
    @Published var books: [LibrarianBook] = []
    let dataController = SupabaseDataController()
    private let addIDKey = "BookStore.lastAddID" // Key for storing last addID in UserDefaults
    private var lastAddID: Int {
        get { UserDefaults.standard.integer(forKey: addIDKey) }
        set { UserDefaults.standard.set(newValue, forKey: addIDKey) }
    }
    private var bookAddIDs: [UUID: Int] = [:] // In-memory mapping of book IDs to addIDs
    
    init() {
        Task(priority: .userInitiated) {
            do {
                let isConnected = try await dataController.testConnection()
                if isConnected {
                    await loadBooks()
                    print("BookStore initialized with \(books.count) books")
                } else {
                    print("BookStore initialization failed - connection test failed")
                }
            } catch {
                print("Failed to connect to database: \(error)")
            }
        }
    }
    
    func addBook(_ book: LibrarianBook) {
        Task {
            do {
                print("Adding book: \(book.title)")
                // Create a new book with incremented addID
                var newBook = book
                let nextAddID = lastAddID + 1
                newBook.addID = nextAddID
                
                let success = try await dataController.addBook(newBook)
                if success {
                    print("Book added successfully: \(book.title) with local addID: \(nextAddID)")
                    // Update the last addID only after successful addition
                    lastAddID = nextAddID
                    await loadBooks()
                    
                    // Verify the book was actually added
                    let addedBook = books.first { $0.ISBN == book.ISBN }
                    if let addedBook = addedBook, let bookId = addedBook.id {
                        print("Book verified in database: \(book.title)")
                        // Store the addID mapping
                        bookAddIDs[bookId] = nextAddID
                    } else {
                        print("WARNING: Book not found in database after addition: \(book.title)")
                    }
                } else {
                    print("Failed to add book: \(book.title)")
                }
            } catch {
                print("Error adding book: \(error)")
            }
        }
    }
    
    // New method to check if a book exists and add/update accordingly
    func addOrUpdateBook(_ book: LibrarianBook) async -> (isNewBook: Bool, bookId: UUID?) {
        // Check if a book with the same ISBN already exists
        if let existingBook = findBookByISBN(book.ISBN) {
            // Book exists, update its quantities
            let updatedBook = LibrarianBook(
                id: existingBook.id,
                title: existingBook.title,
                author: existingBook.author,
                genre: existingBook.genre,
                publicationDate: existingBook.publicationDate,
                totalCopies: existingBook.totalCopies + book.totalCopies,
                availableCopies: existingBook.availableCopies + book.totalCopies,
                ISBN: existingBook.ISBN,
                Description: existingBook.Description,
                shelfLocation: existingBook.shelfLocation,
                dateAdded: existingBook.dateAdded,
                publisher: existingBook.publisher,
                imageLink: existingBook.imageLink
            )
            
            do {
                _ = try await dataController.updateBook(updatedBook)
                return (false, existingBook.id)
            } catch {
                print("Error updating existing book: \(error)")
                return (false, nil)
            }
        } else {
            // Book doesn't exist, add it as new
            do {
                _ = try await dataController.addBook(book)
                return (true, book.id)
            } catch {
                print("Error adding new book: \(error)")
                return (false, nil)
            }
        }
    }
    
    // Helper method to find a book by ISBN
    func findBookByISBN(_ isbn: String) -> LibrarianBook? {
        return books.first { $0.ISBN == isbn }
    }
    
    func updateBook(_ book: LibrarianBook) {
        Task {
            do {
                let _ = try await dataController.updateBook(book)
                await loadBooks()
            } catch {
                print("Error updating book: \(error)")
            }
        }
    }
    
//    func deleteBook(_ book: LibrarianBook) {
//        Task {
//            do {
//                let _ = try await dataController.deleteBook(book)
//                await loadBooks()
//            } catch {
//                print("Error deleting book: \(error)")
//            }
//        }
//    }
    
    // New method to create a deletion request instead of directly deleting books
    func createDeletionRequest(for books: Set<LibrarianBook>) async -> Bool {
        guard let currentLibrarianEmail = UserDefaults.standard.string(forKey: "currentLibrarianEmail") else {
            print("Error: No librarian email found")
            return false
        }
        
        let bookIDs = books.compactMap { $0.id }
        
        // Create the deletion request
        let deletionRequest = BookDeletionRequest(
            bookIDs: bookIDs,
            requestedBy: currentLibrarianEmail
        )
        
        do {
            let success = try await dataController.createBookDeletionRequest(deletionRequest)
            if success {
                print("Deletion request created successfully for \(bookIDs.count) books")
                return true
            } else {
                print("Failed to create deletion request")
                return false
            }
        } catch {
            print("Error creating deletion request: \(error)")
            return false
        }
    }
    
    func getRecentlyAddedBooks(limit: Int = 10) -> [LibrarianBook] {
        let sortedBooks = books.sorted { book1, book2 in
            // Compare by addID (newer books have higher addID)
            let id1 = book1.addID ?? -1
            let id2 = book2.addID ?? -1
            return id1 > id2
        }
        let limitedBooks = sortedBooks.prefix(limit).map { $0 }
        return limitedBooks
    }
    
    @MainActor
    func loadBooks() async {
        print("Loading books from database...")
        do {
            let fetchedBooks = try await dataController.fetchBooks()
            // Assign addIDs to books that don't have them yet
            var processedBooks = fetchedBooks
            for i in 0..<processedBooks.count {
                if let bookId = processedBooks[i].id {
                    if let existingAddID = bookAddIDs[bookId] {
                        processedBooks[i].addID = existingAddID
                    } else {
                        let nextAddID = lastAddID + 1
                        processedBooks[i].addID = nextAddID
                        bookAddIDs[bookId] = nextAddID
                        lastAddID = nextAddID
                    }
                }
            }
            self.books = processedBooks
            print("Successfully loaded \(fetchedBooks.count) books")
            
            // Debug info - print the first few books
            if !fetchedBooks.isEmpty {
                let sampleBooks = fetchedBooks.prefix(min(3, fetchedBooks.count))
                for book in sampleBooks {
                    print("  - \(book.title) (ID: \(book.id?.uuidString ?? "nil"), AddID: \(book.addID ?? -1))")
                }
            }
        } catch {
            print("Error loading books: \(error)")
            self.books = []
        }
    }
    
    // Force refresh books from database - can be called from any view
    func refreshBooks() {
        Task {
            await loadBooks()
        }
    }
    
    // Update a book's shelf location
    func updateBookShelfLocation(bookId: UUID, shelfLocation: String) async -> Bool {
        if let bookIndex = books.firstIndex(where: { $0.id == bookId }) {
            var updatedBook = books[bookIndex]
            updatedBook.shelfLocation = shelfLocation
            
            do {
                let success = try await dataController.updateBook(updatedBook)
                if success {
                    await loadBooks()
                    return true
                }
                return false
            } catch {
                print("Error updating book shelf location: \(error)")
                return false
            }
        }
        return false
    }
} 
