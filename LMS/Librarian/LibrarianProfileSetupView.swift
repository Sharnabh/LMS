import SwiftUI
import PhotosUI
import Supabase

struct LibrarianProfileSetupView: View {
    let librarianId: String
    let onComplete: () -> Void
    
    // Public initializer
    init(librarianId: String, onComplete: @escaping () -> Void) {
        self.librarianId = librarianId
        self.onComplete = onComplete
    }
    
    @State private var fullName = ""
    @State private var email = ""
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date())!
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var showLibrarianOnboarding = false
    @State private var showDatePicker = false
    @State private var profileImage: UIImage?
    @State private var showImagePicker = false
    @State private var imageSelection: PhotosPickerItem?
    @State private var isUploading = false
    @Environment(\.dismiss) private var dismiss
    
    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    private var isValid: Bool {
        // Check for empty name
        guard !fullName.isEmpty else { return false }
        
        // Verify age requirement (at least 21 years old)
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        guard let age = ageComponents.year, age >= 21 else { return false }
        
        return true
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 16) {
                        // Profile Image Selector
                        ZStack {
                            if let profileImage = profileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                            } else {
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Image(systemName: "person.crop.circle.fill")
                                            .font(.system(size: 60))
                                            .foregroundColor(.blue)
                                    )
                            }
                            
                            PhotosPicker(selection: $imageSelection, matching: .images) {
                                Circle()
                                    .fill(Color.black.opacity(0.3))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .position(x: 95, y: 95)
                        }
                        .padding(.bottom, 8)
                        
                        Text("Complete Your Profile")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Please provide your details to complete the setup")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Form Fields
                    VStack(spacing: 25) {
                        // Full Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.blue)
                                Text("Full Name")
                                    .font(.headline)
                            }
                            .foregroundColor(.secondary)
                            
                            TextField("Enter your full name", text: $fullName)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        // Date of Birth Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                Text("Date of Birth")
                                    .font(.headline)
                            }
                            .foregroundColor(.secondary)
                            
                            Button(action: {
                                showDatePicker = true
                            }) {
                                HStack {
                                    Text(dateFormatter.string(from: dateOfBirth))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Next Button
                    Button(action: {
                        saveProfileAndContinue()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "arrow.right.circle.fill")
                                Text("Next")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    isValid ? Color.blue : Color.blue.opacity(0.3),
                                    isValid ? Color.blue.opacity(0.8) : Color.blue.opacity(0.2)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .disabled(isLoading || !isValid)
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                    
                    // Validation message
                    if !isValid {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            if fullName.isEmpty {
                                Text("Please enter your full name")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            } else {
                                Text("You must be at least 21 years old")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    } else {
                        // Empty spacer to maintain layout when no message is shown
                        Spacer().frame(height: 25)
                    }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Notification"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showDatePicker) {
                NavigationView {
                    VStack {
                        DatePicker(
                            "Select your date of birth",
                            selection: $dateOfBirth,
                            in: ...Calendar.current.date(byAdding: .year, value: -21, to: Date())!,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .padding()
                        
                        Spacer()
                    }
                    .navigationTitle("Date of Birth")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showDatePicker = false
                            }
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showLibrarianOnboarding) {
                LibrarianOnboardingView(onComplete: onComplete)
            }
            .onChange(of: imageSelection) { item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        profileImage = uiImage
                    }
                }
            }
        }
    }
    
    private func saveProfileAndContinue() {
        // Validation is now handled by isValid property and button disabling
        isLoading = true
        
        Task {
            do {
                var avatarUrl: String? = nil
                
                // Upload image if one is selected
                if let profileImage = profileImage {
                    // Resize image to a moderate size for avatars - increased from 150x150 for better quality
                    let resizedImage = resizeImage(image: profileImage, targetSize: CGSize(width: 300, height: 300))
                    
                    // Convert UIImage to JPG data with improved compression for better quality
                    guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
                        throw NSError(domain: "Image processing failed", code: 1001)
                    }
                    
                    // Check file size
                    let fileSizeInKB = Double(imageData.count) / 1000.0
                    print("File size after compression: \(fileSizeInKB) KB")
                    
                    // Generate a unique filename with librarian ID and timestamp
                    let timestamp = Int(Date().timeIntervalSince1970)
                    let filename = "\(librarianId)_\(timestamp).jpg"
                    
                    // Upload to Supabase storage or get Base64 data URI
                    avatarUrl = try await LibrarianStorageService.shared.uploadLibrarianAvatar(
                        data: imageData,
                        filename: filename
                    )
                }
                
                // Update librarian profile with all information including avatar URL
                try await LibrarianService.shared.updateLibrarianProfile(
                    librarianId: librarianId,
                    name: fullName,
                    dateOfBirth: dateOfBirth,
                    avatarUrl: avatarUrl
                )
                
                await MainActor.run {
                    isLoading = false
                    showLibrarianOnboarding = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Failed to save profile: \(error.localizedDescription)"
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

// MARK: - Storage Service
class LibrarianStorageService {
    static let shared = LibrarianStorageService()
    
    private init() {}
    
    func uploadLibrarianAvatar(data: Data, filename: String) async throws -> String {
        // Upload the image to Supabase storage
        do {
            let dataController = SupabaseDataController()
            
            // Log file size
            let fileSizeInKB = Double(data.count) / 1000.0
            print("Attempting to upload file: \(filename), Size: \(fileSizeInKB) KB")
            
            // Check if bucket exists first - if not, we'll need to create it
            // This is just for diagnostic purposes
            let buckets = try await dataController.client.storage.listBuckets()
            let bucketExists = buckets.contains { $0.name == "librarianavatar" }
            print("Bucket 'librarianavatar' exists: \(bucketExists)")
            
            if !bucketExists {
                print("Bucket does not exist. Will attempt to use default bucket instead.")
            }
            
            // Set proper file options with upsert enabled to allow overwriting existing files
            let fileOptions = FileOptions(
                cacheControl: "3600",
                contentType: "image/jpeg",
                upsert: true
            )
            
            // For files over 10MB, we might need chunked upload or other approaches
            // But for profile images, this approach should work fine
            let fileSizeMB = Double(data.count) / 1_000_000.0
            if fileSizeMB > 10 {
                print("Warning: File size (\(fileSizeMB) MB) is large for an avatar image")
            }
            
            // Try direct base64 encoding approach first since we know the bucket has RLS issues
            print("Using Base64 encoding approach for small avatar image")
            
            // For Base64 encoding, we may want to reduce size further if it's very large
            // since Base64 increases size by ~33% and is stored directly in the database
            let maxBase64SizeKB = 500.0 // 500KB max for base64 encoded images
            var dataForBase64 = data
            var compressionQuality = 0.7
            
            // If the image is too large for comfortable Base64 storage, compress further
            while Double(dataForBase64.count) / 1000.0 > maxBase64SizeKB && compressionQuality > 0.1 {
                compressionQuality -= 0.1
                if let uiImage = UIImage(data: data),
                   let compressedData = uiImage.jpegData(compressionQuality: compressionQuality) {
                    dataForBase64 = compressedData
                    print("Reduced Base64 image to \(Double(dataForBase64.count) / 1000.0) KB with quality \(compressionQuality)")
                } else {
                    break
                }
            }
            
            let base64String = dataForBase64.base64EncodedString()
            let dataUri = "data:image/jpeg;base64," + base64String
            
            // For diagnostics, still try to upload to see the specific error
            do {
                try await dataController.client.storage
                    .from("librarianavatar")
                    .upload(path: filename, file: data, options: fileOptions)
                
                print("Upload successful - unexpected success!")
                
                // Create a direct URL to the image
                let baseUrl = "https://iswzgemgctojcdnbxvjv.supabase.co/storage/v1/object/public/librarianavatar/"
                let encodedFilename = filename.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? filename
                let publicUrl = baseUrl + encodedFilename
                
                print("Generated URL: \(publicUrl)")
                return publicUrl
            } catch {
                // Log the specific error for debugging
                print("Storage upload failed (expected): \(error.localizedDescription)")
                if let nsError = error as NSError? {
                    print("Error domain: \(nsError.domain), code: \(nsError.code)")
                    print("Error user info: \(nsError.userInfo)")
                }
                
                // Return the Base64 data URI since the upload failed
                print("Using Base64 encoded data URI as fallback")
                return dataUri
            }
        } catch {
            print("Failed to upload image: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("Error domain: \(nsError.domain), code: \(nsError.code)")
                print("Error user info: \(nsError.userInfo)")
            }
            
            // If we get an error about the bucket not existing, return a special error string
            if error.localizedDescription.contains("bucket") || 
               error.localizedDescription.contains("not exist") || 
               error.localizedDescription.contains("librarianavatar") {
                // Instead of trying to set alertMessage and showAlert directly,
                // return a special value that the calling code can handle
                return "ERROR_BUCKET_NOT_FOUND"
            }
            
            throw error
        }
    }
}

// MARK: - Librarian Service
class LibrarianService {
    static let shared = LibrarianService()
    
    private init() {}
    
    func fetchLibrarianProfile(librarianId: String) async throws -> LibrarianModel {
        // Fetch librarian profile from Supabase
        do {
            let dataController = SupabaseDataController()
            
            let response: [LibrarianModel] = try await dataController.client.from("Librarian")
                .select()
                .eq("id", value: librarianId)
                .execute()
                .value
            
            guard let librarianModel = response.first else {
                throw NSError(domain: "LibrarianService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Librarian not found"])
            }
            
            return librarianModel
        } catch {
            print("Failed to fetch librarian profile: \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateLibrarianProfile(librarianId: String, name: String, dateOfBirth: Date, avatarUrl: String?) async throws {
        // Update librarian profile in Supabase
        do {
            let dataController = SupabaseDataController()
            
            // Format the date for Supabase
            let dateFormatter = ISO8601DateFormatter()
            let formattedDate = dateFormatter.string(from: dateOfBirth)
            
            // Create an encodable struct for the update data
            struct LibrarianUpdateData: Encodable {
                let username: String
                let date_of_birth: String
                let isFirstLogin: Bool
                let avatar_url: String?
            }
            
            // Create the update data using the struct
            let updateData = LibrarianUpdateData(
                username: name,
                date_of_birth: formattedDate,
                isFirstLogin: false,
                avatar_url: avatarUrl
            )
            
            // Update the librarian record
            try await dataController.client.from("Librarian")
                .update(updateData)
                .eq("id", value: librarianId)
                .execute()
            
        } catch {
            print("Failed to update librarian profile: \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: - Librarian Onboarding View
struct LibrarianOnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0
    let totalPages = 3
    
    var body: some View {
        ZStack {
            // Background color
            Color(.systemBackground).edgesIgnoringSafeArea(.all)
            
            // Onboarding pages
            TabView(selection: $currentPage) {
                // Page 1: Welcome
                VStack(spacing: 20) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        .padding(.bottom, 20)
                    
                    Text("Welcome to the Librarian Dashboard")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Manage your library efficiently with our comprehensive tools.")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
                }
                .tag(0)
                
                // Page 2: Features
                VStack(spacing: 30) {
                    Image(systemName: "list.bullet.clipboard.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.blue)
                        .padding(.bottom, 20)
                    
                    Text("Powerful Library Management")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        FeatureRow(icon: "book.fill", title: "Catalog Books", description: "Add, update and organize your book collection")
                        FeatureRow(icon: "person.crop.circle.badge.checkmark", title: "Manage Checkouts", description: "Track all library transactions in one place")
                        FeatureRow(icon: "chart.bar.xaxis", title: "Analytics", description: "Get insights on library usage patterns")
                    }
                    .padding(.horizontal, 30)
                }
                .tag(1)
                
                // Page 3: Get Started
                VStack(spacing: 25) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                        .padding(.bottom, 20)
                    
                    Text("You're All Set!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Your account is now ready. Tap the button below to start using the librarian portal.")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
                    
                    Button(action: {
                        onComplete()
                    }) {
                        Text("Start Using Pustakalaya")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(12)
                            .padding(.horizontal, 40)
                    }
                }
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            
            // Navigation buttons
            VStack {
                Spacer()
                
                HStack {
                    // Back button
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation {
                                currentPage -= 1
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                        }
                    } else {
                        Spacer()
                    }
                    
                    Spacer()
                    
                    // Next/Get Started button
                    if currentPage < totalPages - 1 {
                        Button(action: {
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text("Next")
                                Image(systemName: "chevron.right")
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                        }
                    } else {
                        Button(action: {
                            onComplete()
                        }) {
                            Text("Get Started")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            }
        }
    }
}

// Feature row component for onboarding
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    LibrarianProfileSetupView(librarianId: "preview_librarian_id", onComplete: {})
} 