import Foundation
import SwiftUI

class AnnouncementStore: ObservableObject {
    @Published var activeAnnouncements: [AnnouncementModel] = []
    @Published var scheduledAnnouncements: [AnnouncementModel] = []
    @Published var archivedAnnouncements: [AnnouncementModel] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    let dataController = SupabaseDataController()
    private var refreshTimer: Timer?
    private var refreshTask: Task<Void, Never>?
    private var isRefreshing = false
    private var backgroundTask: Task<Void, Never>?
    
    init() {
        startPeriodicRefresh()
        setupNotificationObservers()
    }
    
    deinit {
        stopPeriodicRefresh()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNotificationObservers() {
        // Listen for app entering background
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBackgroundTransition),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // Listen for app becoming active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleForegroundTransition),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func handleBackgroundTransition() {
        // Cancel existing refresh timer
        refreshTimer?.invalidate()
        refreshTimer = nil
        
        // Start background task for periodic updates
        backgroundTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                await self?.loadAnnouncements()
                try? await Task.sleep(nanoseconds: 10 * 1_000_000_000) // 10 seconds
            }
        }
    }
    
    @objc private func handleForegroundTransition() {
        // Cancel background task
        backgroundTask?.cancel()
        backgroundTask = nil
        
        // Immediately refresh and restart normal timer
        Task { @MainActor in
            await loadAnnouncements()
            startPeriodicRefresh()
        }
    }
    
    private func startPeriodicRefresh() {
        // Cancel existing timer if any
        refreshTimer?.invalidate()
        
        // Initial load
        Task { @MainActor in
            await loadAnnouncements()
        }
        
        // Set up a timer to refresh announcements every 10 seconds
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Cancel any existing refresh task
            self.refreshTask?.cancel()
            
            // Start a new refresh task
            self.refreshTask = Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                // Only refresh if we're not already refreshing
                if !self.isRefreshing {
                    await self.loadAnnouncements()
                }
            }
        }
    }
    
    private func stopPeriodicRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        refreshTask?.cancel()
        refreshTask = nil
        backgroundTask?.cancel()
        backgroundTask = nil
    }
    
    @MainActor
    func loadAnnouncements() async {
        // Prevent multiple concurrent refreshes
        guard !isRefreshing else { return }
        isRefreshing = true
        
        // Don't show loading indicator for refresh operations
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
            
            // Load all announcements concurrently
            let (active, scheduled, archived) = try await (activeTask, scheduledTask, archivedTask)
            
            // Only update if the task hasn't been cancelled
            if !Task.isCancelled {
                // Only update if we successfully got all announcements
                await MainActor.run {
                    self.activeAnnouncements = active
                    self.scheduledAnnouncements = scheduled
                    self.archivedAnnouncements = archived
                    self.error = nil
                    
                    print("Successfully loaded announcements at \(Date())")
                }
            }
        } catch {
            print("Error loading announcements: \(error)")
            await MainActor.run {
                self.error = error
            }
            // Don't clear existing announcements on error to maintain last known good state
        }
        
        if !wasLoading {
            isLoading = false
        }
        isRefreshing = false
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