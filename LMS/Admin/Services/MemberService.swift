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
            .from("members")
            .select("id", count: CountOption.exact)
            .execute()
        
        if let count = response.count {
            return count
        }
        
        return 0
    }
} 
