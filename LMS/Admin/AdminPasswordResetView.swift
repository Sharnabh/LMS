//
//  AdminPasswordResetView.swift
//  SampleLMS
//
//  Created by Madhav Saxena on 18/03/25.
//

import SwiftUI

struct AdminPasswordResetView: View {
    let adminId: String
    let onComplete: () -> Void
    
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false
    @State private var animateContent = false
    @State private var showProfileSetup = false
    @State private var showAdminOnboarding = false
    
    private let dataController = SupabaseDataController()
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .scaleEffect(animateContent ? 1 : 0.8)
                            .opacity(animateContent ? 1 : 0)
                        
                        Text("Reset Password")
                            .font(.title)
                            .fontWeight(.semibold)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                        
                        Text("Please set a new password for your account")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                    }
                    .padding(.top, 40)
                    
                    // Reset Form
                    VStack(spacing: 20) {
                        // New Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Password")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            ZStack(alignment: .trailing) {
                                if showNewPassword {
                                    TextField("Enter new password", text: $newPassword)
                                        .textContentType(.newPassword)
                                        .textFieldStyle(CustomTextFieldStyle())
                                } else {
                                    SecureField("Enter new password", text: $newPassword)
                                        .textContentType(.newPassword)
                                        .textFieldStyle(CustomTextFieldStyle())
                                }
                                
                                Button(action: {
                                    withAnimation {
                                        showNewPassword.toggle()
                                    }
                                }) {
                                    Image(systemName: showNewPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 12)
                                }
                            }
                        }
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                        
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            ZStack(alignment: .trailing) {
                                if showConfirmPassword {
                                    TextField("Confirm new password", text: $confirmPassword)
                                        .textContentType(.newPassword)
                                        .textFieldStyle(CustomTextFieldStyle())
                                } else {
                                    SecureField("Confirm new password", text: $confirmPassword)
                                        .textContentType(.newPassword)
                                        .textFieldStyle(CustomTextFieldStyle())
                                }
                                
                                Button(action: {
                                    withAnimation {
                                        showConfirmPassword.toggle()
                                    }
                                }) {
                                    Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 12)
                                }
                            }
                        }
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                    }
                    .padding(.horizontal, 24)
                    
                    // Password Requirements
                    passwordRequirements
                    
                    // Reset Button
                    Button(action: {
                        Task {
                            await resetPassword()
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 8)
                            }
                            
                            Text("Update Password")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading || newPassword.isEmpty || confirmPassword.isEmpty || !passwordsMatch)
                    .padding(.horizontal, 24)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    
                    Spacer()
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertMessage.contains("Error") ? "Error" : "Success"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if !alertMessage.contains("Error") {
                        showProfileSetup = true
                    }
                }
            )
        }
        .fullScreenCover(isPresented: $showProfileSetup) {
            AdminProfileSetupView(adminId: adminId, onComplete: {
                onComplete()
            })
        }
        .fullScreenCover(isPresented: $showAdminOnboarding) {
            AdminOnboardingView(onComplete: onComplete)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animateContent = true
            }
        }
    }
    
    private var passwordsMatch: Bool {
        return newPassword == confirmPassword
    }
    
    // Password requirements checklist
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
    
    private func resetPassword() async {
        guard passwordsMatch else {
            alertMessage = "Passwords do not match. Please try again."
            showAlert = true
            return
        }
        
        guard !newPassword.isEmpty, newPassword.count >= 6 else {
            alertMessage = "Password must be at least 6 characters long."
            showAlert = true
            return
        }
        
        isLoading = true
        
        do {
            let admin = try await dataController.resetAdminPassword(adminId: adminId, newPassword: newPassword)
            
            DispatchQueue.main.async {
                isLoading = false
                
                // Store admin email in UserDefaults for session persistence
                // But don't set adminIsLoggedIn yet - wait until completing the full onboarding flow
                UserDefaults.standard.set(admin.email, forKey: "adminEmail")
                
                alertMessage = "Password has been updated successfully."
                showAlert = true
            }
        } catch {
            DispatchQueue.main.async {
                isLoading = false
                alertMessage = "Error: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}

#Preview {
    AdminPasswordResetView(adminId: "preview_admin_id", onComplete: {})
} 
