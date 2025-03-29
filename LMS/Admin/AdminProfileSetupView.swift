import SwiftUI
import PhotosUI
import Supabase

struct AdminProfileSetupView: View {
    let adminId: String
    let onComplete: () -> Void
    
    // Public initializer
    init(adminId: String, onComplete: @escaping () -> Void) {
        self.adminId = adminId
        self.onComplete = onComplete
    }
    
    @State private var fullName = ""
    @State private var email = ""
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date())!
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var showAdminOnboarding = false
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
                                    .overlay(Circle().stroke(Color.purple, lineWidth: 3))
                            } else {
                                Circle()
                                    .fill(Color.purple.opacity(0.2))
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Image(systemName: "person.crop.circle.fill")
                                            .font(.system(size: 60))
                                            .foregroundColor(.purple)
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
                                    .foregroundColor(.purple)
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
                                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        // Email Field
//                        VStack(alignment: .leading, spacing: 8) {
//                            HStack {
//                                Image(systemName: "envelope.fill")
//                                    .foregroundColor(.purple)
//                                Text("Email Address")
//                                    .font(.headline)
//                            }
//                            .foregroundColor(.secondary)
//                            
//                            TextField("Enter your email", text: $email)
//                                .padding()
//                                .background(Color(.secondarySystemBackground))
//                                .cornerRadius(12)
//                                .keyboardType(.emailAddress)
//                                .autocapitalization(.none)
//                                .overlay(
//                                    RoundedRectangle(cornerRadius: 12)
//                                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
//                                )
//                        }
                        
                        // Date of Birth Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.purple)
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
                                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
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
                                    isValid ? Color.purple : Color.purple.opacity(0.3),
                                    isValid ? Color.purple.opacity(0.8) : Color.purple.opacity(0.2)
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
            .fullScreenCover(isPresented: $showAdminOnboarding) {
                AdminOnboardingView(onComplete: onComplete)
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
                    
                    // Generate a unique filename with admin ID and timestamp
                    let timestamp = Int(Date().timeIntervalSince1970)
                    let filename = "\(adminId)_\(timestamp).jpg"
                    
                    // Upload to Supabase storage or get Base64 data URI
                    avatarUrl = try await StorageService.shared.uploadAdminAvatar(
                        data: imageData,
                        filename: filename
                    )
                }
                
                // Update admin profile with all information including avatar URL
                try await AdminService.shared.updateAdminProfile(
                    adminId: adminId,
                    name: fullName,
                    dateOfBirth: dateOfBirth,
                    avatarUrl: avatarUrl
                )
                
                await MainActor.run {
                    isLoading = false
                    showAdminOnboarding = true
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
class StorageService {
    static let shared = StorageService()
    
    private init() {}
    
    func uploadAdminAvatar(data: Data, filename: String) async throws -> String {
        // Upload the image to Supabase storage
        do {
            let dataController = SupabaseDataController()
            
            // Log file size
            let fileSizeInKB = Double(data.count) / 1000.0
            print("Attempting to upload file: \(filename), Size: \(fileSizeInKB) KB")
            
            // Check if bucket exists first - if not, we'll need to create it
            // This is just for diagnostic purposes
            let buckets = try await dataController.client.storage.listBuckets()
            let bucketExists = buckets.contains { $0.name == "adminavatars" }
            print("Bucket 'adminavatars' exists: \(bucketExists)")
            
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
                    .from("adminavatars")
                    .upload(path: filename, file: data, options: fileOptions)
                
                print("Upload successful - unexpected success!")
                
                // Create a direct URL to the image
                let baseUrl = "https://iswzgemgctojcdnbxvjv.supabase.co/storage/v1/object/public/adminavatars/"
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
               error.localizedDescription.contains("adminavatars") {
                // Instead of trying to set alertMessage and showAlert directly,
                // return a special value that the calling code can handle
                return "ERROR_BUCKET_NOT_FOUND"
            }
            
            throw error
        }
    }
}

// MARK: - Admin Service
class AdminService {
    static let shared = AdminService()
    
    private init() {}
    
    func fetchAdminProfile(adminId: String) async throws -> Admin {
        // Fetch admin profile from Supabase
        do {
            let dataController = SupabaseDataController()
            
            let response: [AdminModel] = try await dataController.client.from("Admin")
                .select()
                .eq("id", value: adminId) // Removed column: label
                .execute()
                .value
            
            guard let adminModel = response.first else {
                throw NSError(domain: "AdminService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Admin not found"])
            }
            
            // Convert to app model
            let admin = Admin(
                id: adminModel.id,
                name: adminModel.name,
                email: adminModel.email,
                password: adminModel.password,
                is_first_login: adminModel.is_first_login,
                created_at: adminModel.created_at,
                avatar_url: adminModel.avatar_url,
                date_of_birth: adminModel.date_of_birth
            )
            
            return admin
        } catch {
            print("Failed to fetch admin profile: \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateAdminProfile(adminId: String, name: String, dateOfBirth: Date, avatarUrl: String?) async throws {
        // Update admin profile in Supabase
        do {
            let dataController = SupabaseDataController()
            
            // Format the date for Supabase
            let dateFormatter = ISO8601DateFormatter()
            let formattedDate = dateFormatter.string(from: dateOfBirth)
            
            // Create an encodable struct for the update data instead of [String: Any]
            struct AdminUpdateData: Encodable {
                let name: String
                let date_of_birth: String
                let is_first_login: Bool
                let avatar_url: String?
            }
            
            // Create the update data using the struct
            let updateData = AdminUpdateData(
                name: name,
                date_of_birth: formattedDate,
                is_first_login: false,
                avatar_url: avatarUrl
            )
            
            // Update the admin record
            try await dataController.client.from("Admin")
                .update(updateData)
                .eq("id", value: adminId) // Removed column: label
                .execute()
            
        } catch {
            print("Failed to update admin profile: \(error.localizedDescription)")
            throw error
        }
    }
}

#Preview {
    AdminProfileSetupView(adminId: "preview_admin_id", onComplete: {})
} 
