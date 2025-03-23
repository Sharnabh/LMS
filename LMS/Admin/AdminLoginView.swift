//
//  AdminLoginView.swift
//  SampleLMS
//
//  Created by Madhav Saxena on 18/03/25.
//

import SwiftUI
import Supabase

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
    }
}

struct AdminLoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var showPassword = false
    @Binding var showMainApp: Bool
    @State private var animateContent = false
    @State private var showOnboarding = false
    @State private var currentAdminId: String?
    
    private let dataController = SupabaseDataController()
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.12),
                    Color.purple.opacity(0.12),
                    Color.indigo.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(animateContent ? 1 : 0.8)
                            .opacity(animateContent ? 1 : 0)
                        
                        Text("Admin Login")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                        
                        Text("Enter your credentials to access the admin dashboard")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                    }
                    .padding(.top, 40)
                    
                    // Login Form
                    VStack(spacing: 20) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter your email", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            ZStack(alignment: .trailing) {
                                if showPassword {
                                    TextField("Enter your password", text: $password)
                                        .textContentType(.password)
                                        .textFieldStyle(CustomTextFieldStyle())
                                } else {
                                    SecureField("Enter your password", text: $password)
                                        .textContentType(.password)
                                        .textFieldStyle(CustomTextFieldStyle())
                                }
                                
                                Button(action: {
                                    withAnimation {
                                        showPassword.toggle()
                                    }
                                }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 12)
                                }
                            }
                        }
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                    }
                    .padding(.horizontal, 24)
                    
                    // Login Button
                    Button(action: {
                        Task {
                            await authenticateAdmin()
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 8)
                            }
                            
                            Text("Sign In")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(
                            color: .blue.opacity(0.3),
                            radius: 15,
                            x: 0,
                            y: 8
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .disabled(isLoading)
                    .padding(.horizontal, 24)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    
                    Spacer()
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            AdminOnboardingView()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animateContent = true
            }
        }
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
                        showOnboarding = true
                    } else {
                        showMainApp = true
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

#Preview {
    AdminLoginView(showMainApp: .constant(false))
}
