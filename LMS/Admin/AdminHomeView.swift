import SwiftUI

struct AdminProfile: Codable {
    var firstName: String
    var lastName: String
    var dateOfBirth: String
    var gender: String
    var bloodGroup: String
}

struct AdminHomeView: View {
    @State private var profile = AdminProfile(
        firstName: "John",
        lastName: "Doe",
        dateOfBirth: "20 Mar 2025",
        gender: "Male",
        bloodGroup: "AB+"
    )
    @Environment(\.dismiss) private var dismiss
    @State private var showingLogoutAlert = false
    @State private var isEditing = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Spacer()
                        VStack {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .foregroundColor(.accentColor)
                            
                            if isEditing {
                                Text("Change Photo")
                                    .font(.footnote)
                                    .foregroundColor(.accentColor)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }
                
                Section {
                    if isEditing {
                        TextField("First Name", text: .init(
                            get: { profile.firstName },
                            set: { profile.firstName = $0 }
                        ))
                        TextField("Last Name", text: .init(
                            get: { profile.lastName },
                            set: { profile.lastName = $0 }
                        ))
                        TextField("Date of Birth", text: .init(
                            get: { profile.dateOfBirth },
                            set: { profile.dateOfBirth = $0 }
                        ))
                        Picker("Gender", selection: .init(
                            get: { profile.gender },
                            set: { profile.gender = $0 }
                        )) {
                            Text("Male").tag("Male")
                            Text("Female").tag("Female")
                            Text("Other").tag("Other")
                        }
                        TextField("Blood Group", text: .init(
                            get: { profile.bloodGroup },
                            set: { profile.bloodGroup = $0 }
                        ))
                    } else {
                        ProfileInfoRow(title: "First Name", value: profile.firstName)
                        ProfileInfoRow(title: "Last Name", value: profile.lastName)
                        ProfileInfoRow(title: "Date of Birth", value: profile.dateOfBirth)
                        ProfileInfoRow(title: "Gender", value: profile.gender)
                        ProfileInfoRow(title: "Blood Group", value: profile.bloodGroup)
                    }
                } header: {
                    Text("Personal Information")
                }
                
                Section {
                    NavigationLink(destination: NotificationsView()) {
                        HStack {
                            Label("Notifications", systemImage: "bell.fill")
                            Spacer()
                        }
                    }
                } header: {
                    Text("Preferences")
                }
                
                Section {
                    NavigationLink(destination: SupportView()) {
                        Label("Contact Support", systemImage: "questionmark.circle.fill")
                    }
                    
                    Link(destination: URL(string: "https://www.samplelms.com/help")!) {
                        Label("Help Center", systemImage: "book.fill")
                    }
                    
                    Link(destination: URL(string: "https://www.samplelms.com/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                } header: {
                    Text("Help & Support")
                }
                
                Section {
                    Button(role: .destructive) {
                        showingLogoutAlert = true
                    } label: {
                        Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
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
                }
            }
            .alert("Log Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    // Handle logout
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
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
        }
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

struct SupportView: View {
    @State private var subject = ""
    @State private var message = ""
    
    var body: some View {
        Form {
            Section {
                TextField("Subject", text: $subject)
                TextEditor(text: $message)
                    .frame(height: 100)
            } header: {
                Text("Message")
            }
            
            Section {
                Button("Send Message") {
                    // Handle sending support message
                }
            }
            
            Section {
                Link(destination: URL(string: "tel:+1234567890")!) {
                    Label("Call Support", systemImage: "phone.fill")
                }
                Link(destination: URL(string: "mailto:support@samplelms.com")!) {
                    Label("Email Support", systemImage: "envelope.fill")
                }
            } header: {
                Text("Other Ways to Contact Us")
            }
        }
        .navigationTitle("Contact Support")
    }
}

#Preview {
    AdminHomeView()
} 