import Foundation
import SwiftUI

class AdminBookStore: ObservableObject {
    @Published var books: [LibrarianBook] = []
    let dataController = SupabaseDataController()
    
    // MARK: - Book Deletion Request Handling
    @Published var deletionRequests: [BookDeletionRequest] = []
    
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
                let _ = try await dataController.addBook(book)
                print("Book added successfully: \(book.title)")
                await loadBooks()
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
                let _ = try await dataController.updateBook(updatedBook)
                return (false, existingBook.id)
            } catch {
                print("Error updating existing book: \(error)")
                return (false, nil)
            }
        } else {
            // Book doesn't exist, add it as new
            do {
                let _ = try await dataController.addBook(book)
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
    
    func deleteBook(_ book: LibrarianBook) {
        Task {
            do {
                let _ = try await dataController.deleteBook(book)
                await loadBooks()
            } catch {
                print("Error deleting book: \(error)")
            }
        }
    }
    
    func getRecentlyAddedBooks(limit: Int = 10) -> [LibrarianBook] {
        let sortedBooks = books.sorted { book1, book2 in
            // Compare by addID first (higher addID means more recently added)
            if let addID1 = book1.addID, let addID2 = book2.addID {
                return addID1 > addID2
            }
            // Fall back to dateAdded if addID is not available
            return (book1.dateAdded ?? Date.distantPast) > (book2.dateAdded ?? Date.distantPast)
        }
        let limitedBooks = sortedBooks.prefix(limit).map { $0 }
        return limitedBooks
    }
    
    @MainActor
    func loadBooks() async {
        print("Loading books from database...")
        do {
            let fetchedBooks = try await dataController.fetchBooks()
            self.books = fetchedBooks
            print("Successfully loaded \(fetchedBooks.count) books")
            
            // Debug info - print the first few books
            if !fetchedBooks.isEmpty {
                let sampleBooks = fetchedBooks.prefix(min(3, fetchedBooks.count))
                for book in sampleBooks {
                    print("  - \(book.title) (ID: \(book.id?.uuidString ?? "nil"))")
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
                let _ = try await dataController.updateBook(updatedBook)
                await loadBooks()
                return true
            } catch {
                print("Error updating book shelf location: \(error)")
                return false
            }
        }
        return false
    }
    
    func fetchDeletionRequests() {
        Task {
            do {
                let requests = try await dataController.fetchDeletionRequests()
                await MainActor.run {
                    self.deletionRequests = requests
                }
            } catch {
                print("Error fetching deletion requests: \(error)")
            }
        }
    }
    
    func approveDeletionRequest(_ request: BookDeletionRequest) async -> Bool {
        do {
            // First update the request status
            let success = try await dataController.updateDeletionRequestStatus(
                requestId: request.id!,
                status: "approved",
                adminResponse: nil
            )
            
            if success {
                // Then delete the books
                for bookId in request.bookIDs {
                    if let book = try await dataController.fetchBook(by: bookId) {
                        let _ = try await dataController.deleteBook(book)
                    }
                }
                
                // Refresh the requests list
                await MainActor.run {
                    fetchDeletionRequests()
                }
                return true
            }
            return false
        } catch {
            print("Error approving deletion request: \(error)")
            return false
        }
    }
    
    func rejectDeletionRequest(_ request: BookDeletionRequest, reason: String) async -> Bool {
        do {
            let success = try await dataController.updateDeletionRequestStatus(
                requestId: request.id!,
                status: "rejected",
                adminResponse: reason
            )
            
            if success {
                await MainActor.run {
                    fetchDeletionRequests()
                }
                return true
            }
            return false
        } catch {
            print("Error rejecting deletion request: \(error)")
            return false
        }
    }
} 