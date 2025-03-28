import Foundation
import SwiftUI

class AnnouncementStore: ObservableObject {
    @Published var activeAnnouncements: [AnnouncementModel] = []
    @Published var scheduledAnnouncements: [AnnouncementModel] = []
    @Published var archivedAnnouncements: [AnnouncementModel] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    let dataController = SupabaseDataController()
    
    init() {
        Task(priority: .userInitiated) {
            do {
                let isConnected = try await dataController.testConnection()
                if isConnected {
                    await loadAnnouncements()
                } else {
                    print("AnnouncementStore initialization failed - connection test failed")
                }
            } catch {
                print("Failed to connect to database: \(error)")
            }
        }
    }
    
    @MainActor
    func loadAnnouncements() async {
        isLoading = true
        error = nil
        
        do {
            // Load active announcements
            activeAnnouncements = try await AnnouncementService.shared.fetchActiveAnnouncements()
            
            // Load scheduled announcements
            scheduledAnnouncements = try await AnnouncementService.shared.fetchScheduledAnnouncements()
            
            // Load archived announcements
            archivedAnnouncements = try await AnnouncementService.shared.fetchArchivedAnnouncements()
            
            print("Successfully loaded announcements")
        } catch {
            print("Error loading announcements: \(error)")
            self.error = error
            activeAnnouncements = []
            scheduledAnnouncements = []
            archivedAnnouncements = []
        }
        
        isLoading = false
    }
    
    func createAnnouncement(title: String, content: String, type: AnnouncementType, startDate: Date, expiryDate: Date) async throws {
        try await AnnouncementService.shared.createAnnouncement(
            title: title,
            content: content,
            type: type,
            startDate: startDate,
            expiryDate: expiryDate
        )
        await loadAnnouncements()
    }
    
    func updateAnnouncement(_ announcement: AnnouncementModel) async throws {
        try await AnnouncementService.shared.updateAnnouncement(announcement)
        await loadAnnouncements()
    }
    
    func archiveAnnouncement(id: UUID) async throws {
        try await AnnouncementService.shared.archiveAnnouncement(id: id)
        await loadAnnouncements()
    }
    
    func restoreAnnouncement(_ announcement: AnnouncementModel) async throws {
        try await AnnouncementService.shared.restoreAnnouncement(announcement)
        await loadAnnouncements()
    }
} 