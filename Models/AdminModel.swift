import Foundation

struct Admin: Codable, Identifiable {
    let id: UUID
    let adminID: String
    let emailID: String
    let adminName: String
    var isFirstLogin: Bool
    
    enum CodingKeys: String, CodingKey {
        case id = "UUID"
        case adminID
        case emailID
        case adminName
        case isFirstLogin
    }
}

struct LoginResponse: Codable {
    let message: String
    let adminID: String
    let token: String?
    let isFirstLogin: Bool
}

struct PasswordChangeResponse: Codable {
    let message: String
    let token: String
}