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
        VStack(alignment: .leading, spacing: 16) {
            Text("Announcements")
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            Picker("View Mode", selection: $selectedSegment) {
                Text("Active").tag(0)
                Text("Archived").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            if announcementStore.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredAnnouncements.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text(selectedSegment == 1 ? "No archived notifications" : "No active notifications")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredAnnouncements) { announcement in
                            NotificationCard(announcement: announcement)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .onAppear {
            Task {
                await announcementStore.loadAnnouncements()
                
                // Mark all active announcements as seen when the view appears
                if selectedSegment == 0 {
                    tracker.markAllAsSeen(filteredAnnouncements)
                }
            }
        }
        .onChange(of: selectedSegment) { oldValue, newValue in
            // Mark active announcements as seen when switching to active tab
            if newValue == 0 {
                tracker.markAllAsSeen(filteredAnnouncements)
            }
        }
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

struct NotificationCard: View {
    let announcement: AnnouncementModel
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(announcement.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        
                        Text(statusText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(formattedDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            if isExpanded {
                Text(announcement.content)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 4)
            } else {
                Text(truncatedContent)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .padding(.bottom, 4)
            }
            
            if announcement.content.count > 120 {
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Text(isExpanded ? "Show less" : "Read more")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.accentColor)
                }
                .padding(.top, 2)
            }
            
            HStack {
                Label(announcement.type.rawValue.capitalized, systemImage: typeIcon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(typeBackgroundColor.opacity(0.2))
                    .cornerRadius(12)
                
                Spacer()
                
                if let daysRemaining = daysRemaining, daysRemaining > 0 {
                    Text("Expires in \(daysRemaining) day\(daysRemaining == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var truncatedContent: String {
        if announcement.content.count > 120 {
            return String(announcement.content.prefix(120)) + "..."
        }
        return announcement.content
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: announcement.startDate)
    }
    
    private var daysRemaining: Int? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: announcement.expiryDate)
        return components.day
    }
    
    private var statusColor: Color {
        if !announcement.isActive {
            return .gray
        }
        
        let now = Date()
        if announcement.startDate > now {
            return .orange
        } else if announcement.expiryDate < now {
            return .gray
        } else {
            return .green
        }
    }
    
    private var statusText: String {
        if !announcement.isActive {
            return "Inactive"
        }
        
        let now = Date()
        if announcement.startDate > now {
            return "Upcoming"
        } else if announcement.expiryDate < now {
            return "Expired"
        } else {
            return "Active"
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
    
    private var typeBackgroundColor: Color {
        switch announcement.type {
        case .member:
            return .blue
        case .librarian:
            return .purple
        case .all:
            return .orange
        }
    }
    
    private var cardBackgroundColor: Color {
        if announcement.isArchived {
            return Color(.systemBackground).opacity(0.8)
        } else {
            let priority = priorityLevel
            switch priority {
            case .high:
                return Color.red.opacity(0.08)
            case .medium:
                return Color.orange.opacity(0.08)
            case .low:
                return Color(.systemBackground)
            }
        }
    }
    
    private var priorityLevel: PriorityLevel {
        // This is a simple implementation. You could enhance this logic
        // based on keywords in the title/content or other attributes
        
        if announcement.title.lowercased().contains("urgent") ||
           announcement.title.lowercased().contains("emergency") ||
           announcement.content.lowercased().contains("immediate action") {
            return .high
        } else if announcement.title.lowercased().contains("important") ||
                  announcement.content.lowercased().contains("please note") {
            return .medium
        } else {
            return .low
        }
    }
    
    enum PriorityLevel {
        case high, medium, low
    }
}

#Preview {
    NotificationView()
}
