import Foundation
import Supabase

// Struct for announcement updates
private struct AnnouncementUpdate: Encodable {
    let is_active: Bool
    let is_archived: Bool
    let last_modified: String
}

class AnnouncementService {
    static let shared = AnnouncementService()
    private let supabase: SupabaseClient
    
    private init() {
        // Initialize Supabase client
        self.supabase = SupabaseConfig.client
    }
    
    // Create a new announcement
    func createAnnouncement(title: String, content: String, type: AnnouncementType, expiryDate: Date) async throws -> AnnouncementModel {
        let announcement = AnnouncementModel(
            id: UUID(),
            title: title,
            content: content,
            type: type,
            expiryDate: expiryDate,
            createdAt: Date(),
            isActive: true,
            isArchived: false,
            lastModified: Date()
        )
        
        try await supabase
            .from("announcements")
            .insert(announcement)
            .execute()
        
        return announcement
    }
    
    // Fetch active announcements
    func fetchActiveAnnouncements() async throws -> [AnnouncementModel] {
        let response = try await supabase
            .from("announcements")
            .select()
            .eq("is_active", value: true)
            .eq("is_archived", value: false)
            .lte("expiry_date", value: ISO8601DateFormatter().string(from: Date()))
            .order("created_at", ascending: false)
            .execute()
        
        let decoder = JSONDecoder()
        return try decoder.decode([AnnouncementModel].self, from: response.data)
    }
    
    // Fetch scheduled announcements
    func fetchScheduledAnnouncements() async throws -> [AnnouncementModel] {
        let response = try await supabase
            .from("announcements")
            .select()
            .eq("is_active", value: true)
            .eq("is_archived", value: false)
            .gt("expiry_date", value: ISO8601DateFormatter().string(from: Date()))
            .order("expiry_date", ascending: true)
            .execute()
        
        let decoder = JSONDecoder()
        return try decoder.decode([AnnouncementModel].self, from: response.data)
    }
    
    // Fetch archived announcements
    func fetchArchivedAnnouncements() async throws -> [AnnouncementModel] {
        let response = try await supabase
            .from("announcements")
            .select()
            .eq("is_archived", value: true)
            .order("last_modified", ascending: false)
            .execute()
        
        let decoder = JSONDecoder()
        return try decoder.decode([AnnouncementModel].self, from: response.data)
    }
    
    // Update an announcement
    func updateAnnouncement(_ announcement: AnnouncementModel) async throws {
        try await supabase
            .from("announcements")
            .update(announcement)
            .eq("id", value: announcement.id)
            .execute()
    }
    
    // Archive an announcement
    func archiveAnnouncement(id: UUID) async throws {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let updateData = AnnouncementUpdate(
            is_active: false,
            is_archived: true,
            last_modified: dateFormatter.string(from: Date())
        )
        
        try await supabase
            .from("announcements")
            .update(updateData)
            .eq("id", value: id)
            .execute()
    }
    
    // Restore an archived announcement
    func restoreAnnouncement(id: UUID) async throws {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let updateData = AnnouncementUpdate(
            is_active: true,
            is_archived: false,
            last_modified: dateFormatter.string(from: Date())
        )
        
        try await supabase
            .from("announcements")
            .update(updateData)
            .eq("id", value: id)
            .execute()
    }
} 