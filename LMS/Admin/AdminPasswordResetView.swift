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
    @State private var showPasswordRequirements = false
    
    private let dataController = SupabaseDataController()
    
    var body: some View {
        ZStack {
            
            Color("AccentColor") // ----------------Added
                .ignoresSafeArea()
            
            VStack { // -------------------Added
                WaveShape()
                    .fill(Color.white)
                    .padding(.top, -350) // Changes
                    .frame(height: UIScreen.main.bounds.height * 0.9)
                    .offset(y: UIScreen.main.bounds.height * 0.04)
                Spacer()
            }
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {

                        
                        Text("Reset Password")
                            .font(.title)
                            .padding(10)
                            .padding(.top, 200)
                            .padding(.leading, -145)
                            .fontWeight(.semibold)
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
                            
                            // Password Requirements List
                            if !newPassword.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Password Requirements")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        PasswordRequirementRow(
                                            text: "At least 8 characters",
                                            isValid: newPassword.count >= 8
                                        )
                                        
                                        PasswordRequirementRow(
                                            text: "One uppercase letter",
                                            isValid: newPassword.range(of: "[A-Z]", options: .regularExpression) != nil
                                        )
                                        
                                        PasswordRequirementRow(
                                            text: "One lowercase letter",
                                            isValid: newPassword.range(of: "[a-z]", options: .regularExpression) != nil
                                        )
                                        
                                        PasswordRequirementRow(
                                            text: "One number",
                                            isValid: newPassword.range(of: "[0-9]", options: .regularExpression) != nil
                                        )
                                        
                                        PasswordRequirementRow(
                                            text: "One special character",
                                            isValid: newPassword.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil
                                        )
                                    }
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                                .transition(.opacity)
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
                            
                            if !confirmPassword.isEmpty {
                                PasswordRequirementRow(
                                    text: "Passwords match",
                                    isValid: !newPassword.isEmpty && newPassword == confirmPassword
                                )
                                .padding(.top, 8)
                            }
                        }
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                    }
                    .padding(.horizontal, 24)
                    
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
                        .background(.accent)
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

struct PasswordRequirementRow: View {
    let text: String
    let isValid: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isValid ? .green : .gray.opacity(0.5))
                .imageScale(.small)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    AdminPasswordResetView(adminId: "preview_admin_id", onComplete: {})
} 
