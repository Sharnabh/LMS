//
//  LibrarianDataController.swift
//  LMS
//
//  Created by Sharnabh on 19/03/25.
//

import Foundation
import Supabase

extension SupabaseDataController {
    
    func authenticateLibrarian(email: String, password: String) async throws -> (isAuthenticated: Bool, isFirstLogin: Bool, librarianId: String?, requiresOTP: Bool) {
        let query = client.from("Librarian")
            .select()
            .eq("email", value: email)
            .eq("password", value: password)
            .single()
        
        do {
            let librarian: LibrarianModel = try await query.execute().value
            
            // Check if librarian is disabled
            if librarian.isDisabled == true {
                throw NSError(domain: "", code: 403, userInfo: [NSLocalizedDescriptionKey: "Your account has been disabled. Please contact the administrator for assistance."])
            }
            
            // Store librarian email and id for future use
            UserDefaults.standard.set(librarian.id, forKey: "currentLibrarianID")
            UserDefaults.standard.set(librarian.email, forKey: "currentLibrarianEmail")
            
            if librarian.isFirstLogin {
                return (true, true, librarian.id, false)
            } else {
                // Generate and send OTP for non-first-time logins
                let otp = generateOTP(for: email)
                let _ = try await sendOTP(to: email, name: "Librarian", otp: otp)
                return (true, false, librarian.id, true)
            }
        } catch {
            throw error
        }
    }
    
    func updateLibrarianPassword(librarianID: String, newPassword: String) async throws -> Bool {
        // Validate password before updating
        let validationResult = validatePassword(newPassword)
        guard validationResult.isValid else {
            throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: validationResult.errorMessage ?? "Invalid password"])
        }
        
        let updateData = LibrarianPasswordUpdate(password: newPassword, isFirstLogin: false)
        
        do {
            try await client.from("Librarian")
                .update(updateData)
                .eq("id", value: librarianID)
                .execute()
            return true
        } catch {
            throw error
        }
    }
    
    // MARK: - Book Operations
    
    func fetchBooks() async throws -> [LibrarianBook] {
        let query = client.from("Books")
            .select()
            .eq("is_deleted", value: false)
        
        do {
            let books: [LibrarianBook] = try await query.execute().value
            return books
        } catch {
            throw error
        }
    }
    
    func addBook(_ book: LibrarianBook) async throws -> Bool {
        // Validate required fields
        guard !book.title.isEmpty else {
            throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Book title is required"])
        }
        
        guard !book.author.isEmpty else {
            throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Book author is required"])
        }
        
        // Validate genre against allowed values
        let allowedGenres = ["Science", "Humanities", "Business", "Medicine", "Law", 
                            "Education", "Arts", "Religion", "Mathematics", "Technology", "Reference", "Fiction", "Non-Fiction", "Literature"]
        guard allowedGenres.contains(book.genre) else {
            throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid genre. Please select from the allowed genres."])
        }
        
        // Create a new book with the current date
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: currentDate)
        
        // Create an encodable structure for the book data
        struct BookInsert: Codable {
            let id: String  // Add ID field to ensure it's properly sent to database
            let title: String
            let author: [String]
            let genre: String
            let publicationDate: String
            let totalCopies: Int
            let availableCopies: Int
            let ISBN: String
            let Description: String
            let shelfLocation: String
            let dateAdded: String
            let publisher: String
            let imageLink: String
        }
        
        let bookData = BookInsert(
            id: book.id?.uuidString ?? UUID().uuidString,  // Convert UUID to string for database
            title: book.title,
            author: book.author,
            genre: book.genre,
            publicationDate: book.publicationDate,
            totalCopies: book.totalCopies,
            availableCopies: book.availableCopies,
            ISBN: book.ISBN,
            Description: book.Description ?? "",
            shelfLocation: book.shelfLocation ?? "",
            dateAdded: dateString,
            publisher: book.publisher ?? "",
            imageLink: book.imageLink ?? ""
        )
        
        do {
            print("Inserting book with ID: \(book.id?.uuidString ?? "new UUID")")
            let response = try await client.from("Books")
                .insert(bookData)
                .execute()
                
            print("Book insert response status: \(response.status)")
            return true
        } catch {
            throw error
        }
    }
    
    func updateBook(_ book: LibrarianBook) async throws -> Bool {
        // Create an encodable structure for the book data
        struct BookUpdate: Codable {
            let title: String
            let author: [String]
            let genre: String
            let publicationDate: String
            let totalCopies: Int
            let availableCopies: Int
            let ISBN: String
            let Description: String?
            let shelfLocation: String?
            let dateAdded: String?
            let publisher: String?
            let imageLink: String?
        }
        
        let bookData = BookUpdate(
            title: book.title,
            author: book.author,
            genre: book.genre,
            publicationDate: book.publicationDate,
            totalCopies: book.totalCopies,
            availableCopies: book.availableCopies,
            ISBN: book.ISBN,
            Description: book.Description,
            shelfLocation: book.shelfLocation,
            dateAdded: book.dateAdded.map { ISO8601DateFormatter().string(from: $0) },
            publisher: book.publisher,
            imageLink: book.imageLink
        )
        
        do {
            try await client.from("Books")
                .update(bookData)
                .eq("id", value: book.id)
                .execute()
            return true
        } catch {
            throw error
        }
    }
    

    
    // MARK: - Shelf Location Methods
    
    func fetchShelfLocations() async throws -> [BookShelfLocation] {
        let query = client.from("BookShelfLocation")
            .select()
        
        do {
            let locations: [BookShelfLocation] = try await query.execute().value
            return locations
        } catch let error {
            print("Error fetching shelf locations: \(error)")
            throw error
        }
    }
    
    func addShelfLocation(_ shelfLocation: BookShelfLocation) async throws -> Bool {
        do {
            try await client.from("BookShelfLocation")
                .insert(shelfLocation)
                .execute()
            return true
        } catch let error {
            print("Error adding shelf location: \(error)")
            throw error
        }
    }
    
    func updateShelfLocation(_ shelfLocation: BookShelfLocation) async throws -> Bool {
        do {
            try await client.from("BookShelfLocation")
                .update(shelfLocation)
                .eq("id", value: shelfLocation.id)
                .execute()
            return true
        } catch let error {
            print("Error updating shelf location: \(error)")
            throw error
        }
    }
    
    func deleteShelfLocation(_ shelfLocation: BookShelfLocation) async throws -> Bool {
        do {
            try await client.from("BookShelfLocation")
                .delete()
                .eq("id", value: shelfLocation.id)
                .execute()
            return true
        } catch let error {
            print("Error deleting shelf location: \(error)")
            throw error
        }
    }
    
    // MARK: - Book Deletion Requests
    
    func createBookDeletionRequest(_ request: BookDeletionRequest) async throws -> Bool {
        // Create a Codable structure for the request data
        struct RequestInsert: Codable {
            let id: String
            let book_ids: [String]
            let requested_by: String
            let request_date: String
            let status: String
        }
        
        // Format the date for Supabase
        let formatter = ISO8601DateFormatter()
        let dateString = formatter.string(from: request.requestDate)
        
        // Convert UUID arrays to string arrays for Supabase
        let bookIDStrings = request.bookIDs.map { $0.uuidString }
        
        let requestData = RequestInsert(
            id: request.id?.uuidString ?? UUID().uuidString,
            book_ids: bookIDStrings,
            requested_by: request.requestedBy,
            request_date: dateString,
            status: "pending"
        )
        
        do {
            try await client.from("book_requests")
                .insert(requestData)
                .execute()
            return true
        } catch let error {
            print("Error creating deletion request: \(error)")
            throw error
        }
    }
    
    func checkLibrarianStatus(librarianId: String) async throws -> Bool {
        let query = client.from("Librarian")
            .select("librarian_is_disabled")
            .eq("id", value: librarianId)
            .single()
        
        do {
            // Create a custom struct that only includes the fields we need
            struct LibrarianStatusResponse: Codable {
                let isDisabled: Bool?
                
                enum CodingKeys: String, CodingKey {
                    case isDisabled = "librarian_is_disabled"
                }
            }
            
            let librarian: LibrarianStatusResponse = try await query.execute().value
            return librarian.isDisabled ?? false
        } catch {
            throw error
        }
    }
}
