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
        let email = "pustakalaya.lms@gmail.com"  // Your Gmail address
        let password = "kacs xgrz tndf kofp"       // Your app-specific password
        
        // Create sender user
        senderUser = Mail.User(name: "Pustakalaya", email: email)
        
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
                    let _ = try await sendOTP(to: email, name: "Admin", otp: otp, type: "login")
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
            isFirstLogin: true,
            isDisabled: false,   // Set to true for new librarians
            date_of_birth: nil,
            avatar_url: nil
        )
        
        do {
            // Insert the librarian into the database
            try await client.from("Librarian")
                .insert(librarian)
                .execute()
            
            // Create email content
            let emailContent = """
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Pustakalaya - Welcome</title>
                <style>
                    @import url('https://fonts.googleapis.com/css2?family=Charter:ital,wght@0,400;0,700;1,400&display=swap');
                    
                    body {
                        font-family: 'Charter', 'Georgia', serif;
                        line-height: 1.6;
                        color: #333;
                        margin: 0;
                        padding: 0;
                        background-color: #f9f9f7;
                    }
                    .container {
                        max-width: 600px;
                        margin: 20px auto;
                        background-color: #ffffff;
                        border-radius: 8px;
                        overflow: hidden;
                        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
                        border: 1px solid #e8e8e8;
                    }
                    .header {
                        background-color: #FCEFD5;
                        padding: 25px;
                        text-align: center;
                        border-bottom: 4px solid #FF8C00;
                    }
                    .header h1 {
                        color: #FF8C00;
                        margin: 0;
                        font-size: 26px;
                        font-weight: 700;
                        letter-spacing: -0.5px;
                    }
                    .content {
                        padding: 30px;
                    }
                    h2 {
                        color: #5a4a3a;
                        font-weight: 700;
                        margin-top: 0;
                        font-size: 22px;
                    }
                    .credentials-container {
                        background-color: #FCEFD5;
                        border-left: 4px solid #FF8C00;
                        border-radius: 0 6px 6px 0;
                        padding: 25px;
                        margin: 25px 0;
                        font-size: 18px;
                    }
                    .credential {
                        font-family: 'Courier New', monospace;
                        font-size: 18px;
                        font-weight: bold;
                        color: #FF8C00;
                        margin: 15px 0;
                        padding: 10px;
                        background: white;
                        display: block;
                        border-radius: 4px;
                        box-shadow: 0 1px 3px rgba(0,0,0,0.1);
                    }
                    .footer {
                        background-color: #FCEFD5;
                        padding: 20px;
                        text-align: center;
                        font-size: 13px;
                        color: #666;
                        border-top: 1px solid rgba(255,140,0,0.2);
                    }
                    .logo {
                        font-weight: 700;
                        color: #FF8C00;
                        font-style: italic;
                    }
                    .signature {
                        font-style: italic;
                        color: #5a4a3a;
                    }
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1><span class="logo">Pustakalaya</span> Library Management</h1>
                    </div>
                    
                    <div class="content">
                        <h2>Welcome to Pustakalaya</h2>
                        <p>Dear \(name),</p>
                        <p>Your account has been created successfully. Please use the following credentials to log in:</p>
                        
                        <div class="credentials-container">
                            <p style="margin-top: 0;">Your login credentials:</p>
                            <div class="credential"><strong>Email:</strong> \(email)</div>
                            <div class="credential"><strong>Password:</strong> \(password)</div>
                            <p style="margin-bottom: 0; font-size: 16px;">Please log in and change your password immediately for security purposes.</p>
                        </div>
                        
                        <p>For your security, please do not share these credentials with anyone.</p>
                        <p class="signature">With warm regards,<br>The <span class="logo">Pustakalaya</span> Team</p>
                    </div>
                    
                    <div class="footer">
                        ©️ 2023 Pustakalaya Library Management System<br>
                        Preserving knowledge, empowering minds
                    </div>
                </div>
            </body>
            </html>
            """
            
            // Create recipient user
            let recipientUser = Mail.User(name: name, email: email)
            
            // Create an HTML attachment
            let htmlAttachment = Attachment(htmlContent: emailContent)
            
            // Create the email
            let mail = Mail(
                from: senderUser,
                to: [recipientUser],
                subject: "Welcome To Pustakalaya",
                attachments: [htmlAttachment]
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
    
    func sendOTP(to email: String, name: String, otp: String, type: String = "reset") async throws -> Bool {
        // Create email content
        let emailContent = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Pustakalaya - Password Reset OTP</title>
            <style>
                @import url('https://fonts.googleapis.com/css2?family=Charter:ital,wght@0,400;0,700;1,400&display=swap');
                
                body {
                    font-family: 'Charter', 'Georgia', serif;
                    line-height: 1.6;
                    color: #333;
                    margin: 0;
                    padding: 0;
                    background-color: #f9f9f7;
                }
                .container {
                    max-width: 600px;
                    margin: 20px auto;
                    background-color: #ffffff;
                    border-radius: 8px;
                    overflow: hidden;
                    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
                    border: 1px solid #e8e8e8;
                }
                .header {
                    background-color: #FCEFD5;
                    padding: 25px;
                    text-align: center;
                    border-bottom: 4px solid #FF8C00;
                }
                .header h1 {
                    color: #FF8C00;
                    margin: 0;
                    font-size: 26px;
                    font-weight: 700;
                    letter-spacing: -0.5px;
                }
                .content {
                    padding: 30px;
                }
                h2 {
                    color: #5a4a3a;
                    font-weight: 700;
                    margin-top: 0;
                    font-size: 22px;
                }
                .otp-container {
                    background-color: #FCEFD5;
                    border-left: 4px solid #FF8C00;
                    border-radius: 0 6px 6px 0;
                    padding: 25px;
                    margin: 25px 0;
                    font-size: 18px;
                }
                .otp {
                    font-family: 'Courier New', monospace;
                    font-size: 24px;
                    font-weight: bold;
                    color: #FF8C00;
                    margin: 15px 0;
                    padding: 10px;
                    background: white;
                    display: block;
                    border-radius: 4px;
                    box-shadow: 0 1px 3px rgba(0,0,0,0.1);
                }
                .footer {
                    background-color: #FCEFD5;
                    padding: 20px;
                    text-align: center;
                    font-size: 13px;
                    color: #666;
                    border-top: 1px solid rgba(255,140,0,0.2);
                }
                .logo {
                    font-weight: 700;
                    color: #FF8C00;
                    font-style: italic;
                }
                .signature {
                    font-style: italic;
                    color: #5a4a3a;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1><span class="logo">Pustakalaya</span> Library Management</h1>
                </div>
                
                <div class="content">
                    <h2>Password Reset OTP</h2>
                    <p>Dear \(name),</p>
                    <p>You've requested to reset your admin password for the Library Management System.</p>
                    
                    <div class="otp-container">
                        <p style="margin-top: 0;">Your OTP:</p>
                        <div class="otp">\(otp)</div>
                        <p style="margin-bottom: 0; font-size: 16px;">This code will expire in 10 minutes.</p>
                    </div>
                    
                    <p>If you didn't request this, please ignore this email or contact support.</p>
                    <p class="signature">With warm regards,<br>The <span class="logo">Pustakalaya</span> Team</p>
                </div>
                
                <div class="footer">
                    ©️ 2023 Pustakalaya Library Management System<br>
                    Preserving knowledge, empowering minds
                </div>
            </div>
        </body>
        </html>
        """
        
        // Create recipient user
        let recipientUser = Mail.User(name: name, email: email)
        
        // Create an HTML attachment
        let htmlAttachment = Attachment(htmlContent: emailContent)
        
        // Create the email
        let subject = type == "login" ? "Login Authentication OTP - Pustakalaya" : "Password Reset OTP - Pustakalaya"
        let mail = Mail(
            from: senderUser,
            to: [recipientUser],
            subject: subject,
            attachments: [htmlAttachment]
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
    
    // MARK: - Book Deletion Request Methods
    
    func updateDeletionRequestStatus(requestId: UUID, status: String, adminResponse: String?) async throws -> Bool {
        struct RequestUpdate: Codable {
            let status: String
            let admin_response: String?
            let response_date: String
        }
        
        let formatter = ISO8601DateFormatter()
        let dateString = formatter.string(from: Date())
        
        let updateData = RequestUpdate(
            status: status,
            admin_response: adminResponse,
            response_date: dateString
        )
        
        do {
            try await client.from("book_requests")
                .update(updateData)
                .eq("id", value: requestId.uuidString)
                .execute()
            return true
        } catch {
            print("Error updating deletion request status: \(error)")
            throw error
        }
    }
    
    func fetchBook(by id: UUID) async throws -> LibrarianBook? {
        let query = client.from("Books")
            .select()
            .eq("id", value: id.uuidString)
            .eq("is_deleted", value: false)
            .single()
        
        do {
            let book: LibrarianBook = try await query.execute().value
            return book
        } catch {
            print("Error fetching book by ID: \(error)")
            return nil
        }
    }
    
    func fetchDeletionRequests() async throws -> [BookDeletionRequest] {
        print("📋 SupabaseDataController: Fetching deletion requests from the database...")
        let query = client.from("book_requests")
            .select()
        
        do {
            // Define a decoder type for the Supabase response
            struct RawRequest: Codable {
                let id: String
                let book_ids: [String]
                let requested_by: String
                let request_date: String
                let status: String
                let admin_response: String?
                let response_date: String?
            }
            
            print("📋 SupabaseDataController: Executing query to fetch deletion requests...")
            let rawRequests: [RawRequest] = try await query.execute().value
            print("📋 SupabaseDataController: Received \(rawRequests.count) raw deletion requests")
            
            // Convert the raw data to our app model
            let formatter = ISO8601DateFormatter()
            
            let result = rawRequests.map { raw in
                let bookIDs = raw.book_ids.compactMap { UUID(uuidString: $0) }
                let requestDate = formatter.date(from: raw.request_date) ?? Date()
                let responseDate = raw.response_date.flatMap { formatter.date(from: $0) }
                
                return BookDeletionRequest(
                    id: UUID(uuidString: raw.id),
                    bookIDs: bookIDs,
                    requestedBy: raw.requested_by,
                    requestDate: requestDate,
                    status: raw.status,
                    adminResponse: raw.admin_response,
                    responseDate: responseDate
                )
            }
            
            print("📋 SupabaseDataController: Successfully mapped \(result.count) deletion requests")
            return result
        } catch let error {
            print("📋 SupabaseDataController: Error fetching deletion requests: \(error)")
            throw error
        }
    }
    
    // MARK: - Book Operations
    
    func deleteBook(_ book: LibrarianBook) async throws -> Bool {
        guard let bookId = book.id else {
            print("Error: Book ID is nil")
            return false
        }
        
        do {
            print("Attempting to mark book as deleted with ID: \(bookId)")
            
            // Instead of deleting, update the is_deleted flag to true
            try await client.from("Books")
                .update(["is_deleted": true])
                .eq("id", value: bookId.uuidString)
                .execute()
            
            print("Book marked as deleted successfully")
            return true
        } catch {
            print("Error marking book as deleted: \(error)")
            throw error
        }
    }
}

// MARK: - Library Policies Extension
extension SupabaseDataController {
    // Fetch policies from Supabase
    func fetchLibraryPolicies() async throws -> (borrowingLimit: Int, returnPeriod: Int, fineAmount: Int, lostBookFine: Int) {
        do {
            // Create a decodable struct to match the database columns
            struct PolicyResponse: Decodable {
                let borrowing_limit: Int
                let return_period: Int
                let fine_amount: Int
                let lost_book_fine: Int
            }
            
            let response: [PolicyResponse] = try await client
                .from("library_policies")
                .select("borrowing_limit, return_period, fine_amount, lost_book_fine")
                .limit(1)
                .execute()
                .value
            
            if let policy = response.first {
                return (
                    borrowingLimit: policy.borrowing_limit,
                    returnPeriod: policy.return_period,
                    fineAmount: policy.fine_amount,
                    lostBookFine: policy.lost_book_fine
                )
            } else {
                // Return default values if no policy exists
                return (borrowingLimit: 5, returnPeriod: 14, fineAmount: 5, lostBookFine: 500)
            }
        } catch {
            print("Error fetching library policies: \(error)")
            throw error
        }
    }
    
    // Update policies in Supabase
    func updateLibraryPolicies(borrowingLimit: Int, returnPeriod: Int, fineAmount: Int, lostBookFine: Int) async throws {
        struct UpdateData: Encodable {
            let borrowing_limit: Int
            let return_period: Int
            let fine_amount: Int
            let lost_book_fine: Int
            let last_updated: String
        }
        
        // Get current timestamp in ISO 8601 format
        let dateFormatter = ISO8601DateFormatter()
        let currentTimestamp = dateFormatter.string(from: Date())
        
        let updateData = UpdateData(
            borrowing_limit: borrowingLimit,
            return_period: returnPeriod,
            fine_amount: fineAmount,
            lost_book_fine: lostBookFine,
            last_updated: currentTimestamp
        )
        
        do {
            // First check if a policy exists
            struct PolicyIdResponse: Decodable {
                let id: UUID
            }
            
            let response: [PolicyIdResponse] = try await client
                .from("library_policies")
                .select("id")
                .limit(1)
                .execute()
                .value
            
            if response.isEmpty {
                // If no policy exists, create one
                try await client
                    .from("library_policies")
                    .insert(updateData)
                    .execute()
            } else {
                // If policy exists, update it
                let policyId = response[0].id
                try await client
                    .from("library_policies")
                    .update(updateData)
                    .eq("id", value: policyId)
                    .execute()
            }
        } catch {
            print("Error updating library policies: \(error)")
            throw error
        }
    }
}

