import Foundation

enum QRParseError: Error {
    case invalidFormat
    case invalidJSON
    case missingFields
    case expired
}

struct QRCodeParser {
    
    static func parseBookInfo(from qrContent: String) -> Result<BookInfo, QRParseError> {
        // First try parsing as JSON
        if let jsonData = qrContent.data(using: .utf8) {
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                decoder.dateDecodingStrategy = .iso8601
                
                struct QRData: Codable {
                    struct BookIssueData: Codable {
                        let issueDate: String
                        let bookId: String
                        let id: String
                        let issueStatus: String
                        let returnDate: String
                        let memberId: String
                    }
                    
                    let bookIssue: BookIssueData
                    let expirationDate: String
                    let timestamp: String
                    let isValid: Bool
                }
                
                let qrData = try decoder.decode(QRData.self, from: jsonData)
                
                // Convert BookIssue to BookInfo format
                let bookInfo = BookInfo(
                    bookIds: [qrData.bookIssue.bookId],
                    memberId: qrData.bookIssue.memberId,
                    issueStatus: qrData.bookIssue.issueStatus,
                    issueDate: qrData.bookIssue.issueDate,
                    returnDate: qrData.bookIssue.returnDate,
                    expirationDate: TimeInterval(qrData.expirationDate) ?? 0,
                    timestamp: TimeInterval(qrData.timestamp) ?? 0,
                    isValid: qrData.isValid
                )
                
                // Validate required fields
                if bookInfo.bookIds.isEmpty || bookInfo.memberId.isEmpty {
                    return .failure(.missingFields)
                }
                
                // Check if QR code is expired
                if !bookInfo.isValid {
                    return .failure(.expired)
                }
                
                return .success(bookInfo)
            } catch {
                print("JSON parsing error: \(error)")
                // If JSON parsing fails, try text format parsing
                let textResult = parseTextFormat(from: qrContent)
                return textResult
            }
        }
        
        // Fallback to text format parsing
        return parseTextFormat(from: qrContent)
    }
    
    // Parse text format QR code content
    private static func parseTextFormat(from qrContent: String) -> Result<BookInfo, QRParseError> {
        // Example expected format from a library QR code
        // Book IDs: ["2506db6b-b427-4733-b8e7-b993dd3c5300"]
        // Member ID: 1f7cb028-b331-4050-8d46-40944e60ca09
        // Status: Issued
        // Issue Date: 21-03-2025
        // Return Date: 30-03-2025
        // Expiration Date: 1734567890
        // Timestamp: 1734567890
        // Valid: true
        
        var bookIds: [String] = []
        var memberId = ""
        var issueStatus = ""
        var issueDate = ""
        var returnDate = ""
        var expirationDate: TimeInterval = 0
        var timestamp: TimeInterval = 0
        var isValid = false
        
        let lines = qrContent.components(separatedBy: .newlines)
        
        for line in lines {
            if line.lowercased().contains("book ids:") {
                let value = line.replacingOccurrences(of: "Book IDs:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                if let data = value.data(using: .utf8),
                   let ids = try? JSONDecoder().decode([String].self, from: data) {
                    bookIds = ids
                }
            } else if line.lowercased().contains("member id:") {
                let value = line.replacingOccurrences(of: "Member ID:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                memberId = value
            } else if line.lowercased().contains("status:") {
                let value = line.replacingOccurrences(of: "Status:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                issueStatus = value
            } else if line.lowercased().contains("issue date:") {
                let value = line.replacingOccurrences(of: "Issue Date:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                issueDate = value
            } else if line.lowercased().contains("return date:") {
                let value = line.replacingOccurrences(of: "Return Date:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                returnDate = value
            } else if line.lowercased().contains("expiration date:") {
                let value = line.replacingOccurrences(of: "Expiration Date:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                expirationDate = TimeInterval(value) ?? 0
            } else if line.lowercased().contains("timestamp:") {
                let value = line.replacingOccurrences(of: "Timestamp:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                timestamp = TimeInterval(value) ?? 0
            } else if line.lowercased().contains("valid:") {
                let value = line.replacingOccurrences(of: "Valid:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                isValid = value.lowercased() == "true"
            }
        }
        
        // Ensure we have at least the book IDs and member ID
        if !bookIds.isEmpty && !memberId.isEmpty {
            let bookInfo = BookInfo(
                bookIds: bookIds,
                memberId: memberId,
                issueStatus: issueStatus,
                issueDate: issueDate,
                returnDate: returnDate,
                expirationDate: expirationDate,
                timestamp: timestamp,
                isValid: isValid
            )
            return .success(bookInfo)
        }
        
        return .failure(.missingFields)
    }
} 