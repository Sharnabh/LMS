//
//  UnreadAnnouncementIcon.swift
//  LMS
//
//  Created by Sharnabh on 06/04/25.
//

import SwiftUI

struct UnreadAnnouncementIcon: View {
    @StateObject private var announcementStore = AnnouncementStore()
    @ObservedObject private var tracker = AnnouncementTracker.shared
    @State private var unreadCount = 0
    
    // Timer for refreshing announcements
    @State private var announcementsTimer: Timer? = nil
    
    var body: some View {
        NavigationLink(destination: NotificationView().onAppear {
            // Mark all announcements as seen when the user opens the notification view
            let relevantAnnouncements = getActiveLibrarianAnnouncements()
            tracker.markAllAsSeen(relevantAnnouncements)
            updateUnreadCount()
        }) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "megaphone.fill")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                
                if unreadCount > 0 {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 18, height: 18)
                        
                        if unreadCount < 10 {
                            Text("\(unreadCount)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("9+")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .offset(x: 8, y: -8)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .onAppear {
            updateUnreadCount()
            startAnnouncementsTimer()
        }
        .onDisappear {
            stopAnnouncementsTimer()
        }
        .onReceive(tracker.objectWillChange) { _ in
            // Update the badge when tracked announcements change
            updateUnreadCount()
        }
    }
    
    private func startAnnouncementsTimer() {
        // Cancel any existing timer
        stopAnnouncementsTimer()
        
        // Create a new timer that fires every 10 seconds
        announcementsTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            Task {
                await announcementStore.loadAnnouncements()
                await MainActor.run {
                    updateUnreadCount()
                }
            }
        }
    }
    
    private func stopAnnouncementsTimer() {
        announcementsTimer?.invalidate()
        announcementsTimer = nil
    }
    
    private func updateUnreadCount() {
        // Update on the main thread without reloading announcements
        // This avoids showing a loading indicator
        let relevantAnnouncements = getActiveLibrarianAnnouncements()
        unreadCount = tracker.getUnseenCount(from: relevantAnnouncements)
    }
    
    private func getActiveLibrarianAnnouncements() -> [AnnouncementModel] {
        let now = Date()
        
        return announcementStore.activeAnnouncements.filter { announcement in
            (announcement.type == .librarian || announcement.type == .all) &&
            announcement.isActive &&
            !announcement.isArchived &&
            announcement.startDate <= now &&
            announcement.expiryDate > now
        }
    }
}

#Preview {
    UnreadAnnouncementIcon()
} 
