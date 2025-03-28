import Foundation
import Supabase

class MemberService {
    static let shared = MemberService()
    private let supabase: SupabaseClient
    
    private init() {
        self.supabase = SupabaseConfig.client
    }
    
    func getTotalMembersCount() async throws -> Int {
        let response = try await supabase
            .from("Member")
            .select()
            .execute()
        
        // Print response for debugging
        if let jsonString = String(data: response.data, encoding: .utf8) {
            print("Supabase Response: \(jsonString)")
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let patrons = try decoder.decode([Patron].self, from: response.data)
        return patrons.count
    }
}

// Helper struct to decode patron data
private struct Patron: Codable {
    let id: String?
    let userId: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case createdAt = "created_at"
    }
} 
