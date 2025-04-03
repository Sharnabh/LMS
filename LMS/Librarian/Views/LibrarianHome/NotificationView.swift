//
//  NotificationView.swift
//  LMS
//
//  Created by Sharnabh on 28/03/25.
//

import SwiftUI

struct NotificationView: View {
    @StateObject private var announcementStore = AnnouncementStore()
    @State private var selectedSegment = 0
    @ObservedObject private var tracker = AnnouncementTracker.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            
            
            if announcementStore.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredAnnouncements.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No messages")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredAnnouncements) { announcement in
                        MessageStyleNotificationCard(announcement: announcement)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("Announcement")
    }
    
    var filteredAnnouncements: [AnnouncementModel] {
        let now = Date()
        
        if selectedSegment == 1 {
            return announcementStore.archivedAnnouncements.filter { announcement in
                isRelevantForLibrarian(announcement)
            }
        } else {
            return announcementStore.activeAnnouncements.filter { announcement in
                isRelevantForLibrarian(announcement) &&
                announcement.isActive &&
                !announcement.isArchived &&
                announcement.startDate <= now &&
                announcement.expiryDate > now
            }
        }
    }
    
    private func isRelevantForLibrarian(_ announcement: AnnouncementModel) -> Bool {
        announcement.type == .librarian || announcement.type == .all
    }
}

struct MessageStyleNotificationCard: View {
    let announcement: AnnouncementModel
    
    var body: some View {
        NavigationLink(destination: AnnouncementDetailView(announcement: announcement)) {
            HStack(spacing: 12) {
                // Avatar circle
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: typeIcon)
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(announcement.title)
                            .font(.system(size: 16, weight: .semibold))
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(formattedTime)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    Text(announcement.content)
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var typeIcon: String {
        switch announcement.type {
        case .member:
            return "person.fill"
        case .librarian:
            return "books.vertical.fill"
        case .all:
            return "megaphone.fill"
        }
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: announcement.startDate)
    }
}

struct AnnouncementDetailView: View {
    let announcement: AnnouncementModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with icon and message title
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: typeIcon)
                                .foregroundColor(.gray)
                                .font(.system(size: 20))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(announcement.title)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                        Text(formattedDate)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Content
                Text(announcement.content)
                    .font(.body)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var typeIcon: String {
        switch announcement.type {
        case .member:
            return "person.fill"
        case .librarian:
            return "books.vertical.fill"
        case .all:
            return "megaphone.fill"
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy 'at' h:mm a"
        return formatter.string(from: announcement.startDate)
    }
}

#Preview {
    NotificationView()
}
