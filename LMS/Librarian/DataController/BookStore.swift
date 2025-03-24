import Foundation
import SwiftUI

class BookStore: ObservableObject {
    @Published var books: [LibrarianBook] = []
    let dataController = SupabaseDataController()
    
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
                let success = try await dataController.addBook(book)
                if success {
                    print("Book added successfully: \(book.title)")
                    await loadBooks()
                    
                    // Verify the book was actually added
                    let addedBook = books.first { $0.ISBN == book.ISBN }
                    if addedBook != nil {
                        print("Book verified in database: \(book.title)")
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
                let success = try await dataController.updateBook(updatedBook)
                return (false, existingBook.id)
            } catch {
                print("Error updating existing book: \(error)")
                return (false, nil)
            }
        } else {
            // Book doesn't exist, add it as new
            do {
                let success = try await dataController.addBook(book)
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
        let sortedBooks = books.sorted { ($0.dateAdded ?? Date.distantPast) > ($1.dateAdded ?? Date.distantPast) }
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
                    print("  - \(book.title) (ID: \(book.id?.uuidString ?? "nil"), Shelf: \(book.shelfLocation ?? "None"))")
                }
            } else {
                print("Warning: No books were fetched from the database")
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
