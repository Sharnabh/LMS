//
//  AdminLoginView.swift
//  SampleLMS
//
//  Created by Madhav Saxena on 18/03/25.
//

import SwiftUI

struct AdminLoginView: View {
    @State private var adminID = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Binding var showMainApp: Bool
    @State private var showPasswordReset = false
    
    // Sample admin credentials (in a real app, these would be stored securely)
    // TODO: Replace with secure authentication system
    private let validAdminID = "ADMIN001"
    private let validPassword = "password123"
    
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
                    Text("Admin ID")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter your admin ID", text: $adminID)
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
                // Show password reset screen instead of direct login
                showPasswordReset = true
            }) {
                Text("Login")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Authentication Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showPasswordReset) {
                PasswordResetView(showMainApp: $showMainApp)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
    
    private func authenticateAdmin() {
        // In a real app, you would make an API call to authenticate
        if adminID == validAdminID && password == validPassword {
            withAnimation {
                showMainApp = true
            }
        } else {
            alertMessage = "Invalid admin ID or password. Please try again."
            showAlert = true
        }
    }
}

#Preview {
    AdminLoginView(showMainApp: .constant(false))
}


// Add this after the AdminLoginView struct and before the #Preview

struct PasswordResetView: View {
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showOnboarding = false
    @Environment(\.dismiss) private var dismiss
    @Binding var showMainApp: Bool
    
    var body: some View {
        NavigationView {
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
                
                // Submit button
                Button(action: {
                    // Show onboarding screen
                    showOnboarding = true
                }) {
                    Text("Reset Password")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Password Reset"),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.large)
            .fullScreenCover(isPresented: $showOnboarding, onDismiss: {
                // When onboarding is dismissed, show the main app
                dismiss()
                showMainApp = true
            }) {
                AdminOnboardingView()
            }
        }
    }
}