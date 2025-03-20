//
//  LibrarianDataController.swift
//  LMS
//
//  Created by Sharnabh on 19/03/25.
//

import Foundation
import Supabase

extension SupabaseDataController {
    
    func authenticateLibrarian(email: String, password: String) async throws -> (Bool, Bool) {
        let query = client.database
            .from("Librarian")
            .select()
            .eq("email", value: email)
            .eq("password", value: password)
            .single()
        
        do {
            let librarian: LibrarianModel = try await query.execute().value
            // Store librarian email and id for future use
            UserDefaults.standard.set(librarian.id, forKey: "currentLibrarianID")
            UserDefaults.standard.set(librarian.email, forKey: "currentLibrarianEmail")
            return (true, librarian.isFirstLogin)
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
            try await client.database
                .from("Librarian")
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
        let query = client.database
            .from("Books")
            .select()
        
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
                            "Education", "Arts", "Religion", "Mathematics", "Technology", "Reference"]
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
            try await client.database
                .from("Books")
                .insert(bookData)
                .execute()
            return true
        } catch {
            throw error
        }
    }
    
    func updateBook(_ book: LibrarianBook) async throws -> Bool {
        do {
            try await client.database
                .from("Books")
                .update(book)
                .eq("id", value: book.id)
                .execute()
            return true
        } catch {
            throw error
        }
    }
    
    func deleteBook(_ book: LibrarianBook) async throws -> Bool {
        do {
            try await client.database
                .from("Books")
                .delete()
                .eq("id", value: book.id)
                .execute()
            return true
        } catch {
            throw error
        }
    }
    
    // MARK: - Database Connection Test
    
    func testConnection() async throws -> Bool {
        do {
            let query = client.database
                .from("Books")
                .select("*")
                .limit(1)
            
            let books: [LibrarianBook] = try await query.execute().value
            return true
        } catch {
            throw error
        }
    }
}
