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
}
