import Foundation

enum QRParseError: Error {
    case invalidFormat
    case invalidJSON
    case missingFields
}

struct QRCodeParser {
    
    static func parseBookInfo(from qrContent: String) -> Result<BookInfo, QRParseError> {
        // First try parsing as JSON
        if let jsonData = qrContent.data(using: .utf8) {
            do {
                let decoder = JSONDecoder()
                let bookInfo = try decoder.decode(BookInfo.self, from: jsonData)
                
                // Validate required fields
                if bookInfo.bookId.isEmpty || bookInfo.memberId.isEmpty {
                    return .failure(.missingFields)
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
        // Book ID: 2506db6b-b427-4733-b8e7-b993dd3c5300
        // Member ID: 1f7cb028-b331-4050-8d46-40944e60ca09
        // Status: Issued
        // Issue Date: 21-03-2025
        // Return Date: 30-03-2025
        
        var bookId = ""
        var memberId = ""
        var issueStatus = ""
        var issueDate = ""
        var returnDate = ""
        
        let lines = qrContent.components(separatedBy: .newlines)
        
        for line in lines {
            if line.lowercased().contains("book id:") {
                let value = line.replacingOccurrences(of: "Book ID:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                bookId = value
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
            }
        }
        
        // Ensure we have at least the book ID and member ID
        if !bookId.isEmpty && !memberId.isEmpty {
            let bookInfo = BookInfo(
                bookId: bookId,
                memberId: memberId,
                issueStatus: issueStatus,
                issueDate: issueDate,
                returnDate: returnDate
            )
            return .success(bookInfo)
        }
        
        return .failure(.missingFields)
    }
} 