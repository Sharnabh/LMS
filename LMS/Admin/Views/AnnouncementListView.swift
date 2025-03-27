import SwiftUI

struct AnnouncementListView: View {
    @Environment(\.dismiss) private var dismiss
    let type: HomeView.AnnouncementListType
    @ObservedObject var announcementStore: AnnouncementStore
    @State private var isLoading = false
    
    private var announcements: [AnnouncementModel] {
        switch type {
        case .active:
            return announcementStore.activeAnnouncements
        case .scheduled:
            return announcementStore.scheduledAnnouncements
        case .archived:
            return announcementStore.archivedAnnouncements
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if announcements.isEmpty {
                    EmptyStateView(type: type)
                } else {
                    List {
                        ForEach(announcements) { announcement in
                            AnnouncementRow(
                                announcement: announcement,
                                type: type,
                                isLoading: $isLoading
                            ) { action in
                                handleAction(action, for: announcement)
                            }
                        }
                    }
                }
                
                if isLoading {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                }
            }
            .navigationTitle("\(type.title) Announcements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
            }
        }
    }
    
    private func handleAction(_ action: AnnouncementRow.AnnouncementAction, for announcement: AnnouncementModel) {
        isLoading = true
        
        Task {
            do {
                switch action {
                case .archive:
                    try await announcementStore.archiveAnnouncement(id: announcement.id)
                case .restore:
                    try await announcementStore.restoreAnnouncement(id: announcement.id)
                }
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                print("Error performing action: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

struct EmptyStateView: View {
    let type: HomeView.AnnouncementListType
    
    private var message: String {
        switch type {
        case .active:
            return "No active announcements"
        case .scheduled:
            return "No scheduled announcements"
        case .archived:
            return "No archived announcements"
        }
    }
    
    private var icon: String {
        switch type {
        case .active:
            return "megaphone"
        case .scheduled:
            return "calendar"
        case .archived:
            return "archivebox"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
            
            if type == .active {
                Text("Create a new announcement to get started")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct AnnouncementRow: View {
    let announcement: AnnouncementModel
    let type: HomeView.AnnouncementListType
    @Binding var isLoading: Bool
    let onAction: (AnnouncementAction) -> Void
    
    enum AnnouncementAction {
        case archive, restore
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(announcement.title)
                    .font(.headline)
                
                Spacer()
                
                Menu {
                    if type != .archived {
                        Button(role: .destructive, action: {
                            onAction(.archive)
                        }) {
                            Label("Archive", systemImage: "archivebox")
                        }
                        .disabled(isLoading)
                    } else {
                        Button(action: {
                            onAction(.restore)
                        }) {
                            Label("Restore", systemImage: "arrow.uturn.up")
                        }
                        .disabled(isLoading)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                }
            }
            
            Text(announcement.content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Label(announcement.type.rawValue.capitalized, systemImage: "person.2")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Spacer()
                
                if type == .scheduled {
                    Label(announcement.expiryDate.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AnnouncementListView_Previews: PreviewProvider {
    static var previews: some View {
        AnnouncementListView(
            type: .active,
            announcementStore: AnnouncementStore()
        )
    }
} 