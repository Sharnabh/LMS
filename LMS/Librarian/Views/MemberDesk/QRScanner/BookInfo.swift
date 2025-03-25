import Foundation

struct BookInfo: Identifiable, Codable {
    var id = UUID()
    var bookIds: [String]
    var memberId: String
    var issueStatus: String
    var issueDate: String
    var returnDate: String
    var expirationDate: TimeInterval
    var timestamp: TimeInterval
    var isValid: Bool
    
    enum CodingKeys: String, CodingKey {
        case bookIds
        case memberId
        case issueStatus
        case issueDate
        case returnDate
        case expirationDate
        case timestamp
        case isValid
    }
    
    init(bookIds: [String], memberId: String, issueStatus: String, issueDate: String, returnDate: String, expirationDate: TimeInterval, timestamp: TimeInterval, isValid: Bool) {
        self.bookIds = bookIds
        self.memberId = memberId
        self.issueStatus = issueStatus
        self.issueDate = issueDate
        self.returnDate = returnDate
        self.expirationDate = expirationDate
        self.timestamp = timestamp
        self.isValid = isValid
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        bookIds = try container.decode([String].self, forKey: .bookIds)
        memberId = try container.decode(String.self, forKey: .memberId)
        issueStatus = try container.decode(String.self, forKey: .issueStatus)
        issueDate = try container.decode(String.self, forKey: .issueDate)
        returnDate = try container.decode(String.self, forKey: .returnDate)
        isValid = try container.decode(Bool.self, forKey: .isValid)
        
        // Handle string timestamps
        let expirationDateString = try container.decode(String.self, forKey: .expirationDate)
        expirationDate = TimeInterval(expirationDateString) ?? 0
        
        let timestampString = try container.decode(String.self, forKey: .timestamp)
        timestamp = TimeInterval(timestampString) ?? 0
    }
    
    static var empty: BookInfo {
        BookInfo(
            bookIds: [],
            memberId: "",
            issueStatus: "",
            issueDate: "",
            returnDate: "",
            expirationDate: 0,
            timestamp: 0,
            isValid: false
        )
    }
} 