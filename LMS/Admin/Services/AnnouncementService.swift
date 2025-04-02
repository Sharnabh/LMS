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
    
    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private init() {
        // Initialize Supabase client
        self.supabase = SupabaseConfig.client
    }
    
    // Helper method to determine if an announcement should be active
    private func shouldBeActive(startDate: Date, expiryDate: Date, isArchived: Bool) -> Bool {
        let now = Date()
        return !isArchived && now >= startDate && now <= expiryDate
    }
    
    // Helper method to convert local date to UTC
    private func localToUTC(_ date: Date) -> Date {
        let timezone = TimeZone.current
        let seconds = TimeInterval(timezone.secondsFromGMT(for: date))
        return date.addingTimeInterval(-seconds)
    }
    
    // Helper method to convert UTC to local date
    private func UTCToLocal(_ date: Date) -> Date {
        let timezone = TimeZone.current
        let seconds = TimeInterval(timezone.secondsFromGMT(for: date))
        return date.addingTimeInterval(seconds)
    }
    
    // Create a new announcement
    func createAnnouncement(title: String, content: String, type: AnnouncementType, startDate: Date, expiryDate: Date) async throws -> AnnouncementModel {
        let now = Date()
        let utcStartDate = localToUTC(startDate)
        let utcExpiryDate = localToUTC(expiryDate)
        let utcNow = localToUTC(now)
        
        let isActive = shouldBeActive(startDate: startDate, expiryDate: expiryDate, isArchived: false)
        
        let announcement = AnnouncementModel(
            id: UUID(),
            title: title,
            content: content,
            type: type,
            startDate: startDate,
            expiryDate: expiryDate,
            createdAt: now,
            isActive: isActive,
            isArchived: false,
            lastModified: now
        )
        
        let insertData = AnnouncementInsert(
            id: announcement.id.uuidString,
            title: announcement.title,
            content: announcement.content,
            type: announcement.type.rawValue,
            start_date: dateFormatter.string(from: utcStartDate),
            expiry_date: dateFormatter.string(from: utcExpiryDate),
            created_at: dateFormatter.string(from: utcNow),
            is_active: isActive,
            is_archived: false,
            last_modified: dateFormatter.string(from: utcNow)
        )
        
        try await supabase
            .from("announcements")
            .insert(insertData)
            .execute()
        
        return announcement
    }
    
    // Update an announcement
    func updateAnnouncement(_ announcement: AnnouncementModel) async throws {
        let now = Date()
        let utcNow = localToUTC(now)
        let utcStartDate = localToUTC(announcement.startDate)
        let utcExpiryDate = localToUTC(announcement.expiryDate)
        
        let isActive = shouldBeActive(startDate: announcement.startDate, 
                                    expiryDate: announcement.expiryDate, 
                                    isArchived: announcement.isArchived)
        
        let updateData = AnnouncementFullUpdate(
            title: announcement.title,
            content: announcement.content,
            type: announcement.type.rawValue,
            start_date: dateFormatter.string(from: utcStartDate),
            expiry_date: dateFormatter.string(from: utcExpiryDate),
            is_active: isActive,
            is_archived: announcement.isArchived,
            last_modified: dateFormatter.string(from: utcNow)
        )
        
        try await supabase
            .from("announcements")
            .update(updateData)
            .eq("id", value: announcement.id.uuidString)
            .execute()
    }
    
    // Restore an announcement
    func restoreAnnouncement(_ announcement: AnnouncementModel) async throws {
        let now = Date()
        let utcNow = localToUTC(now)
        let utcStartDate = localToUTC(announcement.startDate)
        let utcExpiryDate = localToUTC(announcement.expiryDate)
        
        let isActive = shouldBeActive(startDate: announcement.startDate, 
                                    expiryDate: announcement.expiryDate, 
                                    isArchived: false)
        
        let updateData = AnnouncementFullUpdate(
            title: announcement.title,
            content: announcement.content,
            type: announcement.type.rawValue,
            start_date: dateFormatter.string(from: utcStartDate),
            expiry_date: dateFormatter.string(from: utcExpiryDate),
            is_active: isActive,
            is_archived: false,
            last_modified: dateFormatter.string(from: utcNow)
        )
        
        try await supabase
            .from("announcements")
            .update(updateData)
            .eq("id", value: announcement.id.uuidString)
            .execute()
    }
    
    // Archive an announcement
    func archiveAnnouncement(id: UUID) async throws {
        let now = Date()
        let utcNow = localToUTC(now)
        
        let updateData = AnnouncementUpdate(
            is_active: false,
            is_archived: true,
            last_modified: dateFormatter.string(from: utcNow)
        )
        
        try await supabase
            .from("announcements")
            .update(updateData)
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    // Fetch active announcements
    func fetchActiveAnnouncements() async throws -> [AnnouncementModel] {
        let now = Date()
        let utcNow = localToUTC(now)
        let nowString = dateFormatter.string(from: utcNow)
        
        print("Checking announcements at: \(now)")
        
        // First, get all non-archived announcements that have started
        let response = try await supabase
            .from("announcements")
            .select()
            .eq("is_archived", value: false)
            .lte("start_date", value: nowString)
            .order("created_at", ascending: false)
            .execute()
        
        let decoder = JSONDecoder()
        let announcements = try decoder.decode([AnnouncementModel].self, from: response.data)
        
        var activeAnnouncements: [AnnouncementModel] = []
        
        for var announcement in announcements {
            // Convert UTC dates to local
            announcement.startDate = UTCToLocal(announcement.startDate)
            announcement.expiryDate = UTCToLocal(announcement.expiryDate)
            announcement.createdAt = UTCToLocal(announcement.createdAt)
            announcement.lastModified = UTCToLocal(announcement.lastModified)
            
            print("Checking announcement: \(announcement.title)")
            print("Expiry date: \(announcement.expiryDate)")
            print("Current time: \(now)")
            
            // Check if the announcement has expired
            if announcement.expiryDate < now {
                print("🚨 Announcement '\(announcement.title)' has expired! Attempting to archive...")
                
                // Update the database to mark it as archived
                let updateData = AnnouncementUpdate(
                    is_active: false,
                    is_archived: true,
                    last_modified: dateFormatter.string(from: utcNow)
                )
                
                print("📝 Updating announcement with data: \(String(describing: updateData))")
                print("🔍 For announcement ID: \(announcement.id.uuidString)")
                
                do {
                    try await supabase
                        .from("announcements")
                        .update(updateData)
                        .eq("id", value: announcement.id.uuidString)
                        .execute()
                    
                    print("✅ Successfully archived announcement: \(announcement.title)")
                    
                    // Verify the update
                    let verifyResponse = try await supabase
                        .from("announcements")
                        .select()
                        .eq("id", value: announcement.id.uuidString)
                        .execute()
                    
                    if let verifyData = try? decoder.decode([AnnouncementModel].self, from: verifyResponse.data),
                       let updated = verifyData.first {
                        print("✅ Verified update - is_archived: \(updated.isArchived), is_active: \(updated.isActive)")
                    } else {
                        print("⚠️ Could not verify update")
                    }
                } catch {
                    print("❌ Failed to archive announcement: \(error.localizedDescription)")
                    print("❌ Error details: \(error)")
                }
                    
                continue // Skip this announcement since it's now archived
            }
            
            // If not expired and within active period, add to active announcements
            if announcement.startDate <= now && announcement.expiryDate >= now {
                announcement.isActive = true
                activeAnnouncements.append(announcement)
                print("📢 Announcement '\(announcement.title)' is active")
            } else {
                print("⏳ Announcement '\(announcement.title)' is not in active period")
            }
        }
        
        return activeAnnouncements
    }
    
    // Fetch scheduled announcements
    func fetchScheduledAnnouncements() async throws -> [AnnouncementModel] {
        let now = Date()
        let utcNow = localToUTC(now)
        let nowString = dateFormatter.string(from: utcNow)
        
        let response = try await supabase
            .from("announcements")
            .select()
            .eq("is_archived", value: false)
            .gt("start_date", value: nowString)
            .order("start_date", ascending: true)
            .execute()
        
        let decoder = JSONDecoder()
        let announcements = try decoder.decode([AnnouncementModel].self, from: response.data)
        
        // Convert UTC dates to local and update status
        var scheduledAnnouncements: [AnnouncementModel] = []
        
        for var announcement in announcements {
            // Convert UTC dates to local
            announcement.startDate = UTCToLocal(announcement.startDate)
            announcement.expiryDate = UTCToLocal(announcement.expiryDate)
            announcement.createdAt = UTCToLocal(announcement.createdAt)
            announcement.lastModified = UTCToLocal(announcement.lastModified)
            
            let shouldBeActive = shouldBeActive(
                startDate: announcement.startDate,
                expiryDate: announcement.expiryDate,
                isArchived: false
            )
            
            if shouldBeActive {
                // Update the announcement to be active
                announcement.isActive = true
                do {
                    try await updateAnnouncement(announcement)
                    // Don't add to scheduled announcements since it's now active
                } catch {
                    print("Failed to activate scheduled announcement: \(error)")
                }
            } else {
                announcement.isActive = false
                scheduledAnnouncements.append(announcement)
            }
        }
        
        return scheduledAnnouncements
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
        var announcements = try decoder.decode([AnnouncementModel].self, from: response.data)
        
        // Convert UTC dates to local
        for i in 0..<announcements.count {
            announcements[i].startDate = UTCToLocal(announcements[i].startDate)
            announcements[i].expiryDate = UTCToLocal(announcements[i].expiryDate)
            announcements[i].createdAt = UTCToLocal(announcements[i].createdAt)
            announcements[i].lastModified = UTCToLocal(announcements[i].lastModified)
            announcements[i].isActive = false
        }
        
        return announcements
    }
} 
