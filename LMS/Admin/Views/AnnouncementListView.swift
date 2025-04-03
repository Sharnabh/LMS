import SwiftUI

// Move enum outside and make it accessible
enum AnnouncementAction {
    case archive
    case restore(AnnouncementModel)
    case edit(AnnouncementModel)
}

struct AnnouncementListView: View {
    @Environment(\.dismiss) private var dismiss
    let type: HomeView.AnnouncementListType
    @ObservedObject var announcementStore: AnnouncementStore
    @State private var isLoading = false
    @State private var errorMessage: String?
    
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
                if announcementStore.isLoading {
                    ProgressView("Loading announcements...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                } else if announcements.isEmpty {
                    EmptyStateView(type: type)
                } else {
                    List {
                        ForEach(announcements) { announcement in
                            AnnouncementRow(
                                announcement: announcement,
                                type: type,
                                announcementStore: announcementStore,
                                isLoading: $isLoading
                            ) { action in
                                handleAction(action, for: announcement)
                            }
                        }
                    }
                    .refreshable {
                        await announcementStore.loadAnnouncements()
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
                
                if let error = errorMessage {
                    VStack {
                        Spacer()
                        Text(error)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red.opacity(0.9))
                            .cornerRadius(8)
                            .padding()
                    }
                }
            }
            .navigationTitle("\(type.title) Announcements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(isLoading || announcementStore.isLoading)
                }
            }
            .onAppear {
                // Force a refresh when the view appears
                Task {
                    await announcementStore.loadAnnouncements()
                }
            }
        }
    }
    
    private func handleAction(_ action: AnnouncementAction, for announcement: AnnouncementModel) {
        Task { @MainActor in
            isLoading = true
            errorMessage = nil
            
            do {
                switch action {
                case .archive:
                    try await announcementStore.archiveAnnouncement(id: announcement.id)
                    // Force refresh after archiving
                    await announcementStore.loadAnnouncements()
                case .restore(let updatedAnnouncement):
                    // Validate dates before restoring
                    let now = Date()
                    if updatedAnnouncement.expiryDate < now {
                        errorMessage = "Expiry date must be in the future"
                        isLoading = false
                        return
                    }
                    
                    try await announcementStore.restoreAnnouncement(updatedAnnouncement)
                    // Force refresh after restoring
                    await announcementStore.loadAnnouncements()
                case .edit(let updatedAnnouncement):
                    try await announcementStore.updateAnnouncement(updatedAnnouncement)
                    // Force refresh after editing
                    await announcementStore.loadAnnouncements()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isLoading = false
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
    @ObservedObject var announcementStore: AnnouncementStore
    @Binding var isLoading: Bool
    let onAction: (AnnouncementAction) -> Void
    @State private var showingEditSheet = false
    @State private var showingRestoreSheet = false
    
    init(
        announcement: AnnouncementModel,
        type: HomeView.AnnouncementListType,
        announcementStore: AnnouncementStore,
        isLoading: Binding<Bool>,
        onAction: @escaping (AnnouncementAction) -> Void
    ) {
        self.announcement = announcement
        self.type = type
        self.announcementStore = announcementStore
        self._isLoading = isLoading
        self.onAction = onAction
    }
    
    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(announcement.title)
                    .font(.headline)
                
                Spacer()
                
                Menu {
                    if type != .archived {
                        Button(action: {
                            showingEditSheet = true
                        }) {
                            Label("Edit", systemImage: "pencil")
                        }
                        .disabled(isLoading)
                        
                        Button(role: .destructive, action: {
                            onAction(.archive)
                        }) {
                            Label("Archive", systemImage: "archivebox")
                        }
                        .disabled(isLoading)
                    } else {
                        Button(action: {
                            showingRestoreSheet = true
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
                    .foregroundColor(.accentColor)
                
                Spacer()
                
                if type != .archived {
                    VStack(alignment: .trailing, spacing: 4) {
                        Label {
                            Text(dateFormatter.string(from: announcement.startDate))
                                .foregroundColor(type == .active ? .green : .orange)
                        } icon: {
                            Image(systemName: "calendar.badge.plus")
                                .foregroundColor(type == .active ? .green : .orange)
                        }
                        
                        Label {
                            Text(dateFormatter.string(from: announcement.expiryDate))
                                .foregroundColor(type == .active ? .green : .orange)
                        } icon: {
                            Image(systemName: "calendar.badge.minus")
                                .foregroundColor(type == .active ? .green : .orange)
                        }
                    }
                    .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingEditSheet) {
            EditAnnouncementView(
                announcementStore: announcementStore,
                announcement: announcement
            )
        }
        .sheet(isPresented: $showingRestoreSheet) {
            EditAnnouncementView(
                announcementStore: announcementStore,
                announcement: announcement,
                isRestoring: true,
                onRestore: { updatedAnnouncement in
                    onAction(.restore(updatedAnnouncement))
                }
            )
        }
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
