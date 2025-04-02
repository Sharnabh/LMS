import SwiftUI

struct AddAnnouncementView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var announcementStore: AnnouncementStore
    
    @State private var title = ""
    @State private var content = ""
    @State private var selectedType = AnnouncementType.all
    @State private var startDate = Date()
    @State private var expiryDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // Default 7 days
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var isError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Form {
                    Section(header: Text("Announcement Details")) {
                        TextField("Title", text: $title)
                        
                        TextEditor(text: $content)
                            .frame(height: 100)
                    }
                    
                    Section(header: Text("Target Audience")) {
                        Picker("Type", selection: $selectedType) {
                            Text("All").tag(AnnouncementType.all)
                            Text("Members").tag(AnnouncementType.member)
                            Text("Librarians").tag(AnnouncementType.librarian)
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Section(header: Text("Schedule")) {
                        DatePicker(
                            "Starts on",
                            selection: $startDate,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        
                        DatePicker(
                            "Expires on",
                            selection: $expiryDate,
                            in: startDate...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }
                .navigationTitle("New Announcement")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .disabled(isLoading)
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Create") {
                            createAnnouncement()
                        }
                        .disabled(title.isEmpty || content.isEmpty || isLoading)
                    }
                }
                .alert(isError ? "Error" : "Success", isPresented: $showingAlert) {
                    Button("OK") {
                        if !isError {
                            dismiss()
                        }
                    }
                } message: {
                    Text(alertMessage)
                }
                
                if isLoading {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    
                    ProgressView("Creating announcement...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                }
            }
        }
    }
    
    private func createAnnouncement() {
        isLoading = true
        
        Task {
//            do {
                await announcementStore.createAnnouncement(
                    title: title,
                    content: content,
                    type: selectedType,
                    startDate: startDate,
                    expiryDate: expiryDate
                )
                
                await MainActor.run {
                    isLoading = false
                    isError = false
                    alertMessage = "Announcement created successfully!"
                    showingAlert = true
                }
//            } catch {
//                await MainActor.run {
//                    isLoading = false
//                    isError = true
//                    alertMessage = "Failed to create announcement: \(error.localizedDescription)"
//                    showingAlert = true
//                }
//            }
        }
    }
}

struct AddAnnouncementView_Previews: PreviewProvider {
    static var previews: some View {
        AddAnnouncementView(announcementStore: AnnouncementStore())
    }
} 
