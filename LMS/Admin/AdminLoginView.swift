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
    @State private var otp = ""
    @State private var showAlert = false
    @State private var alertTitle = "Error"
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var showPassword = false
    @State private var showOTPVerification = false
    @FocusState private var otpFieldFocused: Bool
    @Binding var showMainApp: Bool
    @State private var animateContent = false
    @State private var showOnboarding = false
    @State private var showPasswordReset = false
    @State private var currentAdminId: String?
    @State private var showForgotPassword = false
    @State private var requiresOTP = false
    @State private var resendCountdown = 0
    @State private var timer: Timer?
    @AppStorage("adminIsLoggedIn") private var adminIsLoggedIn = false
    @AppStorage("adminEmail") private var adminEmail = ""
    
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
                        Text(showOTPVerification ? "Verify OTP" : "Admin Login")
                            .font(.title)
                            .fontWeight(.semibold)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                            .padding(.top, 190)
                            .padding(.leading, -170)
                        
                        Text(showOTPVerification ? "Enter the verification code sent to your email" : "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                    }
                    .padding(.top, 40)
                    
                    if showOTPVerification {
                        // OTP Verification View
                        VStack(spacing: 25) {
                            // OTP Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Verification Code")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                // OTP digit boxes
                                HStack(spacing: 10) {
                                    ForEach(0..<6, id: \.self) { index in
                                        OTPDigitBox(index: index, otp: $otp, onTap: {
                                            otpFieldFocused = true
                                        })
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                
                                // Hidden text field to handle actual input
                                TextField("", text: $otp)
                                    .keyboardType(.numberPad)
                                    .frame(width: 0, height: 0)
                                    .opacity(0)
                                    .focused($otpFieldFocused)
                                    .onChange(of: otp) { newValue in
                                        // Limit to 6 digits
                                        if newValue.count > 6 {
                                            otp = String(newValue.prefix(6))
                                        }
                                        
                                        // Filter non-numeric characters
                                        otp = newValue.filter { "0123456789".contains($0) }
                                    }
                            }
                            
                            // Expiry info text
                            Text("This verification code is valid for 10 minutes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Verify OTP Button
                            Button(action: {
                                Task {
                                    await verifyOTP()
                                }
                            }) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .padding(.trailing, 8)
                                    }
                                    
                                    Text("Verify Code")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            .disabled(isLoading || otp.count != 6)
                            
                            // Resend OTP Button with timer
                            VStack(spacing: 8) {
                                Text("Didn't receive the code?")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Button(action: {
                                    Task {
                                        await resendOTP()
                                    }
                                }) {
                                    if resendCountdown > 0 {
                                        Text("Resend code in \(resendCountdown)s")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    } else {
                                        Text("Resend Code")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .disabled(isLoading || resendCountdown > 0)
                            }
                            .padding(.top, 10)
                        }
                        .padding(.horizontal, 24)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                    } else {
                        // Login Form
                        VStack(spacing: 20) {
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
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
                                    .foregroundColor(.gray)
                                
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
                        .padding(.top, -30)
                        
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
                                
                                Text("Log In")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(.accent)
                            .cornerRadius(12)
                        }
                        .disabled(isLoading)
                        .padding(.horizontal, 24)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                    }
                    
                    // Forgot Password Link
                    if !showOTPVerification {
                        Button(action: {
                            showForgotPassword = true
                        }) {
                            Text("Forgot Password?")
                                .font(.subheadline)
                                .foregroundColor(.accent)
                        }
                        .padding(.top, 8)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                    }
                    
                    Spacer()
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .fullScreenCover(isPresented: $showPasswordReset) {
            AdminPasswordResetView(adminId: currentAdminId ?? "", onComplete: {
                showMainApp = true
            })
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            AdminOnboardingView(onComplete: {
                showMainApp = true
            })
        }
        .fullScreenCover(isPresented: $showForgotPassword) {
            AdminForgotPasswordView(onComplete: {
                showForgotPassword = false
            })
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animateContent = true
            }
        }
        .onDisappear {
            // Invalidate timer when view disappears to avoid memory leaks
            timer?.invalidate()
            timer = nil
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
                        showPasswordReset = true
                    } else if result.requiresOTP {
                        showOTPVerification = true
                        requiresOTP = true
                        // Start countdown timer for resend button when OTP view appears
                        startResendCountdown()
                    } else {
                        // Store authentication state
                        adminIsLoggedIn = true
                        adminEmail = email
                        showMainApp = true
                    }
                } else {
                    alertTitle = "Error"
                    alertMessage = "Invalid email or password. Please try again."
                    showAlert = true
                }
            }
        } catch {
            DispatchQueue.main.async {
                isLoading = false
                alertTitle = "Error"
                alertMessage = "An error occurred: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
    
    private func verifyOTP() async {
        isLoading = true
        
        do {
            let isValid = dataController.verifyOTP(email: email, otp: otp)
            
            DispatchQueue.main.async {
                isLoading = false
                
                if isValid {
                    // Store authentication state after successful OTP verification
                    adminIsLoggedIn = true
                    adminEmail = email
                    showMainApp = true
                } else {
                    alertTitle = "Error"
                    alertMessage = "Invalid verification code. Please try again."
                    showAlert = true
                }
            }
        } catch {
            DispatchQueue.main.async {
                isLoading = false
                alertTitle = "Error"
                alertMessage = "An error occurred: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
    
    private func resendOTP() async {
        isLoading = true
        
        do {
            let otp = dataController.generateOTP(for: email)
            let _ = try await dataController.sendOTP(to: email, name: "Admin", otp: otp)
            
            DispatchQueue.main.async {
                isLoading = false
                alertTitle = "Success"
                alertMessage = "A new verification code has been sent to your email."
                showAlert = true
                // Start countdown for resend button
                startResendCountdown()
            }
        } catch {
            DispatchQueue.main.async {
                isLoading = false
                alertTitle = "Error"
                alertMessage = "Failed to resend code: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
    
    private func startResendCountdown() {
        // Invalidate existing timer
        timer?.invalidate()
        
        // Set initial countdown value (30 seconds)
        resendCountdown = 30
        
        // Create new timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if resendCountdown > 0 {
                resendCountdown -= 1
            } else {
                timer?.invalidate()
                timer = nil
            }
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
    }
}


#Preview {
    AdminLoginView(showMainApp: .constant(false))
}
