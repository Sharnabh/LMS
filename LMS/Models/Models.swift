//
//  DataModels.swift
//  SampleLMS
//
//  Created by Madhav Saxena on 18/03/25.
//

import Foundation

struct Admin: Codable, Identifiable {
    var id: UUID
    var name: String
    var email: String
    var createdAt: Date
}

struct Librarian: Codable, Identifiable {
    var id: UUID
    var name: String
    var email: String
    var createdAt: Date
}

struct Member: Codable, Identifiable {
    var id: UUID
    var name: String
    var email: String
    var memberType: String // "Student" or "Faculty"
    var createdAt: Date
}

struct Book: Codable, Identifiable {
    var id: UUID
    var title: String
    var author: String
    var genre: String?
    var isbn: String
    var publicationYear: Int
    var totalCopies: Int
    var availableCopies: Int
    var createdAt: Date
}

struct Borrowing: Codable, Identifiable {
    var id: UUID
    var memberID: UUID
    var bookID: UUID
    var borrowDate: Date
    var returnDate: Date?
    var status: String // "Borrowed" or "Returned"
}
