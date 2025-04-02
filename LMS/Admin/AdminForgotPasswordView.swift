//
//  AdminForgotPasswordView.swift
//  LMS
//
//  Created by Sharnabh on 19/03/25.
//

import SwiftUI

struct AdminForgotPasswordView: View {
    // Callback for when the process is complete
    var onComplete: () -> Void
    
    // State variables
    @State private var email = ""
    @State private var otp = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var step = 1 // 1: Email verification, 2: OTP verification, 3: Password reset
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var sentOTP = ""
    @State private var adminId: String?
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var animateContent = false
    @State private var shouldReturnToLogin = false // Flag to indicate if the alert should return to login
    @FocusState private var otpFieldFocused: Bool
    @State private var resendCountdown = 0
    @State private var timer: Timer?
    
    // Data controller
    private let dataController = SupabaseDataController()
    
    var body: some View {
        ZStack {
            // Background gradient
            
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
            VStack {
                // Header
                HStack {
                    Button(action: {
                        if step > 1 {
                            step -= 1
                        } else {
                            onComplete()
                        }
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .padding(.leading)
                    
                    Spacer()
                }
                .padding(.top)
                
                // Content
                ScrollView {
                    VStack(spacing: 30) {
                        // Icon and title
                        VStack(spacing: 16) {
                            
                            Text(step == 1 ? "Forgot Password" : (step == 2 ? "Verify OTP" : "Reset Password"))
                                .font(.title)
                                .fontWeight(.semibold)
                                .padding(.top, 170)
                                .padding(.leading, -150)
                                .opacity(animateContent ? 1 : 0)
                                .offset(y: animateContent ? 0 : 20)
                            
                            Text(step == 1 ? "" :
                                 (step == 2 ? "Enter the 6-digit code sent to your email" : 
                                    "Create a new password for your account"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .opacity(animateContent ? 1 : 0)
                                .offset(y: animateContent ? 0 : 20)
                        }
                        .padding(.top, 20)
                        
                        // Form content based on current step
                        if step == 1 {
                            // Email verification
                            emailVerificationView
                        } else if step == 2 {
                            // OTP verification
                            otpVerificationView
                        } else {
                            // Password reset
                            passwordResetView
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(shouldReturnToLogin ? "Information" : "Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if shouldReturnToLogin {
                        onComplete() // Return to login screen only when needed
                    }
                }
            )
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
    
    // MARK: - Email Verification View
    private var emailVerificationView: some View {
        VStack(spacing: 25) {
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
            
            // Send OTP Button
            Button(action: {
                Task {
                    await verifyEmail()
                }
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.trailing, 8)
                    }
                    
                    Text("Send Verification Code")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.accentColor)
                .cornerRadius(12)
            }
            .disabled(isLoading)
            
            // Back to Login Button
            Button(action: {
                onComplete()
            }) {
//                Text("Back to Login")
//                    .font(.subheadline)
//                    .foregroundColor(.blue)
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - OTP Verification View
    private var otpVerificationView: some View {
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
                    .onChange(of: otp) { oldValue, newValue in
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
                
            // Verify Button
            Button(action: {
                verifyOTP()
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
                
                if resendCountdown > 0 {
                    Text("Resend code in \(resendCountdown)s")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else {
                    Button(action: {
                        Task {
                            await resendOTP()
                        }
                    }) {
                        Text("Resend Code")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .disabled(isLoading)
                }
            }
            .padding(.top, 10)
        }
    }
    
    // OTP Digit Box
    private struct OTPDigitBox: View {
        let index: Int
        @Binding var otp: String
        var onTap: () -> Void
        
        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 45, height: 55)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemBackground)))
                
                if index < otp.count {
                    let digit = String(Array(otp)[index])
                    Text(digit)
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(index < otp.count ? Color.blue : Color.clear, lineWidth: 1.5)
            )
            .animation(.spring(response: 0.2), value: otp.count)
            .onTapGesture {
                onTap()
            }
        }
    }
    
    // MARK: - Password Reset View
    private var passwordResetView: some View {
        VStack(spacing: 25) {
            // New Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("New Password")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ZStack(alignment: .trailing) {
                    if showPassword {
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
                            showPassword.toggle()
                        }
                    }) {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.gray)
                            .padding(.trailing, 12)
                    }
                }
            }
            
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
            
            // Password Requirements Checklist
            passwordRequirements
                .padding(.top, 5)
            
            // Reset Password Button
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
                    
                    Text("Reset Password")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .disabled(isLoading || newPassword.isEmpty || confirmPassword.isEmpty)
        }
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
    
    // MARK: - Logic Functions
    
    private func verifyEmail() async {
        guard !email.isEmpty else {
            alertMessage = "Please enter your email address"
            showAlert = true
            return
        }
        
        // Validate email format
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        guard NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email) else {
            alertMessage = "Please enter a valid email address"
            showAlert = true
            return
        }
        
        isLoading = true
        
        do {
            // Verify if email exists in Admin table
            let result = try await dataController.verifyAdminEmail(email: email)
            
            if result.exists, let id = result.adminId {
                adminId = id
                
                // Check if this is a first-time login
                if result.isFirstLogin {
                    DispatchQueue.main.async {
                        isLoading = false
                        shouldReturnToLogin = true
                        alertMessage = "This account hasn't been activated yet. Please use the default password that was sent to your email when your account was created. You'll be prompted to set a new password on first login."
                        showAlert = true
                    }
                    return
                } else {
                    shouldReturnToLogin = false
                }
                
                // Generate and send OTP with expiry
                sentOTP = dataController.generateOTP(for: email)
                
                // Send OTP to email
                let _ = try await dataController.sendOTP(to: email, name: "Admin", otp: sentOTP)
                
                // Move to OTP verification step
                DispatchQueue.main.async {
                    isLoading = false
                    step = 2
                    // Start countdown for resend button
                    startResendCountdown()
                }
            } else {
                DispatchQueue.main.async {
                    isLoading = false
                    alertMessage = "No admin account found with this email address"
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
    
    private func verifyOTP() {
        guard otp.count == 6 else {
            alertMessage = "Please enter the complete 6-digit code"
            showAlert = true
            return
        }
        
        // Verify OTP with expiry check
        if dataController.verifyOTP(email: email, otp: otp) {
            // Move to password reset step
            step = 3
        } else {
            alertMessage = "Invalid or expired verification code. Please try again or request a new code."
            showAlert = true
        }
    }
    
    private func resendOTP() async {
        isLoading = true
        
        do {
            // Generate new OTP with expiry
            sentOTP = dataController.generateOTP(for: email)
            
            // Resend OTP to email
            let _ = try await dataController.sendOTP(to: email, name: "Admin", otp: sentOTP)
            
            DispatchQueue.main.async {
                isLoading = false
                // Start countdown for resend button
                startResendCountdown()
            }
        } catch {
            DispatchQueue.main.async {
                isLoading = false
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
    
    private func resetPassword() async {
        guard !newPassword.isEmpty, !confirmPassword.isEmpty else {
            alertMessage = "Please enter and confirm your new password"
            showAlert = true
            return
        }
        
        guard newPassword == confirmPassword else {
            alertMessage = "Passwords do not match"
            showAlert = true
            return
        }
        
        // Validate password
        let validationResult = dataController.validatePassword(newPassword)
        if !validationResult.isValid {
            alertMessage = validationResult.errorMessage ?? "Invalid password"
            showAlert = true
            return
        }
        
        isLoading = true
        
        do {
            guard let id = adminId else {
                throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Admin ID not found"])
            }
            
            // Update password in database
            try await dataController.resetAdminPassword(adminId: id, newPassword: newPassword)
            
            DispatchQueue.main.async {
                isLoading = false
                onComplete() // Return to login screen
            }
        } catch {
            DispatchQueue.main.async {
                isLoading = false
                alertMessage = "Failed to reset password: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}

#Preview {
    AdminForgotPasswordView(onComplete: {})
}
