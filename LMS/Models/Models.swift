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

//struct MemberModel: Codable {
//    let id: String?
//    let firstName: String?
//    let lastName: String?
//    let email: String?
//    let password: String?
//    let created_at: String?
//    let favourites: [String]?
//    let enrollmentNumber: String?
//    let collegeName: String?
//    
//    enum CodingKeys: String, CodingKey {
//        case id
//        case firstName = "firstName"
//        case lastName = "lastName"
//        case email
//        case password
//        case created_at
//        case favourites
//        case enrollmentNumber = "enrollmentNumber" 
//        case collegeName = "collegeName"
//    }
//}

struct MemberModel: Codable {
    var id: String?
    var firstName: String?
    var lastName: String?
    var email: String?
    var password: String?
    var created_at: String?
    var favourites: [String]?
    var enrollmentNumber: String?
    var collegeName: String?
    var isDisabled: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "firstName"
        case lastName = "lastName"
        case email
        case password
        case created_at
        case favourites
        case enrollmentNumber = "enrollmentNumber"
        case collegeName = "collegeName"
        case isDisabled = "is_disabled"  // Make sure this matches your Supabase column name
    }
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
    var author: [String]
    var genre: String
    var ISBN: String
    var publicationDate: String
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

struct LibrarianBook: Identifiable, Codable {
    let id: UUID? // Optional because it's generated by Supabase for new books
    var title: String
    var author: [String] // Array of strings for multiple authors
    var genre: String
    var publicationDate: String
    var totalCopies: Int
    var availableCopies: Int
    var ISBN: String
    var Description: String?
    var shelfLocation: String?
    var dateAdded: Date?
    var publisher: String?
    var imageLink: String?
    var addID: Int? // New field for sequential book addition tracking
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case author
        case genre
        case publicationDate
        case totalCopies
        case availableCopies
        case ISBN
        case Description
        case shelfLocation
        case dateAdded
        case publisher
        case imageLink
        case addID
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        author = try container.decode([String].self, forKey: .author)
        genre = try container.decode(String.self, forKey: .genre)
        publicationDate = try container.decode(String.self, forKey: .publicationDate)
        totalCopies = try container.decode(Int.self, forKey: .totalCopies)
        availableCopies = try container.decode(Int.self, forKey: .availableCopies)
        ISBN = try container.decode(String.self, forKey: .ISBN)
        Description = try container.decodeIfPresent(String.self, forKey: .Description)
        shelfLocation = try container.decodeIfPresent(String.self, forKey: .shelfLocation)
        publisher = try container.decodeIfPresent(String.self, forKey: .publisher)
        imageLink = try container.decodeIfPresent(String.self, forKey: .imageLink)
        addID = try container.decodeIfPresent(Int.self, forKey: .addID)
        
        // Handle dateAdded decoding
        if let dateString = try container.decodeIfPresent(String.self, forKey: .dateAdded) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            dateAdded = formatter.date(from: dateString)
        } else {
            dateAdded = nil
        }
    }
    
    init(id: UUID? = nil, 
         title: String = "", 
         author: [String] = [], 
         genre: String = "Uncategorized",
         publicationDate: String = "", 
         totalCopies: Int = 1,
         availableCopies: Int = 1,
         ISBN: String = "",
         Description: String? = nil,
         shelfLocation: String? = nil,
         dateAdded: Date? = Date(),
         publisher: String? = nil,
         imageLink: String? = nil,
         addID: Int? = nil) {
        self.id = id
        self.title = title
        self.author = author
        self.genre = genre
        self.publicationDate = publicationDate
        self.totalCopies = totalCopies
        self.availableCopies = availableCopies
        self.ISBN = ISBN
        self.Description = Description
        self.shelfLocation = shelfLocation
        self.dateAdded = dateAdded
        self.publisher = publisher
        self.imageLink = imageLink
        self.addID = addID
    }
}

// Google Books API response structures
struct GoogleBooksResponse: Codable {
    var items: [VolumeInfo]?
    
    struct VolumeInfo: Codable {
        var volumeInfo: BookInfo
        
        struct BookInfo: Codable {
            var title: String
            var authors: [String]?
            var publisher: String?
            var publishedDate: String?
            var description: String?
            var industryIdentifiers: [IndustryIdentifier]?
            var imageLinks: ImageLinks?
            
            struct IndustryIdentifier: Codable {
                var type: String
                var identifier: String
            }
            
            struct ImageLinks: Codable {
                var thumbnail: String?
            }
        }
    }
}

struct BookShelfLocation: Codable, Identifiable {
    var id: UUID
    var shelfNo: String
    var bookID: [UUID]
    
    enum CodingKeys: String, CodingKey {
        case id
        case shelfNo
        case bookID
    }
}

// MARK: - Policy Models
struct LibraryPolicy: Codable, Identifiable {
    let id: UUID
    var borrowingLimit: Int
    var returnPeriod: Int
//    var reissuePeriod: Int
    var fineAmount: Int
    var lastUpdated: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case borrowingLimit = "borrowing_limit"
        case returnPeriod = "return_period"
//        case reissuePeriod = "reissue_period"
        case fineAmount = "fine_amount"
        case lastUpdated = "last_updated"
    }
}

struct LibraryTiming: Codable, Identifiable {
    let id: UUID
    var weekdayOpeningTime: Date
    var weekdayClosingTime: Date
    var sundayOpeningTime: Date
    var sundayClosingTime: Date
    var lastUpdated: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case weekdayOpeningTime = "weekday_opening_time"
        case weekdayClosingTime = "weekday_closing_time"
        case sundayOpeningTime = "sunday_opening_time"
        case sundayClosingTime = "sunday_closing_time"
        case lastUpdated = "last_updated"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
        
        // Parse time strings for time fields
        let weekdayOpeningTimeString = try container.decode(String.self, forKey: .weekdayOpeningTime)
        let weekdayClosingTimeString = try container.decode(String.self, forKey: .weekdayClosingTime)
        let sundayOpeningTimeString = try container.decode(String.self, forKey: .sundayOpeningTime)
        let sundayClosingTimeString = try container.decode(String.self, forKey: .sundayClosingTime)
        
        // Convert Supabase time format (HH:MM:SS) to Date
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZone.current  // Use local timezone instead of GMT
        
        // Set default times in case parsing fails
        let calendar = Calendar.current
        var defaultDate = calendar.startOfDay(for: Date())
        
        if let date = formatter.date(from: weekdayOpeningTimeString) {
            weekdayOpeningTime = date
        } else {
            weekdayOpeningTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: defaultDate) ?? defaultDate
        }
        
        if let date = formatter.date(from: weekdayClosingTimeString) {
            weekdayClosingTime = date
        } else {
            weekdayClosingTime = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: defaultDate) ?? defaultDate
        }
        
        if let date = formatter.date(from: sundayOpeningTimeString) {
            sundayOpeningTime = date
        } else {
            sundayOpeningTime = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: defaultDate) ?? defaultDate
        }
        
        if let date = formatter.date(from: sundayClosingTimeString) {
            sundayClosingTime = date
        } else {
            sundayClosingTime = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: defaultDate) ?? defaultDate
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(lastUpdated, forKey: .lastUpdated)
        
        // Convert Date to Supabase time format (HH:MM:SS)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZone.current  // Use local timezone instead of GMT
        
        let weekdayOpeningTimeString = formatter.string(from: weekdayOpeningTime)
        let weekdayClosingTimeString = formatter.string(from: weekdayClosingTime)
        let sundayOpeningTimeString = formatter.string(from: sundayOpeningTime)
        let sundayClosingTimeString = formatter.string(from: sundayClosingTime)
        
        try container.encode(weekdayOpeningTimeString, forKey: .weekdayOpeningTime)
        try container.encode(weekdayClosingTimeString, forKey: .weekdayClosingTime)
        try container.encode(sundayOpeningTimeString, forKey: .sundayOpeningTime)
        try container.encode(sundayClosingTimeString, forKey: .sundayClosingTime)
    }
    
    init(id: UUID = UUID(),
         weekdayOpeningTime: Date? = nil,
         weekdayClosingTime: Date? = nil,
         sundayOpeningTime: Date? = nil,
         sundayClosingTime: Date? = nil,
         lastUpdated: Date = Date()) {
        self.id = id
        self.lastUpdated = lastUpdated
        
        let calendar = Calendar.current
        let defaultDate = calendar.startOfDay(for: Date())
        
        self.weekdayOpeningTime = weekdayOpeningTime ?? calendar.date(bySettingHour: 9, minute: 0, second: 0, of: defaultDate)!
        self.weekdayClosingTime = weekdayClosingTime ?? calendar.date(bySettingHour: 20, minute: 0, second: 0, of: defaultDate)!
        self.sundayOpeningTime = sundayOpeningTime ?? calendar.date(bySettingHour: 10, minute: 0, second: 0, of: defaultDate)!
        self.sundayClosingTime = sundayClosingTime ?? calendar.date(bySettingHour: 16, minute: 0, second: 0, of: defaultDate)!
    }
}

struct BookManagementPolicy: Codable, Identifiable {
    let id: UUID
    var bookManagementText: String
    var bookStatusText: String
    var borrowingRules: String
    var lastUpdated: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case bookManagementText = "book_management_text"
        case bookStatusText = "book_status_text"
        case borrowingRules = "borrowing_rules"
        case lastUpdated = "last_updated"
    }
}
