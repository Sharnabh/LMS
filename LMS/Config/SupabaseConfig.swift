import Foundation
import Supabase

enum SupabaseConfig {
    static let supabaseURL = URL(string: "https://iswzgemgctojcdnbxvjv.supabase.co")!
    static let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlzd3pnZW1nY3RvamNkbmJ4dmp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIyMzAwODgsImV4cCI6MjA1NzgwNjA4OH0.zmATRCYC3V8_BtROa_PzmFxabWQf0NjyNSQaMrwPL7E"
    
    static let client = SupabaseClient(
        supabaseURL: supabaseURL,
        supabaseKey: supabaseKey
    )
    
    static func testConnection() async throws -> Bool {
        do {
            // Try to fetch a single record from the Books table
            let response = try await client
                .from("Books")
                .select()
                .limit(1)
                .execute()
            
            // Check if we got a valid response
            return !response.data.isEmpty
        } catch {
            print("Supabase connection error: \(error)")
            return false
        }
    }
} 
