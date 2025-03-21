import Foundation
import SwiftUI

class ShelfLocationStore: ObservableObject {
    @Published var shelfLocations: [BookShelfLocation] = []
    let dataController = SupabaseDataController()
    
    init() {
        Task(priority: .userInitiated) {
            do {
                let isConnected = try await dataController.testConnection()
                if isConnected {
                    await loadShelfLocations()
                    print("ShelfLocationStore initialized with \(shelfLocations.count) shelf locations")
                } else {
                    print("ShelfLocationStore initialization failed - connection test failed")
                }
            } catch {
                print("Failed to connect to database: \(error)")
            }
        }
    }
    
    @MainActor
    func loadShelfLocations() async {
        print("Loading shelf locations from database...")
        do {
            let fetchedLocations = try await dataController.fetchShelfLocations()
            self.shelfLocations = fetchedLocations
            print("Successfully loaded \(fetchedLocations.count) shelf locations")
        } catch {
            print("Error loading shelf locations: \(error)")
            self.shelfLocations = []
        }
    }
    
    func addShelfLocation(_ shelfLocation: BookShelfLocation) {
        Task {
            do {
                print("Adding shelf location: \(shelfLocation.shelfNo)")
                let success = try await dataController.addShelfLocation(shelfLocation)
                if success {
                    print("Shelf location added successfully: \(shelfLocation.shelfNo)")
                    await loadShelfLocations()
                } else {
                    print("Failed to add shelf location: \(shelfLocation.shelfNo)")
                }
            } catch {
                print("Error adding shelf location: \(error)")
            }
        }
    }
    
    func updateShelfLocation(_ shelfLocation: BookShelfLocation) {
        Task {
            do {
                let success = try await dataController.updateShelfLocation(shelfLocation)
                if success {
                    await loadShelfLocations()
                }
            } catch {
                print("Error updating shelf location: \(error)")
            }
        }
    }
    
    func deleteShelfLocation(_ shelfLocation: BookShelfLocation) {
        Task {
            do {
                let success = try await dataController.deleteShelfLocation(shelfLocation)
                if success {
                    await loadShelfLocations()
                }
            } catch {
                print("Error deleting shelf location: \(error)")
            }
        }
    }
    
    // Add a book to a shelf location
    func addBookToShelf(bookID: UUID, shelfNo: String) async -> Bool {
        // Find if the shelf already exists
        if let existingShelfIndex = shelfLocations.firstIndex(where: { $0.shelfNo == shelfNo }) {
            var updatedShelf = shelfLocations[existingShelfIndex]
            
            // Check if book is already in this shelf
            if !updatedShelf.bookID.contains(bookID) {
                updatedShelf.bookID.append(bookID)
                
                do {
                    let success = try await dataController.updateShelfLocation(updatedShelf)
                    if success {
                        await loadShelfLocations()
                        return true
                    }
                    return false
                } catch {
                    print("Error updating shelf location: \(error)")
                    return false
                }
            } else {
                // Book is already in this shelf
                return true
            }
        } else {
            // Create a new shelf location
            let newShelfLocation = BookShelfLocation(
                id: UUID(),
                shelfNo: shelfNo,
                bookID: [bookID]
            )
            
            do {
                let success = try await dataController.addShelfLocation(newShelfLocation)
                if success {
                    await loadShelfLocations()
                    return true
                }
                return false
            } catch {
                print("Error adding new shelf location: \(error)")
                return false
            }
        }
    }
    
    // Remove a book from a shelf location
    func removeBookFromShelf(bookID: UUID, shelfNo: String) async -> Bool {
        if let existingShelfIndex = shelfLocations.firstIndex(where: { $0.shelfNo == shelfNo }) {
            var updatedShelf = shelfLocations[existingShelfIndex]
            
            // Remove book from the shelf
            updatedShelf.bookID.removeAll(where: { $0 == bookID })
            
            do {
                let success = try await dataController.updateShelfLocation(updatedShelf)
                if success {
                    await loadShelfLocations()
                    return true
                }
                return false
            } catch {
                print("Error updating shelf location: \(error)")
                return false
            }
        }
        return false
    }
    
    // Get all books in a specific shelf
    func getBooksInShelf(shelfNo: String) -> [UUID] {
        if let shelf = shelfLocations.first(where: { $0.shelfNo == shelfNo }) {
            return shelf.bookID
        }
        return []
    }
    
    // Get shelf for a specific book
    func getShelfForBook(bookID: UUID) -> String? {
        for shelf in shelfLocations {
            if shelf.bookID.contains(bookID) {
                return shelf.shelfNo
            }
        }
        return nil
    }
} 