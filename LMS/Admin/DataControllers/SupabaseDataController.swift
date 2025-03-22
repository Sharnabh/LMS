//
//  SupabaseDataController.swift
//  LMS
//
//  Created by Sharnabh on 19/03/25.
//

import Foundation
import Supabase
import MessageUI
import SwiftSMTP

class SupabaseDataController: ObservableObject {
    let client = SupabaseClient(
        supabaseURL: URL(string: "https://iswzgemgctojcdnbxvjv.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlzd3pnZW1nY3RvamNkbmJ4dmp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIyMzAwODgsImV4cCI6MjA1NzgwNjA4OH0.zmATRCYC3V8_BtROa_PzmFxabWQf0NjyNSQaMrwPL7E"
    )
    
    // SMTP Configuration
    private let smtp: SMTP
    private let senderUser: Mail.User
    
    init() {
        // Initialize SMTP configuration
        let hostname = "smtp.gmail.com"
        let email = "sharnabhbanerjee3@gmail.com"  // Your Gmail address
        let password = "kysb amuh xuqy zhng"       // Your app-specific password
        
        // Create sender user
        senderUser = Mail.User(name: "Library Management System", email: email)
        
        // Initialize SMTP with correct configuration
        smtp = SMTP(
            hostname: hostname,
            email: email,
            password: password,
            port: 587,
            tlsMode: .requireSTARTTLS
        )
    }
    
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
            try await client.from("Admin")
                .update(updateData)
                .eq("id", value: adminId)
                .execute()
        } catch {
            throw error
        }
    }
    
    func resetAdminPassword(adminId: String, newPassword: String) async throws {
        try await updateAdminPassword(adminId: adminId, newPassword: newPassword)
    }
    
    func authenticateAdmin(email: String, password: String) async throws -> (isAuthenticated: Bool, isFirstLogin: Bool, adminId: String?) {
        do {
            let response: [AdminModel] = try await client.from("Admin")
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
    
    func generateRandomPassword() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<10).map { _ in letters.randomElement()! })
    }
    
    func createLibrarian(name: String, email: String) async throws -> String {
        // Generate a random password
        let password = generateRandomPassword()
        
        let librarian = LibrarianModel(
            id: nil,  // Let the database generate the UUID
            email: email,
            username: name,  // Using name as username
            password: password,
            created_at: nil,
            isFirstLogin: true  // Set to true for new librarians
        )
        
        do {
            // Insert the librarian into the database
            try await client.from("Librarian")
                .insert(librarian)
                .execute()
            
            // Create email content
            let emailContent = """
            Welcome to the Library Management System! Your account has been created successfully.
            
            Here are your login credentials:
            Email: \(email)
            Password: \(password)
            
            Please log in and change your password immediately for security purposes.
            
            Best regards,
            Library Management Team
            """
            
            // Create recipient user
            let recipientUser = Mail.User(name: name, email: email)
            
            // Create the email
            let mail = Mail(
                from: senderUser,
                to: [recipientUser],
                subject: "Welcome to Library Management System",
                text: emailContent
            )
            
            // Send the email
            try await smtp.send(mail)
            
            return password
        } catch {
            throw error
        }
    }
    
    // MARK: - Test Connection
    
    func testConnection() async throws -> Bool {
        do {
            // Simple query to test the connection - select all fields instead of just id
            let _: [LibrarianBook] = try await client.from("Books")
                .select("*")  // Select all fields instead of just "id"
                .limit(1)
                .execute()
                .value
            
            return true
        } catch {
            print("Error testing connection: \(error)")
            return false
        }
    }
}

