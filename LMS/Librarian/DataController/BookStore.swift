import Foundation
import SwiftUI

class BookStore: ObservableObject {
    @Published var books: [LibrarianBook] = []
    let dataController = SupabaseDataController()
    
    init() {
        Task {
            do {
                let isConnected = try await dataController.testConnection()
                if isConnected {
                    await loadBooks()
                }
            } catch {
                print("Failed to connect to database: \(error)")
            }
        }
    }
    
    func addBook(_ book: LibrarianBook) {
        Task {
            do {
                let success = try await dataController.addBook(book)
                if success {
                    await loadBooks()
                }
            } catch {
                print("Error adding book: \(error)")
            }
        }
    }
    
    func updateBook(_ book: LibrarianBook) {
        Task {
            do {
                let success = try await dataController.updateBook(book)
                if success {
                    await loadBooks()
                }
            } catch {
                print("Error updating book: \(error)")
            }
        }
    }
    
    func deleteBook(_ book: LibrarianBook) {
        Task {
            do {
                let success = try await dataController.deleteBook(book)
                if success {
                    await loadBooks()
                }
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
        do {
            books = try await dataController.fetchBooks()
        } catch {
            books = []
        }
    }
} 
