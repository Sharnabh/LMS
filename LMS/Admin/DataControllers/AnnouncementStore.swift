import Foundation
import SwiftUI

class AnnouncementStore: ObservableObject {
    @Published var activeAnnouncements: [AnnouncementModel] = []
    @Published var scheduledAnnouncements: [AnnouncementModel] = []
    @Published var archivedAnnouncements: [AnnouncementModel] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    let dataController = SupabaseDataController()
    private var nextUpdateTimer: Timer?
    private var refreshTask: Task<Void, Never>?
    private var isRefreshing = false
    
    init() {
        setupNextUpdate()
    }
    
    deinit {
        cancelNextUpdate()
    }
    
    private func setupNextUpdate() {
        // Cancel any existing timer
        cancelNextUpdate()
        
        // Initial load
        Task { @MainActor in
            await loadAnnouncements()
            scheduleNextUpdate()
        }
    }
    
    private func cancelNextUpdate() {
        nextUpdateTimer?.invalidate()
        nextUpdateTimer = nil
        refreshTask?.cancel()
        refreshTask = nil
    }
    
    private func scheduleNextUpdate() {
        // Find the next time we need to update based on announcement transitions
        var nextUpdateTime: Date?
        let now = Date()
        
        // Check scheduled announcements for next start time
        for announcement in scheduledAnnouncements {
            if announcement.startDate > now {
                if nextUpdateTime == nil || announcement.startDate < nextUpdateTime! {
                    nextUpdateTime = announcement.startDate
                }
            }
        }
        
        // Check active announcements for next expiry time
        for announcement in activeAnnouncements {
            if announcement.expiryDate > now {
                if nextUpdateTime == nil || announcement.expiryDate < nextUpdateTime! {
                    nextUpdateTime = announcement.expiryDate
                }
            }
        }
        
        // If we found a next update time, schedule the timer
        if let updateTime = nextUpdateTime {
            let timeInterval = updateTime.timeIntervalSince(now)
            print("📅 Scheduling next update in \(timeInterval) seconds")
            
            nextUpdateTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    await self.loadAnnouncements()
                    self.scheduleNextUpdate() // Schedule the next update after loading
                }
            }
        }
    }
    
    @MainActor
    func loadAnnouncements() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        
        let wasLoading = isLoading
        if !wasLoading {
            isLoading = true
        }
        
        do {
            let isConnected = try await dataController.testConnection()
            guard isConnected else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to connect to database"])
            }
            
            async let activeTask = AnnouncementService.shared.fetchActiveAnnouncements()
            async let scheduledTask = AnnouncementService.shared.fetchScheduledAnnouncements()
            async let archivedTask = AnnouncementService.shared.fetchArchivedAnnouncements()
            
            let (active, scheduled, archived) = try await (activeTask, scheduledTask, archivedTask)
            
            if !Task.isCancelled {
                self.activeAnnouncements = active
                self.scheduledAnnouncements = scheduled
                self.archivedAnnouncements = archived
                self.error = nil
                
                // Schedule next update based on the new data
                scheduleNextUpdate()
            }
        } catch {
            print("Error loading announcements: \(error)")
            self.error = error
        }
        
        if !wasLoading {
            isLoading = false
        }
        isRefreshing = false
    }
    
    func createAnnouncement(title: String, content: String, type: AnnouncementType, startDate: Date, expiryDate: Date) async {
        do {
            let _ = try await AnnouncementService.shared.createAnnouncement(
                title: title,
                content: content,
                type: type,
                startDate: startDate,
                expiryDate: expiryDate
            )
            await loadAnnouncements()
        } catch {
            self.error = error
        }
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