import Foundation

struct BookInfo: Identifiable, Codable {
    var id = UUID()
    var bookId: String
    var memberId: String
    var issueStatus: String
    var issueDate: String
    var returnDate: String
    
    enum CodingKeys: String, CodingKey {
        case bookId
        case memberId
        case issueStatus
        case issueDate
        case returnDate
    }
    
    static var empty: BookInfo {
        BookInfo(bookId: "", memberId: "", issueStatus: "", issueDate: "", returnDate: "")
    }
} 