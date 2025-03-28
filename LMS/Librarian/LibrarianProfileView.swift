import SwiftUI
import Supabase

struct LibrarianProfile: Codable {
    var fullName: String
    var dateOfBirth: String
    var email: String
}

struct LibrarianProfileView: View {
    @State private var profile = LibrarianProfile(
        fullName: "Jane Smith",
        dateOfBirth: "15 Apr 1990",
        email: "jane.smith@example.com"
    )
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var showingImagePicker = false
    @AppStorage("librarianIsLoggedIn") private var librarianIsLoggedIn = true
    @AppStorage("librarianEmail") private var librarianEmail = ""
    @State private var showingLogoutAlert = false
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        NavigationView {
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Done" : "Edit") {
                        withAnimation {
                            isEditing.toggle()
                        }
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
                    librarianIsLoggedIn = false
                    librarianEmail = ""
                    // Reset app state to go back to the first screen
                    appState.resetToFirstScreen()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
    }
}

#Preview {
    LibrarianProfileView()
} 
