import SwiftUI

struct LibrarianLoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showPasswordReset = false
    @State private var isLoading = false
    @Binding var showMainApp: Bool
    @Binding var selectedRole: UserRole?
    @StateObject private var dataController = SupabaseDataController()
    @State private var showLibrarianInitialView = false
    @State private var showPassword = false
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false
    @State private var showForgotPassword = false
    
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
                    Text("Email")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter your email", text: $email)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if showPassword {
                        TextField("Enter your password", text: $password)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                            .textContentType(.password)
                            .overlay(
                                Button(action: {
                                    showPassword.toggle()
                                }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                }
                                .padding(.trailing, 8),
                                alignment: .trailing
                            )
                    } else {
                        SecureField("Enter your password", text: $password)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                            .textContentType(.password)
                            .overlay(
                                Button(action: {
                                    showPassword.toggle()
                                }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                }
                                .padding(.trailing, 8),
                                alignment: .trailing
                            )
                    }
                }
            }
            .padding(.horizontal)
            
            // Forgot Password Link
            Button(action: {
                showForgotPassword = true
            }) {
                Text("Forgot Password?")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            .padding(.top, 8)
            
            Spacer()
            
            // Login button
            Button(action: {
                Task {
                    await loginLibrarian()
                }
            }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Login")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .frame(minWidth: 120, maxWidth: 280)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(Color.blue)
            .cornerRadius(12)
            .disabled(isLoading)
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarBackButtonHidden(false)
        .fullScreenCover(isPresented: $showPasswordReset) {
            LibrarianPasswordResetView(showMainApp: $showMainApp, showLibrarianInitialView: $showLibrarianInitialView)
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .fullScreenCover(isPresented: $showLibrarianInitialView) {
            LibrarianInitialView()
        }
        .fullScreenCover(isPresented: $showForgotPassword) {
            LibrarianForgotPasswordView(onComplete: {
                showForgotPassword = false
            })
        }
    }
    
    private func loginLibrarian() async {
        if !validateInput() {
            return
        }
        
        isLoading = true
        do {
            let (success, isFirstLogin) = try await dataController.authenticateLibrarian(email: email, password: password)
            isLoading = false
            
            if success {
                if isFirstLogin {
                    showPasswordReset = true
                } else {
                    showLibrarianInitialView = true
                }
            }
        } catch {
            isLoading = false
            alertMessage = "Invalid credentials. Please try again."
            showAlert = true
        }
    }
    
    private func validateInput() -> Bool {
        if email.isEmpty || password.isEmpty {
            alertMessage = "Please fill in all fields"
            showAlert = true
            return false
        }
        
        // Basic email validation
        if !email.contains("@") || !email.contains(".") {
            alertMessage = "Please enter a valid email address"
            showAlert = true
            return false
        }
        
        return true
    }
}

struct LibrarianPasswordResetView: View {
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    @Binding var showMainApp: Bool
    @Binding var showLibrarianInitialView: Bool
    @StateObject private var dataController = SupabaseDataController()
    @State private var showPassword = false
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false
    
    private var passwordRequirements: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Password Requirements:")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Group {
                requirementRow("At least 8 characters", isValid: newPassword.count >= 8)
                requirementRow("One uppercase letter", isValid: newPassword.range(of: "[A-Z]", options: .regularExpression) != nil)
                requirementRow("One lowercase letter", isValid: newPassword.range(of: "[a-z]", options: .regularExpression) != nil)
                requirementRow("One number", isValid: newPassword.range(of: "[0-9]", options: .regularExpression) != nil)
                requirementRow("One special character", isValid: newPassword.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil)
                requirementRow("Passwords match", isValid: !newPassword.isEmpty && newPassword == confirmPassword)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    private func requirementRow(_ text: String, isValid: Bool) -> some View {
        HStack {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isValid ? .green : .gray)
            Text(text)
                .foregroundColor(.secondary)
        }
    }
    
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
                        
                        if showNewPassword {
                            TextField("Enter new password", text: $newPassword)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                                .overlay(
                                    Button(action: {
                                        showNewPassword.toggle()
                                    }) {
                                        Image(systemName: showNewPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.trailing, 8),
                                    alignment: .trailing
                                )
                        } else {
                            SecureField("Enter new password", text: $newPassword)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                                .overlay(
                                    Button(action: {
                                        showNewPassword.toggle()
                                    }) {
                                        Image(systemName: showNewPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.trailing, 8),
                                    alignment: .trailing
                                )
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if showConfirmPassword {
                            TextField("Confirm new password", text: $confirmPassword)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                                .overlay(
                                    Button(action: {
                                        showConfirmPassword.toggle()
                                    }) {
                                        Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.trailing, 8),
                                    alignment: .trailing
                                )
                        } else {
                            SecureField("Confirm new password", text: $confirmPassword)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                                .overlay(
                                    Button(action: {
                                        showConfirmPassword.toggle()
                                    }) {
                                        Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.trailing, 8),
                                    alignment: .trailing
                                )
                        }
                    }
                }
                .padding(.horizontal)
                
                passwordRequirements
                    .padding(.horizontal)
                
                // Reset Password button
                Button(action: {
                    Task {
                        await resetPassword()
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Reset Password")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .frame(minWidth: 120, maxWidth: 280)
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(Color.blue)
                .cornerRadius(12)
                .disabled(isLoading)
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
        if newPassword.count < 6 {
            alertMessage = "Password must be at least 6 characters long"
            showAlert = true
            return false
        }
        return true
    }
    
    private func resetPassword() async {
        if !validatePasswords() {
            return
        }
        
        isLoading = true
        if let librarianID = UserDefaults.standard.string(forKey: "currentLibrarianID") {
            do {
                let success = try await dataController.updateLibrarianPassword(librarianID: librarianID, newPassword: newPassword)
                isLoading = false
                if success {
                    dismiss()
                    showLibrarianInitialView = true
                }
            } catch {
                isLoading = false
                alertMessage = "Failed to update password. Please try again."
                showAlert = true
            }
        } else {
            isLoading = false
            alertMessage = "Error: Librarian ID not found"
            showAlert = true
        }
    }
}

#Preview {
    LibrarianLoginView(showMainApp: .constant(false), selectedRole: .constant(nil))
}

#Preview {
    LibrarianPasswordResetView(showMainApp: .constant(false), showLibrarianInitialView: .constant(false))
}
