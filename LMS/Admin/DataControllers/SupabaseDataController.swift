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
    
    func authenticateAdmin(email: String, password: String) async throws -> (isAuthenticated: Bool, isFirstLogin: Bool, adminId: String?, requiresOTP: Bool) {
        do {
            let response: [AdminModel] = try await client.from("Admin")
                .select("*")
                .eq("email", value: email)
                .eq("password", value: password)
                .execute()
                .value
            
            if let admin = response.first {
                if admin.is_first_login {
                    return (true, true, admin.id, false)
                } else {
                    // Generate and send OTP for non-first-time logins
                    let otp = generateOTP(for: email)
                    let _ = try await sendOTP(to: email, name: "Admin", otp: otp)
                    return (true, false, admin.id, true)
                }
            }
            
            return (false, false, nil, false)
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
    
    // MARK: - Admin Password Reset
    
    // Structure to store OTP information with expiry
    private struct OTPInfo {
        let otp: String
        let expiryTime: Date
        let email: String
        
        var isValid: Bool {
            return Date() < expiryTime
        }
    }
    
    // Dictionary to store active OTPs
    private static var activeOTPs: [String: OTPInfo] = [:]
    
    func generateOTP(for email: String) -> String {
        // Generate a 6-digit OTP
        let digits = "0123456789"
        var otp = ""
        for _ in 0..<6 {
            let randomIndex = Int.random(in: 0..<digits.count)
            let digit = digits[digits.index(digits.startIndex, offsetBy: randomIndex)]
            otp.append(digit)
        }
        
        // Set expiry time to 10 minutes from now
        let expiryTime = Date().addingTimeInterval(10 * 60)
        
        // Store OTP with expiry
        let otpInfo = OTPInfo(otp: otp, expiryTime: expiryTime, email: email)
        SupabaseDataController.activeOTPs[email] = otpInfo
        
        return otp
    }
    
    func verifyOTP(email: String, otp: String) -> Bool {
        guard let otpInfo = SupabaseDataController.activeOTPs[email] else {
            return false // No OTP found for this email
        }
        
        // Check if OTP is expired
        if !otpInfo.isValid {
            // Remove expired OTP
            SupabaseDataController.activeOTPs.removeValue(forKey: email)
            return false
        }
        
        // Verify OTP
        let isValid = otpInfo.otp == otp
        
        // If valid, remove the used OTP
        if isValid {
            SupabaseDataController.activeOTPs.removeValue(forKey: email)
        }
        
        return isValid
    }
    
    func generateOTP() -> String {
        // DEPRECATED: Use generateOTP(for:) instead to include expiry
        // This is maintained for backward compatibility
        // Generate a 6-digit OTP
        let digits = "0123456789"
        var otp = ""
        for _ in 0..<6 {
            let randomIndex = Int.random(in: 0..<digits.count)
            let digit = digits[digits.index(digits.startIndex, offsetBy: randomIndex)]
            otp.append(digit)
        }
        return otp
    }
    
    func verifyAdminEmail(email: String) async throws -> (exists: Bool, adminId: String?, isFirstLogin: Bool) {
        do {
            let response: [AdminModel] = try await client.from("Admin")
                .select("*")
                .eq("email", value: email)
                .execute()
                .value
            
            if let admin = response.first {
                return (true, admin.id, admin.is_first_login)
            }
            
            return (false, nil, false)
        } catch {
            print("Verification error: \(error)")
            throw error
        }
    }
    
    func verifyLibrarianEmail(email: String) async throws -> (exists: Bool, librarianId: String?, isFirstLogin: Bool) {
        do {
            let response: [LibrarianModel] = try await client.from("Librarian")
                .select("*")
                .eq("email", value: email)
                .execute()
                .value
            
            if let librarian = response.first {
                return (true, librarian.id, librarian.isFirstLogin)
            }
            
            return (false, nil, false)
        } catch {
            print("Librarian verification error: \(error)")
            throw error
        }
    }
    
    func sendOTP(to email: String, name: String, otp: String) async throws -> Bool {
        // Create email content
        let emailContent = """
        Hello,
        
        You've requested to reset your admin password for the Library Management System.
        
        Your OTP is: \(otp)
        
        This code will expire in 10 minutes.
        
        If you didn't request this, please ignore this email or contact support.
        
        Best regards,
        Library Management Team
        """
        
        // Create recipient user
        let recipientUser = Mail.User(name: name, email: email)
        
        // Create the email
        let mail = Mail(
            from: senderUser,
            to: [recipientUser],
            subject: "Password Reset OTP - Library Management System",
            text: emailContent
        )
        
        do {
            // Send the email
            try await smtp.send(mail)
            return true
        } catch {
            print("Error sending OTP: \(error)")
            throw error
        }
    }
}

