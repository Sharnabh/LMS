//
//  AnalyticsService.swift
//  LMS
//
//  Created by Utkarsh Raj Saxena on 19/03/25.
//

import Foundation
import Supabase

class AnalyticsService {
    static let shared = AnalyticsService()
    private let supabase: SupabaseClient
    
    private init() {
        self.supabase = SupabaseConfig.client
    }
    
    // Get currently issued books count
    func getIssuedBooksCount() async throws -> Int {
        let response = try await supabase
            .from("BookIssue")
            .select("*", head: true, count: .exact)
            .eq("status", value: "Issue")
            .execute()
        
        return response.count ?? 0
    }
    
    // Get overdue books count
    func getOverdueBooksCount() async throws -> Int {
        let today = ISO8601DateFormatter().string(from: Date())
        let response = try await supabase
            .from("BookIssue")
            .select("*", head: true, count: .exact)
            .eq("status", value: "Issue")
            .lt("dueDate", value: today)
            .execute()
        
        return response.count ?? 0
    }
    
    // Get books due today
    func getBooksDueToday() async throws -> Int {
        let today = ISO8601DateFormatter().string(from: Date())
        let response = try await supabase
            .from("BookIssue")
            .select("*", head: true, count: .exact)
            .eq("status", value: "Issue")
            .eq("dueDate", value: today)
            .execute()
        
        return response.count ?? 0
    }
    
    // Get total revenue from fines
    func getTotalRevenue() async throws -> Double {
        let response = try await supabase
            .from("BookIssue")
            .select("fine")
            .eq("status", value: "Returned")
            .execute()
        
        struct FineResponse: Codable {
            let fine: Double
        }
        
        let decoder = JSONDecoder()
        let fines = try decoder.decode([FineResponse].self, from: response.data)
        return fines.reduce(0) { $0 + $1.fine }
    }
    
    // Get active members count (not disabled)
    func getActiveMembersCount() async throws -> Int {
        let response = try await supabase
            .from("Member")
            .select("*", head: true, count: .exact)
            .eq("is_disabled", value: false)
            .execute()
        
        return response.count ?? 0
    }
    
    // Get members with overdue books
    func getMembersWithOverdueBooks() async throws -> Int {
        let today = ISO8601DateFormatter().string(from: Date())
        let response = try await supabase
            .from("BookIssue")
            .select("memberId")
            .eq("status", value: "Issue")
            .lt("dueDate", value: today)
            .execute()
        
        return response.count ?? 0
    }
} 
