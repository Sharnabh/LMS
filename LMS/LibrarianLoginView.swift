import SwiftUI

struct LibrarianLoginView: View {
    @State private var librarianID = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showPasswordReset = false
    @Binding var showMainApp: Bool
    @Binding var selectedRole: UserRole?
    
    var body: some View {
        VStack(spacing: 30) {
            // Header with back button
            HStack {
                Spacer()
            }
            
            // Header
            VStack(spacing: 16) {
                Image(systemName: "person.text.rectangle")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Librarian Login")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Enter your credentials to access the librarian dashboard")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 20)
            
            Spacer()
            
            // Login Form
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Librarian ID")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter your librarian ID", text: $librarianID)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .autocapitalization(.none)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    SecureField("Enter your password", text: $password)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Login button
            Button(action: {
                showPasswordReset = true
            }) {
                Text("Login")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(minWidth: 120, maxWidth: 280)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarBackButtonHidden(false)
        .sheet(isPresented: $showPasswordReset) {
            LibrarianPasswordResetView(showMainApp: $showMainApp)
        }
    }
}

struct LibrarianPasswordResetView: View {
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Environment(\.dismiss) private var dismiss
    @Binding var showMainApp: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Set a new password")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Create a new password for your account")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 30)
                
                Spacer()
                
                // Password Form
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Password")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        SecureField("Enter new password", text: $newPassword)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        SecureField("Confirm new password", text: $confirmPassword)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Reset Password button
                Button(action: {
                    if validatePasswords() {
                        // In a real app, you would update the password here
                        dismiss()
                        showMainApp = true
                    }
                }) {
                    Text("Reset Password")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(minWidth: 120, maxWidth: 280)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func validatePasswords() -> Bool {
        if newPassword.isEmpty || confirmPassword.isEmpty {
            alertMessage = "Please fill in both password fields"
            showAlert = true
            return false
        }
        if newPassword != confirmPassword {
            alertMessage = "Passwords do not match"
            showAlert = true
            return false
        }
        return true
    }
}

#Preview {
    LibrarianLoginView(showMainApp: .constant(false), selectedRole: .constant(nil))
}
