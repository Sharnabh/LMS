//
//  AdminLoginView.swift
//  SampleLMS
//
//  Created by Madhav Saxena on 18/03/25.
//

import SwiftUI

struct AdminLoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Binding var showMainApp: Bool
    @State private var showPasswordReset = false
    @State private var showOnboarding = false
    @State private var isLoading = false
    @State private var currentAdminId: String?
    
    private let dataController = SupabaseDataController()
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "person.badge.shield.checkmark")
                    .font(.system(size: 80))
                    .foregroundColor(.purple)
                
                Text("Admin Login")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Enter your credentials to access the admin dashboard")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 60)
            
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
                Task {
                    await authenticateAdmin()
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
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.purple)
            .cornerRadius(12)
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
            .disabled(isLoading)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Authentication Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showPasswordReset) {
                if let adminId = currentAdminId {
                    PasswordResetView(showMainApp: $showMainApp, adminId: adminId)
                }
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                AdminOnboardingView()
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
    
    private func authenticateAdmin() async {
        isLoading = true
        
        do {
            let result = try await dataController.authenticateAdmin(email: email, password: password)
            
            DispatchQueue.main.async {
                isLoading = false
                
                if result.isAuthenticated {
                    currentAdminId = result.adminId
                    if result.isFirstLogin {
                        showPasswordReset = true
                    } else {
                        showOnboarding = true
                    }
                } else {
                    alertMessage = "Invalid email or password. Please try again."
                    showAlert = true
                }
            }
        } catch {
            DispatchQueue.main.async {
                isLoading = false
                alertMessage = "An error occurred: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}

struct PasswordResetView: View {
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showOnboarding = false
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    @Binding var showMainApp: Bool
    let adminId: String
    
    private let dataController = SupabaseDataController()
    
    private var isPasswordValid: Bool {
        let validation = dataController.validatePassword(newPassword)
        return validation.isValid && newPassword == confirmPassword
    }
    
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
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)
                        
                        Text("Set a new password for your account")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 30)
                    
                    // Password Requirements
                    passwordRequirements
                        .padding(.horizontal)
                    
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
                                .textContentType(.newPassword)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            SecureField("Confirm new password", text: $confirmPassword)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                                .textContentType(.newPassword)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Submit button
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
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isPasswordValid ? Color.purple : Color.gray)
                    .cornerRadius(12)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                    .disabled(!isPasswordValid || isLoading)
                    .alert(isPresented: $showAlert) {
                        Alert(
                            title: Text("Password Reset"),
                            message: Text(alertMessage),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.large)
            .fullScreenCover(isPresented: $showOnboarding) {
                AdminOnboardingView()
            }
        }
    }
    
    private func resetPassword() async {
        isLoading = true
        
        do {
            try await dataController.updateAdminPassword(adminId: adminId, newPassword: newPassword)
            DispatchQueue.main.async {
                isLoading = false
                dismiss()
                showOnboarding = true
            }
        } catch {
            DispatchQueue.main.async {
                isLoading = false
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
}

#Preview {
    AdminLoginView(showMainApp: .constant(false))
}
