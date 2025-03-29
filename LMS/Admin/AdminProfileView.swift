import SwiftUI
import Supabase

struct AdminProfile: Codable {
    var fullName: String
    var dateOfBirth: String
    var email: String
}

struct AdminProfileView: View {
    @State private var profile = AdminProfile(
        fullName: "John Doe",
        dateOfBirth: "20 Mar 2025",
        email: "john.doe@example.com"
    )
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var showingImagePicker = false
    @AppStorage("adminIsLoggedIn") private var adminIsLoggedIn = true
    @AppStorage("adminEmail") private var adminEmail = ""
    @State private var showingLogoutAlert = false
    @State private var shouldDismissToRoot = false
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        List {
            // Profile Photo Section
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(.accentColor)
                            .accessibilityLabel("Profile photo")
                        
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
                            set: { profile.fullName = $0 }
                        ))
                        .textContentType(.name)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date of Birth")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("Enter date of birth", text: .init(
                            get: { profile.dateOfBirth },
                            set: { profile.dateOfBirth = $0 }
                        ))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("Enter your email", text: .init(
                            get: { profile.email },
                            set: { profile.email = $0 }
                        ))
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
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
                    Text("Your information will be used to personalize your experience")
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
            // Image picker implementation would go here
            Text("Image Picker")
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

#Preview {
    AdminProfileView()
} 
