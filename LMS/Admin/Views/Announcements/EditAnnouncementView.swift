import SwiftUI

struct EditAnnouncementView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var announcementStore: AnnouncementStore
    let announcement: AnnouncementModel
    let isRestoring: Bool
    let onRestore: ((AnnouncementModel) -> Void)?
    
    @State private var title: String
    @State private var content: String
    @State private var type: AnnouncementType
    @State private var startDate: Date
    @State private var expiryDate: Date
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    init(announcementStore: AnnouncementStore, 
         announcement: AnnouncementModel,
         isRestoring: Bool = false,
         onRestore: ((AnnouncementModel) -> Void)? = nil) {
        self.announcementStore = announcementStore
        self.announcement = announcement
        self.isRestoring = isRestoring
        self.onRestore = onRestore
        
        // When restoring, set start date to now if the original start date is in the past
        let now = Date()
        let initialStartDate = isRestoring && announcement.startDate < now ? now : announcement.startDate
        let initialExpiryDate = isRestoring && announcement.expiryDate < now ? now.addingTimeInterval(24*60*60) : announcement.expiryDate
        
        _title = State(initialValue: announcement.title)
        _content = State(initialValue: announcement.content)
        _type = State(initialValue: announcement.type)
        _startDate = State(initialValue: initialStartDate)
        _expiryDate = State(initialValue: initialExpiryDate)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Form {
                    detailsSection
                    scheduleSection
                    if let error = errorMessage {
                        errorSection(error)
                    }
                }
            }
            .navigationTitle(isRestoring ? "Restore Announcement" : "Edit Announcement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isRestoring ? "Restore" : "Save") {
                        isRestoring ? restore() : save()
                    }
                    .disabled(isLoading)
                }
            }
            .disabled(isLoading)
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
        }
    }
    
    private var detailsSection: some View {
        Section {
            TextField("Title", text: $title)
            TextEditor(text: $content)
                .frame(height: 100)
            
            Picker(selection: $type, label: Text("Type")) {
                ForEach(AnnouncementType.allCases, id: \.self) { type in
                    Text(type.rawValue.capitalized)
                }
            }
        } header: {
            Text("Announcement Details")
        }
    }
    
    private var scheduleSection: some View {
        Section {
            DatePicker("Start Date", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
            DatePicker("Expiry Date", selection: $expiryDate, in: startDate..., displayedComponents: [.date, .hourAndMinute])
        } header: {
            Text("Schedule")
        }
    }
    
    private func errorSection(_ error: String) -> some View {
        Section {
            Text(error)
                .foregroundColor(.red)
        }
    }
    
    private func validateInput() -> Bool {
        errorMessage = nil
        
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Title cannot be empty"
            return false
        }
        
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Content cannot be empty"
            return false
        }
        
        let now = Date()
        
        if isRestoring {
            guard startDate >= now else {
                errorMessage = "Start date must be in the future when restoring"
                return false
            }
        }
        
        guard startDate <= expiryDate else {
            errorMessage = "Start date must be before expiry date"
            return false
        }
        
        guard expiryDate > now else {
            errorMessage = "Expiry date must be in the future"
            return false
        }
        
        return true
    }
    
    private func restore() {
        guard validateInput() else { return }
        
        let updatedAnnouncement = AnnouncementModel(
            id: announcement.id,
            title: title,
            content: content,
            type: type,
            startDate: startDate,
            expiryDate: expiryDate,
            createdAt: announcement.createdAt,
            isActive: true,
            isArchived: false,
            lastModified: Date()
        )
        
        onRestore?(updatedAnnouncement)
        dismiss()
    }
    
    private func save() {
        guard validateInput() else { return }
        
        isLoading = true
        errorMessage = nil
        
        let updatedAnnouncement = AnnouncementModel(
            id: announcement.id,
            title: title,
            content: content,
            type: type,
            startDate: startDate,
            expiryDate: expiryDate,
            createdAt: announcement.createdAt,
            isActive: announcement.isActive,
            isArchived: announcement.isArchived,
            lastModified: Date()
        )
        
        Task {
            do {
                try await announcementStore.updateAnnouncement(updatedAnnouncement)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
} 