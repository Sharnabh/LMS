import SwiftUI
import Supabase
import PhotosUI

struct LibrarianProfile: Codable {
    var fullName: String
    var dateOfBirth: String
    var email: String
}

struct LibrarianProfileView: View {
    @State private var fullName = ""
    @State private var dateOfBirth = ""
    @State private var email = ""
    @State private var avatarUrl: String?
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var showingImagePicker = false
    @AppStorage("librarianIsLoggedIn") private var librarianIsLoggedIn = true
    @AppStorage("librarianEmail") private var librarianEmail = ""
    @State private var showingLogoutAlert = false
    @EnvironmentObject private var appState: AppState
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertTitle = "Error"
    @State private var alertMessage = ""
    @State private var profileImage: UIImage?
    @State private var imageSelection: PhotosPickerItem?
    
    var body: some View {
            List {
                // Profile Photo Section
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            if let profileImage = profileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
                            } else if let avatarUrl = avatarUrl, avatarUrl.starts(with: "data:image") {
                                // Handle base64 data URI
                                if let imageData = extractBase64Data(from: avatarUrl),
                                   let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
                                } else {
                                    // Fallback if we can't load the base64 image
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.accentColor)
                                        
                                }
                            } else if let avatarUrl = avatarUrl, !avatarUrl.isEmpty {
                                // Handle remote URL
                                AsyncImage(url: URL(string: avatarUrl)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 100, height: 100)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                                    case .failure:
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 100, height: 100)
                                            .foregroundColor(.accentColor)
                                    @unknown default:
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 100, height: 100)
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            } else {
                                // Default image if no avatar URL
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.accentColor)
                            }
                            
                            if isEditing {
                                PhotosPicker(selection: $imageSelection, matching: .images) {
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
                            TextField("Enter your full name", text: $fullName)
                                .textContentType(.name)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        // Non-editable fields (display only)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date of Birth")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(dateOfBirth)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(email)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                    } else {
                        ProfileInfoRow(title: "Full Name", value: fullName)
                        ProfileInfoRow(title: "Date of Birth", value: dateOfBirth)
                        ProfileInfoRow(title: "Email", value: email)
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
                    NavigationLink(destination: LibrarianPoliciesView()) {
                        Label {
                            Text("Library Policies")
                        } icon: {
                            Image(systemName: "doc.text.fill")
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        handleDoneButtonTap()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text(isEditing ? "Done" : "Edit")
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .onChange(of: imageSelection) { oldItem, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        profileImage = uiImage
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert("Logout", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    // Clear authentication state
                    librarianIsLoggedIn = false
                    librarianEmail = ""
                    // Reset app state to go back to the first screen
                    appState.resetToFirstScreen()
                    appState.showLibrarianApp = false
                    // Need to clear the currentLibrarianID from UserDefaults
                    UserDefaults.standard.removeObject(forKey: "currentLibrarianID")
                    UserDefaults.standard.removeObject(forKey: "currentLibrarianEmail")
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
            .onAppear {
                fetchLibrarianProfile()
            }
        }
    
    // Extract base64 data from a data URI
    private func extractBase64Data(from dataURI: String) -> Data? {
        guard dataURI.starts(with: "data:image") else { return nil }
        
        let components = dataURI.components(separatedBy: ",")
        guard components.count > 1, let base64String = components.last else { return nil }
        
        return Data(base64Encoded: base64String)
    }
    
    // Fetch librarian profile
    private func fetchLibrarianProfile() {
        guard let librarianId = UserDefaults.standard.string(forKey: "currentLibrarianID") else {
            alertTitle = "Error"
            alertMessage = "Librarian ID not found"
            showAlert = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let librarianModel = try await LibrarianService.shared.fetchLibrarianProfile(librarianId: librarianId)
                
                // Debug: Print all properties to see what we're working with
                let mirror = Mirror(reflecting: librarianModel)
                print("Librarian model properties:")
                for (label, value) in mirror.children {
                    print("Property: \(label ?? "unknown"), Value: \(value), Type: \(type(of: value))")
                }
                
                await MainActor.run {
                    // Update UI with fetched data
                    fullName = librarianModel.username
                    email = librarianModel.email
                    
                    // Format date of birth if available
                    if let dobString = librarianModel.date_of_birth {
                        print("Raw date of birth from model: \(dobString)")
                        dateOfBirth = formatDateString(dobString)
                        print("Formatted date of birth: \(dateOfBirth)")
                    } else {
                        print("Date of birth is nil in the model")
                        dateOfBirth = "Not set"
                    }
                    
                    // Set avatar URL if available
                    if let url = librarianModel.avatar_url {
                        if url.starts(with: "data:image") {
                            // It's a base64 data URI
                            avatarUrl = url
                        } else if !url.isEmpty && !url.starts(with: "http") {
                            // It's a relative path, add the base URL
                            avatarUrl = "https://iswzgemgctojcdnbxvjv.supabase.co/storage/v1/object/public/librarianavatar/\(url)"
                        } else {
                            // It's already a full URL
                            avatarUrl = url
                        }
                        print("Avatar URL set to: \(avatarUrl ?? "nil")")
                    } else {
                        print("Avatar URL is nil in the model")
                        avatarUrl = nil
                    }
                    
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertTitle = "Error"
                    alertMessage = "Failed to load profile: \(error.localizedDescription)"
                    showAlert = true
                    print("Error fetching profile: \(error)")
                }
            }
        }
    }
    
    // Helper function to format any date value
    private func formatDateValue(_ value: Any) -> String {
        // If it's already a string, try to parse it
        if let dateString = value as? String {
            return formatDateString(dateString)
        }
        
        // If it's a Date object
        if let date = value as? Date {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
        
        // If it's a TimeInterval (timestamp)
        if let timeInterval = value as? TimeInterval {
            let date = Date(timeIntervalSince1970: timeInterval)
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
        
        // If it's a dictionary with a timestamp
        if let dict = value as? [String: Any], let timestamp = dict["$date"] as? TimeInterval {
            let date = Date(timeIntervalSince1970: timestamp / 1000) // Convert from milliseconds
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
        
        // If all else fails, return a string representation
        return "\(value)"
    }
    
    // Format ISO date string to a more readable format
    private func formatDateString(_ isoString: String) -> String {
        // First try ISO8601 with timezone
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        
        if let date = isoFormatter.date(from: isoString) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
        
        // If that fails, try with different format options
        isoFormatter.formatOptions = [.withFullDate, .withFullTime, .withTimeZone]
        if let date = isoFormatter.date(from: isoString) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
        
        // If ISO8601 fails, try standard date formatter with timestamp format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let date = dateFormatter.date(from: isoString) {
            dateFormatter.dateFormat = "MMM d, yyyy"
            return dateFormatter.string(from: date)
        }
        
        // If all else fails, return the original string
        return isoString
    }
    
    // Handle Done button tap
    private func handleDoneButtonTap() {
        if isEditing {
            // If we're in edit mode, save changes
            updateProfile()
        } else {
            // If we're in view mode, enter edit mode
            withAnimation {
                isEditing = true
            }
        }
    }
    
    // Cancel edit mode and reset changes
    private func cancelEditMode() {
        withAnimation {
            isEditing = false
            // Reset any changes
            fetchLibrarianProfile()
        }
    }
    
    // Update profile
    private func updateProfile() {
        guard let librarianId = UserDefaults.standard.string(forKey: "currentLibrarianID") else {
            alertTitle = "Error"
            alertMessage = "Librarian ID not found"
            showAlert = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                var avatarUrlToUpdate: String? = avatarUrl
                
                // Upload new image if selected
                if let profileImage = profileImage {
                    let resizedImage = resizeImage(image: profileImage, targetSize: CGSize(width: 300, height: 300))
                    
                    guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
                        throw NSError(domain: "Image processing failed", code: 1001)
                    }
                    
                    let timestamp = Int(Date().timeIntervalSince1970)
                    let filename = "\(librarianId)_\(timestamp).jpg"
                    
                    avatarUrlToUpdate = try await LibrarianStorageService.shared.uploadLibrarianAvatar(
                        data: imageData,
                        filename: filename
                    )
                }
                
                // Create an encodable struct for the update data
                struct LibrarianProfileUpdate: Encodable {
                    let username: String
                    let avatar_url: String?
                }
                
                // Create the update data
                let updateData = LibrarianProfileUpdate(
                    username: fullName,
                    avatar_url: avatarUrlToUpdate
                )
                
                // Update profile
                let dataController = SupabaseDataController()
                try await dataController.client.from("Librarian")
                    .update(updateData)
                    .eq("id", value: librarianId)
                    .execute()
                
                await MainActor.run {
                    isLoading = false
                    isEditing = false
                    alertTitle = "Success"
                    alertMessage = "Profile updated successfully"
                    showAlert = true
                    
                    // Refresh profile data
                    fetchLibrarianProfile()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertTitle = "Error"
                    alertMessage = "Failed to update profile: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
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
        HStack(alignment: .top) {
            Text(title)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }
}

struct NotificationsView: View {
    var body: some View {
        Text("Notifications settings would go here")
            .navigationTitle("Notifications")
    }
}

struct LibrarianPoliciesView: View {
    @StateObject private var policiesViewModel = LibrarianPoliciesViewModel()
    @StateObject private var timingsViewModel = LibrarianTimingsViewModel()
    
    var body: some View {
        List {
            Section(header: Text("Borrowing Rules").font(.headline)) {
                if policiesViewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                } else if let errorMessage = policiesViewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    HStack {
                        Text("Borrowing Limit")
                        Spacer()
                        Text("\(policiesViewModel.borrowingLimit) books")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    HStack {
                        Text("Return Period")
                        Spacer()
                        Text("\(policiesViewModel.returnPeriod) days")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    HStack {
                        Text("Late Fine (per day)")
                        Spacer()
                        Text("₹\(policiesViewModel.fineAmount)")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    HStack {
                        Text("Lost Book Fine")
                        Spacer()
                        Text("₹\(policiesViewModel.lostBookFine)")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Section(header: Text("Library Timings").font(.headline)) {
                if timingsViewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                } else if let error = timingsViewModel.error {
                    Text("Error: \(error.localizedDescription)")
                        .foregroundColor(.red)
                        .padding()
                } else if let timings = timingsViewModel.libraryTimings {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Monday - Saturday")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Text("Opening Time")
                            Spacer()
                            Text(timings.weekdayOpeningTime, style: .time)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        
                        HStack {
                            Text("Closing Time")
                            Spacer()
                            Text(timings.weekdayClosingTime, style: .time)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sunday")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        HStack {
                            Text("Opening Time")
                            Spacer()
                            Text(timings.sundayOpeningTime, style: .time)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        
                        HStack {
                            Text("Closing Time")
                            Spacer()
                            Text(timings.sundayClosingTime, style: .time)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Library Policies")
        .onAppear {
            Task {
                await policiesViewModel.fetchPolicies()
                await timingsViewModel.fetchLibraryTimings()
            }
        }
    }
}

// View model for policies
class LibrarianPoliciesViewModel: ObservableObject {
    @Published var borrowingLimit: Int = 4
    @Published var returnPeriod: Int = 14
    @Published var fineAmount: Int = 10
    @Published var lostBookFine: Int = 500
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var dataController = SupabaseDataController()
    
    func fetchPolicies() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            let policies = try await dataController.fetchLibraryPolicies()
            
            await MainActor.run {
                self.borrowingLimit = policies.borrowingLimit
                self.returnPeriod = policies.returnPeriod
                self.fineAmount = policies.fineAmount
                self.lostBookFine = policies.lostBookFine
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load policies: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

// View model for library timings
class LibrarianTimingsViewModel: ObservableObject {
    @Published var libraryTimings: LibraryTiming?
    @Published var isLoading = false
    @Published var error: Error?
    private var dataController = SupabaseDataController()
    
    func fetchLibraryTimings() async {
        await MainActor.run {
            self.isLoading = true
        }
        
        do {
            let query = dataController.client
                .from("library_timings")
                .select()
                .limit(1)
                .single()
            
            let response: LibraryTiming = try await query.execute().value
            await MainActor.run {
                self.libraryTimings = response
                self.isLoading = false
            }
        } catch {
            print("Error fetching library timings: \(error.localizedDescription)")
            
            // If no data exists yet, create default timings
            if self.libraryTimings == nil {
                // Create default timings object
                let defaultTimings = createDefaultTimings()
                await MainActor.run {
                    self.libraryTimings = defaultTimings
                    self.isLoading = false
                    self.error = nil
                }
            } else {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    private func createDefaultTimings() -> LibraryTiming {
        // Create default times
        let calendar = Calendar.current
        let defaultDate = calendar.startOfDay(for: Date())
        
        let weekdayOpeningTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: defaultDate)!
        let weekdayClosingTime = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: defaultDate)!
        let sundayOpeningTime = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: defaultDate)!
        let sundayClosingTime = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: defaultDate)!
        
        return LibraryTiming(
            id: UUID(),
            weekdayOpeningTime: weekdayOpeningTime,
            weekdayClosingTime: weekdayClosingTime,
            sundayOpeningTime: sundayOpeningTime,
            sundayClosingTime: sundayClosingTime,
            lastUpdated: Date()
        )
    }
}

#Preview {
    LibrarianProfileView()
} 
