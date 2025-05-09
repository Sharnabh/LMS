import Foundation
import SwiftUI

class AdminBookStore: ObservableObject {
    @Published var books: [LibrarianBook] = []
    let dataController = SupabaseDataController()
    
    // MARK: - Book Deletion Request Handling
    @Published var deletionRequests: [BookDeletionRequest] = []
    @Published var deletionHistory: [BookDeletionRequest] = []
    
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
                print("📋 Starting to fetch deletion requests...")
                let requests = try await dataController.fetchDeletionRequests()
                print("📋 Received \(requests.count) total deletion requests")
                
                await MainActor.run {
                    self.deletionRequests = requests.filter { $0.status == "pending" }
                    print("📋 Filtered to \(self.deletionRequests.count) pending deletion requests")
                }
            } catch {
                print("📋 Error fetching deletion requests: \(error)")
            }
        }
    }
    
    func fetchDeletionHistory() {
        Task {
            do {
                let requests = try await dataController.fetchDeletionRequests()
                await MainActor.run {
                    self.deletionHistory = requests
                        .filter { $0.status != "pending" }
                        .sorted { $0.requestDate > $1.requestDate } // Sort by date in descending order
                }
            } catch {
                print("Error fetching deletion history: \(error)")
            }
        }
    }
    
    @MainActor
    func approveDeletionRequest(_ request: BookDeletionRequest) async throws -> Bool {
        print("Starting deletion request approval process...")
        
        // First, check if any books are currently issued
        let issuedBookIds = try await dataController.checkIssuedBooks(bookIds: request.bookIDs)
        
        if !issuedBookIds.isEmpty {
            print("Found \(issuedBookIds.count) books that are currently issued!")
            // Return this information so we can show a warning to the user
            // We will handle this in the view
            throw BookDeletionError.booksCurrentlyIssued(issuedBookIds)
        }
        
        var allBooksDeleted = true
        var deletedBooks: [UUID] = []
        
        // First try to delete all books
        for bookId in request.bookIDs {
            if let book = try await dataController.fetchBook(by: bookId) {
                print("Attempting to delete book: \(book.title) (ID: \(bookId))")
                let deleteSuccess = try await dataController.deleteBook(book)
                
                if deleteSuccess {
                    print("Successfully deleted book: \(book.title)")
                    deletedBooks.append(bookId)
                } else {
                    print("Failed to delete book: \(book.title)")
                    allBooksDeleted = false
                    break // Stop if any deletion fails
                }
            } else {
                print("Book not found: \(bookId)")
                allBooksDeleted = false
                break // Stop if any book is not found
            }
        }
        
        if allBooksDeleted {
            // Only update request status if all books were successfully deleted
            let success = try await dataController.updateDeletionRequestStatus(
                requestId: request.id!,
                status: "approved",
                adminResponse: nil
            )
            
            if success {
                print("Deletion request marked as approved after successful book deletions")
                // Refresh both the deletion requests and books lists
                fetchDeletionRequests()
                await loadBooks()
                return true
            } else {
                print("Failed to update deletion request status")
                // Try to rollback deleted books (in a real production environment)
                // For now, just log the error
                print("Warning: Books were deleted but request status update failed")
                return false
            }
        } else {
            print("Not all books could be deleted, request will remain pending")
            return false
        }
    }

    // Add error enum for issued books
    enum BookDeletionError: Error {
        case booksCurrentlyIssued([UUID])
        
        var localizedDescription: String {
            switch self {
            case .booksCurrentlyIssued(let bookIds):
                return "Cannot delete \(bookIds.count) books that are currently issued."
            }
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
