import Foundation
import Supabase

// Struct for announcement updates
private struct AnnouncementUpdate: Encodable {
    let is_active: Bool
    let is_archived: Bool
    let last_modified: String
}

// Struct for announcement inserts
private struct AnnouncementInsert: Encodable {
    let id: String
    let title: String
    let content: String
    let type: String
    let start_date: String
    let expiry_date: String
    let created_at: String
    let is_active: Bool
    let is_archived: Bool
    let last_modified: String
}

// Struct for announcement full updates
private struct AnnouncementFullUpdate: Encodable {
    let title: String
    let content: String
    let type: String
    let start_date: String
    let expiry_date: String
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
    func createAnnouncement(title: String, content: String, type: AnnouncementType, startDate: Date, expiryDate: Date) async throws -> AnnouncementModel {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let announcement = AnnouncementModel(
            id: UUID(),
            title: title,
            content: content,
            type: type,
            startDate: startDate,
            expiryDate: expiryDate,
            createdAt: Date(),
            isActive: true,
            isArchived: false,
            lastModified: Date()
        )
        
        let insertData = AnnouncementInsert(
            id: announcement.id.uuidString,
            title: announcement.title,
            content: announcement.content,
            type: announcement.type.rawValue,
            start_date: dateFormatter.string(from: announcement.startDate),
            expiry_date: dateFormatter.string(from: announcement.expiryDate),
            created_at: dateFormatter.string(from: announcement.createdAt),
            is_active: announcement.isActive,
            is_archived: announcement.isArchived,
            last_modified: dateFormatter.string(from: announcement.lastModified)
        )
        
        try await supabase
            .from("announcements")
            .insert(insertData)
            .execute()
        
        return announcement
    }
    
    // Fetch active announcements
    func fetchActiveAnnouncements() async throws -> [AnnouncementModel] {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let now = dateFormatter.string(from: Date())
        
        let response = try await supabase
            .from("announcements")
            .select()
            .eq("is_active", value: true)
            .eq("is_archived", value: false)
            .lte("start_date", value: now)
            .gt("expiry_date", value: now)
            .order("created_at", ascending: false)
            .execute()
        
        let decoder = JSONDecoder()
        return try decoder.decode([AnnouncementModel].self, from: response.data)
    }
    
    // Fetch scheduled announcements
    func fetchScheduledAnnouncements() async throws -> [AnnouncementModel] {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let now = dateFormatter.string(from: Date())
        
        let response = try await supabase
            .from("announcements")
            .select()
            .eq("is_active", value: true)
            .eq("is_archived", value: false)
            .gt("start_date", value: now)
            .order("start_date", ascending: true)
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
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let updateData = AnnouncementFullUpdate(
            title: announcement.title,
            content: announcement.content,
            type: announcement.type.rawValue,
            start_date: dateFormatter.string(from: announcement.startDate),
            expiry_date: dateFormatter.string(from: announcement.expiryDate),
            is_active: announcement.isActive,
            is_archived: announcement.isArchived,
            last_modified: dateFormatter.string(from: Date())
        )
        
        try await supabase
            .from("announcements")
            .update(updateData)
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