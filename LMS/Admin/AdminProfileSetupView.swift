import SwiftUI

struct AdminProfileSetupView: View {
    @State private var fullName = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var department = ""
    @State private var position = ""
    @State private var bio = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var showAdminOnboarding = false
    @Environment(\.dismiss) private var dismiss
    
    private var isValid: Bool {
        !fullName.isEmpty &&
        !email.isEmpty &&
        email.contains("@") &&
        email.contains(".") &&
        !phoneNumber.isEmpty &&
        !department.isEmpty &&
        !position.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)
                        
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
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.purple)
                                Text("Email Address")
                                    .font(.headline)
                            }
                            .foregroundColor(.secondary)
                            
                            TextField("Enter your email", text: $email)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        // Phone Number Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.purple)
                                Text("Phone Number")
                                    .font(.headline)
                            }
                            .foregroundColor(.secondary)
                            
                            TextField("Enter your phone number", text: $phoneNumber)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .keyboardType(.phonePad)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        // Department Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "building.2.fill")
                                    .foregroundColor(.purple)
                                Text("Department")
                                    .font(.headline)
                            }
                            .foregroundColor(.secondary)
                            
                            TextField("Enter your department", text: $department)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        // Position Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "briefcase.fill")
                                    .foregroundColor(.purple)
                                Text("Position")
                                    .font(.headline)
                            }
                            .foregroundColor(.secondary)
                            
                            TextField("Enter your position", text: $position)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        // Bio Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "text.quote")
                                    .foregroundColor(.purple)
                                Text("Bio")
                                    .font(.headline)
                            }
                            .foregroundColor(.secondary)
                            
                            TextEditor(text: $bio)
                                .frame(height: 100)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                                )
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
                                gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
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
            .fullScreenCover(isPresented: $showAdminOnboarding) {
                AdminOnboardingView()
            }
        }
    }
    
    private func saveProfileAndContinue() {
        isLoading = true
        
        // Here you would typically save the profile data to your backend
        // For now, we'll just simulate a delay and then proceed
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            showAdminOnboarding = true
        }
    }
}

#Preview {
    AdminProfileSetupView()
} 