import SwiftUI
import Supabase
import PhotosUI

struct AdminProfile: Codable {
    var id: String
    var fullName: String
    var dateOfBirth: String
    var email: String
    var avatarUrl: String?
}

struct AdminProfileView: View {
    @State private var profile: AdminProfile?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var showingImagePicker = false
    @AppStorage("adminIsLoggedIn") private var adminIsLoggedIn = true
    @AppStorage("adminEmail") private var adminEmail = ""
    @State private var showingLogoutAlert = false
    @State private var shouldDismissToRoot = false
    @EnvironmentObject private var appState: AppState
    @State private var profileImage: UIImage?
    @State private var imageSelection: PhotosPickerItem?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading profile...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                VStack {
                    Text("Error loading profile")
                        .font(.headline)
                        .padding(.bottom, 8)
                    Text(errorMessage)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        loadProfile()
                    }
                    .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let profile = profile {
                profileContent(profile: profile)
            } else {
                Text("No profile data available")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            loadProfile()
        }
    }
    
    private func profileContent(profile: AdminProfile) -> some View {
        List {
            // Profile Photo Section
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        if let avatarUrl = profile.avatarUrl {
                            if avatarUrl.starts(with: "data:image") {
                                // Handle Base64 image
                                if let uiImage = loadBase64Image(avatarUrl) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
                                        .accessibility(label: Text("Profile photo"))
                                } else {
                                    fallbackProfileImage
                                }
                            } else {
                                // Handle remote URL image
                                AsyncImage(url: URL(string: avatarUrl)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 100, height: 100)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
                                    case .failure:
                                        fallbackProfileImage
                                    @unknown default:
                                        fallbackProfileImage
                                    }
                                }
                                .accessibility(label: Text("Profile photo"))
                            }
                        } else {
                            fallbackProfileImage
                        }
                        
                        if isEditing {
                            Button(action: { showingImagePicker = true }) {
                                Text("Change Photo")
                                    .font(.subheadline)
                                    .foregroundColor(.accentColor)
                            }
                            .accessibilityLabel("Change profile photo")
                        }
                    }
                    .padding(.vertical, 8)
                    Spacer()
                }
            }
            
            // Personal Information Section
            Section {
                if isEditing {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("Enter your full name", text: .init(
                            get: { profile.fullName },
                            set: { newValue in
                                var updatedProfile = profile
                                updatedProfile.fullName = newValue
                                self.profile = updatedProfile
                            }
                        ))
                        .textContentType(.name)
                    }
                    
                    // Date of Birth - read only in edit mode
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date of Birth")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(profile.dateOfBirth)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                    
                    // Email - read only in edit mode
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(profile.email)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                } else {
                    ProfileInfoRow(title: "Full Name", value: profile.fullName)
                    ProfileInfoRow(title: "Date of Birth", value: profile.dateOfBirth)
                    ProfileInfoRow(title: "Email", value: profile.email)
                }
            } header: {
                Text("Personal Information")
                    .textCase(.none)
            } footer: {
                if isEditing {
                    Text("Only your full name can be changed")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            
            // Preferences Section
            Section {
                NavigationLink(destination: NotificationsView()) {
                    Label {
                        Text("Notifications")
                    } icon: {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.accentColor)
                    }
                }
            } header: {
                Text("Preferences")
                    .textCase(.none)
            }
            
            // Logout Section
            Section {
                Button(action: {
                    showingLogoutAlert = true
                }) {
                    HStack {
                        Spacer()
                        Text("Log Out")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if isEditing {
                        // Save profile changes
                        saveProfile()
                    }
                    withAnimation {
                        isEditing.toggle()
                    }
                } label: {
                    Text(isEditing ? "Done" : "Edit")
                }
                .accessibilityLabel(isEditing ? "Done editing profile" : "Edit profile")
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            // Image picker implementation
            PhotosPicker(selection: $imageSelection, matching: .images) {
                Text("Select a photo")
            }
        }
        .onChange(of: imageSelection) { item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        profileImage = uiImage
                        // Upload new profile image
                        uploadProfileImage(uiImage)
                    }
                }
            }
        }
        .alert("Logout", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                // Clear authentication state
                adminIsLoggedIn = false
                adminEmail = ""
                // Reset app state to go back to the first screen
                appState.resetToFirstScreen()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
    
    private var fallbackProfileImage: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 100, height: 100)
            .foregroundColor(.accentColor)
            .accessibilityLabel("Profile photo")
    }
    
    private func loadProfile() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // First get the admin ID from the email
                let dataController = SupabaseDataController()
                let (exists, adminId, _) = try await dataController.verifyAdminEmail(email: adminEmail)
                
                guard exists, let adminId = adminId else {
                    throw NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "Admin account not found"])
                }
                
                // Then fetch the full profile
                let admin = try await AdminService.shared.fetchAdminProfile(adminId: adminId)
                
                // Convert to the view model
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .none
                
                let dateOfBirth: String
                if let dobString = admin.date_of_birth {
                    let isoFormatter = ISO8601DateFormatter()
                    if let date = isoFormatter.date(from: dobString) {
                        dateOfBirth = dateFormatter.string(from: date)
                    } else {
                        dateOfBirth = dobString
                    }
                } else {
                    dateOfBirth = "Not set"
                }
                
                let viewModel = AdminProfile(
                    id: admin.id,
                    fullName: admin.name ?? "Not set",
                    dateOfBirth: dateOfBirth,
                    email: admin.email,
                    avatarUrl: admin.avatar_url
                )
                
                await MainActor.run {
                    self.profile = viewModel
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func saveProfile() {
        guard let profile = profile else { return }
        
        Task {
            do {
                try await AdminService.shared.updateAdminName(
                    adminId: profile.id,
                    name: profile.fullName,
                    avatarUrl: profile.avatarUrl
                )
                
                // Refresh the profile
                loadProfile()
            } catch {
                print("Failed to save profile: \(error.localizedDescription)")
                // Show error message
            }
        }
    }
    
    private func uploadProfileImage(_ image: UIImage) {
        guard let profile = profile else { return }
        
        Task {
            do {
                // Resize image to a moderate size for avatars
                let resizedImage = resizeImage(image: image, targetSize: CGSize(width: 300, height: 300))
                
                // Convert UIImage to JPG data with improved compression for better quality
                guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
                    throw NSError(domain: "Image processing failed", code: 1001)
                }
                
                // Generate a unique filename with admin ID and timestamp
                let timestamp = Int(Date().timeIntervalSince1970)
                let filename = "\(profile.id)_\(timestamp).jpg"
                
                // Upload to Supabase storage or get Base64 data URI
                let avatarUrl = try await StorageService.shared.uploadAdminAvatar(
                    data: imageData,
                    filename: filename
                )
                
                // Update the profile with the new avatar URL
                var updatedProfile = profile
                updatedProfile.avatarUrl = avatarUrl
                
                await MainActor.run {
                    self.profile = updatedProfile
                }
                
                // Save the profile with the new avatar URL
                try await AdminService.shared.updateAdminName(
                    adminId: profile.id,
                    name: profile.fullName,
                    avatarUrl: avatarUrl
                )
            } catch {
                print("Failed to upload profile image: \(error.localizedDescription)")
                // Show error message
            }
        }
    }
    
    // Helper function to load a Base64 encoded image
    private func loadBase64Image(_ base64String: String) -> UIImage? {
        guard let dataUriComponents = base64String.components(separatedBy: ",").last,
              let imageData = Data(base64Encoded: dataUriComponents) else {
            return nil
        }
        return UIImage(data: imageData)
    }
    
    // Helper method to resize images
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}

struct ProfileInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

struct NotificationsView: View {
    var body: some View {
        List {
            Section {
                Toggle("Push Notifications", isOn: .constant(true))
                Toggle("Email Notifications", isOn: .constant(true))
            }
            
            Section {
                Toggle("New Books", isOn: .constant(true))
                Toggle("Due Date Reminders", isOn: .constant(true))
                Toggle("System Updates", isOn: .constant(true))
            } header: {
                Text("Notification Types")
            } footer: {
                Text("Choose which notifications you'd like to receive")
            }
        }
        .navigationTitle("Notifications")
    }
}

//struct SupportView: View {
//    @State private var subject = ""
//    @State private var message = ""
//    
//    var body: some View {
//        Form {
//            Section {
//                TextField("Subject", text: $subject)
//                TextEditor(text: $message)
//                    .frame(height: 100)
//            } header: {
//                Text("Message")
//            }
//            
//            Section {
//                Button("Send Message") {
//                    // Handle sending support message
//                }
//            }
//            
//            Section {
//                Link(destination: URL(string: "tel:+1234567890")!) {
//                    Label("Call Support", systemImage: "phone.fill")
//                }
//                Link(destination: URL(string: "mailto:support@samplelms.com")!) {
//                    Label("Email Support", systemImage: "envelope.fill")
//                }
//            } header: {
//                Text("Other Ways to Contact Us")
//            }
//        }
//        .navigationTitle("Contact Support")
//    }
//}

// MARK: - Admin Service Extension
extension AdminService {
    func updateAdminName(adminId: String, name: String, avatarUrl: String?) async throws {
        // Update only the admin name in Supabase
        do {
            let dataController = SupabaseDataController()
            
            // Create an encodable struct for the update data
            struct AdminNameUpdate: Encodable {
                let name: String
                let avatar_url: String?
            }
            
            // Create the update data using the struct
            let updateData = AdminNameUpdate(
                name: name,
                avatar_url: avatarUrl
            )
            
            // Update the admin record
            try await dataController.client.from("Admin")
                .update(updateData)
                .eq("id", value: adminId)
                .execute()
            
        } catch {
            print("Failed to update admin name: \(error.localizedDescription)")
            throw error
        }
    }
}

#Preview {
    AdminProfileView()
} 
