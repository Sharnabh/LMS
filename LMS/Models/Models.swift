//
//  DataModels.swift
//  SampleLMS
//
//  Created by Madhav Saxena on 18/03/25.
//

import Foundation

// MARK: - Enums
enum issueStatus: String, Codable {
    case issued = "Issue"
    case returned = "Returned"
    case overdue = "Overdue"
    case lost = "Lost"
}

// MARK: - Supabase Models
struct AdminModel: Codable {
    let id: String
    let email: String
    let password: String
    let is_first_login: Bool
    let created_at: String?
}

struct LibrarianModel: Codable {
    let id: String?
    let email: String
    let username: String
    let password: String
    let created_at: String?
    let isFirstLogin: Bool
}

struct LibrarianPasswordUpdate: Codable {
    let password: String
    let isFirstLogin: Bool
}

// MARK: - Email Models
struct EmailData: Encodable {
    let to: String
    let subject: String
    let name: String
    let password: String
}

// MARK: - App Models
struct Admin: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let password: String
    let is_first_login: Bool
    let created_at: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case password
        case is_first_login
        case created_at
    }
}

struct Librarian: Codable, Identifiable {
    var id: UUID
    var name: String
    var email: String
    var password: String
    var createdAt: Date
}

struct Member: Codable, Identifiable {
    var id: UUID
    var name: String
    var email: String
    var password: String
    var createdAt: Date
}

struct Book: Codable, Identifiable {
    var id: UUID
    var title: String
    var author: String
    var genre: String
    var ISBN: String
    var publicationYear: Int
    var totalCopies: Int
    var availableCopies: Int
}

struct BookIssue: Codable, Identifiable {
    var id: UUID
    var memberID: UUID
    var bookID: UUID
    var issueDate: Date
    var dueDate: Date
    var returnDate: Date?
    var fine: Double = 0.0
    var status: issueStatus
}

// MARK: - Validation Models
struct PasswordValidationResult {
    let isValid: Bool
    let errorMessage: String?
}

