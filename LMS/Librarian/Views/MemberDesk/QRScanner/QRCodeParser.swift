import Foundation

enum QRParseError: Error {
    case invalidFormat
    case invalidJSON
    case missingFields
    case expired
    case invalidAction
}

enum QRCodeType {
    case issue
    case bookReturn
}

struct QRCodeParser {
    
    static func parseBookInfo(from qrContent: String) -> Result<BookInfo, QRParseError> {
        // First try parsing as JSON
        if let jsonData = qrContent.data(using: .utf8) {
//            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                decoder.dateDecodingStrategy = .iso8601
                
                // First try to determine the QR code type
                struct QRTypeCheck: Codable {
                    let action: String?
                    let bookIssue: BookIssueData?
                    
                    struct BookIssueData: Codable {
                        let issueDate: String
                        let bookId: String?
                        let bookIds: [String]?
                        let id: String
                        let status: String
                        let returnDate: String
                        let memberId: String
                    }
                }
                
                // Try parsing as return QR code first
                struct ReturnQRData: Codable {
                    let issueId: String
                    let action: String
                    let timestamp: String
                }
                
                if let returnData = try? decoder.decode(ReturnQRData.self, from: jsonData) {
                    if returnData.action == "return" {
                        // This is a return QR code, we need to fetch the issue details
                        return .failure(.invalidFormat) // We'll handle this in the return flow
                    }
                }
                
                // If not a return QR, try parsing as issue QR
                struct IssueQRData: Codable {
                    struct BookIssueData: Codable {
                        let issueDate: String
                        let bookId: String?
                        let bookIds: [String]?
                        let id: String
                        let status: String
                        let returnDate: String
                        let memberId: String
                    }
                    
                    let bookIssue: BookIssueData
                    let expirationDate: AnyCodable?
                    let timestamp: AnyCodable?
                    let isValid: Bool
                }
                
                // Add AnyCodable to handle both string and numeric values
                struct AnyCodable: Codable {
                    let value: Any
                    
                    init(from decoder: Decoder) throws {
                        let container = try decoder.singleValueContainer()
                        if let stringValue = try? container.decode(String.self) {
                            value = stringValue
                        } else if let doubleValue = try? container.decode(Double.self) {
                            value = doubleValue
                        } else {
                            value = ""
                        }
                    }
                    
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.singleValueContainer()
                        if let stringValue = value as? String {
                            try container.encode(stringValue)
                        } else if let doubleValue = value as? Double {
                            try container.encode(doubleValue)
                        } else {
                            try container.encode("")
                        }
                    }
                }
                
                if let qrData = try? decoder.decode(IssueQRData.self, from: jsonData) {
                    print("Successfully decoded QR data")
                    print("Book Issue: \(qrData.bookIssue)")
                    
                    // Get book IDs - handle both single and multiple book IDs
                    let bookIds: [String]
                    if let singleBookId = qrData.bookIssue.bookId {
                        bookIds = [singleBookId]
                    } else if let multipleBookIds = qrData.bookIssue.bookIds {
                        bookIds = multipleBookIds
                    } else {
                        print("No book IDs found")
                        return .failure(.missingFields)
                    }
                    
                    print("Found book IDs: \(bookIds)")
                    
                    // Handle both string and numeric timestamps
                    let expirationDate: TimeInterval
                    if let expDate = qrData.expirationDate?.value {
                        if let stringValue = expDate as? String {
                            expirationDate = TimeInterval(stringValue) ?? 0
                        } else if let doubleValue = expDate as? Double {
                            expirationDate = doubleValue
                        } else {
                            expirationDate = 0
                        }
                    } else {
                        expirationDate = 0
                    }
                    
                    let timestamp: TimeInterval
                    if let ts = qrData.timestamp?.value {
                        if let stringValue = ts as? String {
                            timestamp = TimeInterval(stringValue) ?? 0
                        } else if let doubleValue = ts as? Double {
                            timestamp = doubleValue
                        } else {
                            timestamp = 0
                        }
                    } else {
                        timestamp = 0
                    }
                    
                    print("Expiration Date: \(expirationDate)")
                    print("Timestamp: \(timestamp)")
                    
                    // Convert BookIssue to BookInfo format
                    let bookInfo = BookInfo(
                        bookIds: bookIds,
                        memberId: qrData.bookIssue.memberId,
                        issueStatus: qrData.bookIssue.status,
                        issueDate: qrData.bookIssue.issueDate,
                        returnDate: qrData.bookIssue.returnDate,
                        expirationDate: expirationDate,
                        timestamp: timestamp,
                        isValid: qrData.isValid
                    )
                    
                    print("Created BookInfo: \(bookInfo)")
                    
                    // Validate required fields
                    if bookInfo.bookIds.isEmpty || bookInfo.memberId.isEmpty {
                        print("Missing required fields - Book IDs: \(bookInfo.bookIds), Member ID: \(bookInfo.memberId)")
                        return .failure(.missingFields)
                    }
                    
                    // Check if QR code is expired
                    if !bookInfo.isValid {
                        print("QR code is not valid")
                        return .failure(.expired)
                    }
                    
                    return .success(bookInfo)
                } else {
                    print("Failed to decode QR data")
                    // If JSON parsing fails, try text format
                    return parseTextFormat(from: qrContent)
                }
                
//            } catch {
//                print("JSON parsing error: \(error)")
//                // If JSON parsing fails, try text format parsing
//                return parseTextFormat(from: qrContent)
//            }
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
