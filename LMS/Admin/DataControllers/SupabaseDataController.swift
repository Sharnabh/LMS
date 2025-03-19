//
//  SupabaseDataController.swift
//  LMS
//
//  Created by Sharnabh on 19/03/25.
//

import Foundation
import Supabase

// Model for Admin table
struct AdminModel: Codable {
    let id: String
    let email: String
    let password: String
    let is_first_login: Bool
    let created_at: String?
}

class SupabaseDataController {
    let client = SupabaseClient(
        supabaseURL: URL(string: "https://iswzgemgctojcdnbxvjv.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlzd3pnZW1nY3RvamNkbmJ4dmp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIyMzAwODgsImV4cCI6MjA1NzgwNjA4OH0.zmATRCYC3V8_BtROa_PzmFxabWQf0NjyNSQaMrwPL7E"
    )
    
    struct PasswordValidationResult {
        let isValid: Bool
        let errorMessage: String?
    }
    
    func validatePassword(_ password: String) -> PasswordValidationResult {
        // Minimum 8 characters
        guard password.count >= 8 else {
            return PasswordValidationResult(isValid: false, errorMessage: "Password must be at least 8 characters long")
        }
        
        // At least one uppercase letter
        guard password.range(of: "[A-Z]", options: .regularExpression) != nil else {
            return PasswordValidationResult(isValid: false, errorMessage: "Password must contain at least one uppercase letter")
        }
        
        // At least one lowercase letter
        guard password.range(of: "[a-z]", options: .regularExpression) != nil else {
            return PasswordValidationResult(isValid: false, errorMessage: "Password must contain at least one lowercase letter")
        }
        
        // At least one number
        guard password.range(of: "[0-9]", options: .regularExpression) != nil else {
            return PasswordValidationResult(isValid: false, errorMessage: "Password must contain at least one number")
        }
        
        // At least one special character
        guard password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil else {
            return PasswordValidationResult(isValid: false, errorMessage: "Password must contain at least one special character")
        }
        
        return PasswordValidationResult(isValid: true, errorMessage: nil)
    }
    
    func updateAdminPassword(adminId: String, newPassword: String) async throws {
        // Validate password before updating
        let validationResult = validatePassword(newPassword)
        guard validationResult.isValid else {
            throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: validationResult.errorMessage ?? "Invalid password"])
        }
        
        struct UpdateData: Encodable {
            let password: String
            let is_first_login: Bool
        }
        
        let updateData = UpdateData(password: newPassword, is_first_login: false)
        
        do {
            try await client.database
                .from("Admin")
                .update(updateData)
                .eq("id", value: adminId)
                .execute()
        } catch {
            throw error
        }
    }
    
    func authenticateAdmin(email: String, password: String) async throws -> (isAuthenticated: Bool, isFirstLogin: Bool, adminId: String?) {
        do {
            let response: [AdminModel] = try await client.database
                .from("Admin")
                .select("*")
                .eq("email", value: email)
                .eq("password", value: password)
                .execute()
                .value
            
            if let admin = response.first {
                return (true, admin.is_first_login, admin.id)
            }
            
            return (false, false, nil)
        } catch {
            print("Authentication error: \(error)")
            throw error
        }
    }
}

