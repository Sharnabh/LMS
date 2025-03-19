//
//  DataModels.swift
//  SampleLMS
//
//  Created by Madhav Saxena on 18/03/25.
//

import Foundation

enum issueStatus: String, Codable {
    case issued = "Issue"
    case returned = "Returned"
    case overdue = "Overdue"
    case lost = "Lost"
}

struct Admin: Codable, Identifiable {
    var id: UUID
    var name: String
    var email: String
    var password: String
    var createdAt: Date
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
//  var memberType: String // "Student" or "Faculty"
    var createdAt: Date
}

struct Book: Codable {
    let id: UUID
    let title: String
    let author: String
    let genre: String
    let ISBN: String  // Changed from [String] to String
    let publicationYear: Int
    let totalCopies: Int
    let availableCopies: Int
    
    enum CodingKeys: String, CodingKey {
        case id, title, author, genre, ISBN, publicationYear, totalCopies, availableCopies
    }
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

