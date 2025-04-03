import SwiftUI

struct LibrarianLoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var otp = ""
    @State private var showAlert = false
    @State private var alertTitle = "Error"
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
    @State private var showOTPVerification = false
    @FocusState private var otpFieldFocused: Bool
    @State private var resendCountdown = 0
    @State private var timer: Timer?
    @State private var currentLibrarianId: String?
    @AppStorage("librarianIsLoggedIn") private var librarianIsLoggedIn = false
    @AppStorage("librarianEmail") private var librarianEmail = ""
    @EnvironmentObject private var appState: AppState
    @State private var showProfileSetup = false
    
    var body: some View {
        ZStack {
            Color.accentColor
                .ignoresSafeArea()
            
            VStack {
                WaveShape()
                    .fill(Color.white)
                    .padding(.top, -350)
                    .frame(height: UIScreen.main.bounds.height * 0.9)
                    .offset(y: UIScreen.main.bounds.height * 0.04)
                Spacer()
            }
           
            if showOTPVerification {
                // OTP Verification View - Clean focused layout
                ZStack {
                    // Background
                    Color.accentColor
                        .ignoresSafeArea()
                    
                    // Wave Shape
                    VStack {
                        WaveShape()
                            .fill(Color.white)
                            .padding(.top, -350)
                            .frame(height: UIScreen.main.bounds.height * 0.9)
                            .offset(y: UIScreen.main.bounds.height * 0.04)
//                        Spacer()
                    }
                    
                    // Content
                    VStack(spacing: 16) {
                        // Icon and title area
                        VStack(spacing: 10) {
                            Text("Verify OTP")
                                .font(.title)
                                .fontWeight(.bold)
                                .padding(.top, 90)
                                .padding(.leading, -160)
                            
                            
                            Text("Enter the verification code sent to your email")
                                .font(.subheadline)
                                .foregroundColor(.black)
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal)
                                .padding(.bottom, -25)
                                .padding(.leading, -10)
                        }
                        
                        // Rest of the content in a white background container
                        VStack(spacing: 20) {
                            // OTP Field
                            VStack(alignment: .leading, spacing: 5) {
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
                            }
                            
                            // Hidden text field to handle actual input
                            TextField("", text: $otp)
                                .keyboardType(.numberPad)
                                .frame(width: 0, height: 0)
                                .opacity(0)
                                .focused($otpFieldFocused)
                                .onChange(of: otp) { oldValue, newValue in
                                    if newValue.count > 6 {
                                        otp = String(newValue.prefix(6))
                                    }
                                    otp = newValue.filter { "0123456789".contains($0) }
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
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(.accent)
                                .cornerRadius(12)
                            }
                            .disabled(isLoading || otp.count != 6)
                            .padding(.top, 5)
                            
                            // Resend OTP Button with timer
                            HStack(spacing: 4) {
                                Text("Didn't receive the code?")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Button(action: {
                                    Task {
                                        await resendOTP()
                                    }
                                }) {
                                    if resendCountdown > 0 {
                                        Text("Resend in \(resendCountdown)s")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    } else {
                                        Text("Resend Code")
                                            .font(.caption)
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .disabled(isLoading || resendCountdown > 0)
                            }
                            .padding(.top, 5)
                        }
                        .padding(24)
                        .background(Color.white)
                        .cornerRadius(20)
                        .padding(.horizontal)
                        .padding(.top, 30)
                    }
                    .padding(.top, 30)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        otpFieldFocused = true
                    }
                }
            } else {
                // Regular login view - unchanged
                VStack(spacing: 30) {
                    // Header with back button
                    HStack {
                        Spacer()
                    }
                    
                    // Header
                    VStack(spacing: 16) {
                    
                        Text("Librarian Login")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.top, 90)
                            .padding(.leading, -170)
                        
              .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
//                    Spacer()
                    
                    // Login Form
                    VStack(spacing: 20) {
                    
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter your email", text: $email)
                                .padding()
                                
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .border(Color.gray.opacity(0.25))
                                .cornerRadius(10)
                        }
                        
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            if showPassword {
                                TextField("Enter your password", text: $password)
                                    .padding()
                                    .textContentType(.password)
                                    .border(Color.gray.opacity(0.25))
                                    .cornerRadius(12)
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
                                    //.cornerRadius(10)
                                    .textContentType(.password)
                                    .border(Color.gray.opacity(0.25))
                                    .cornerRadius(12)
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
                            
                            // Add Forgot Password directly here
                            HStack {
                                Spacer() // Push the button to the right
                                Button(action: {
                                    showForgotPassword = true
                                }) {
                                    Text("Forgot Password?")
                                        .font(.subheadline)
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal)
                    
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
                    .background(Color.accent)
                    .cornerRadius(12)
                    .disabled(isLoading)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                }
//                .background(Color(.systemGroupedBackground).ignoresSafeArea())
            }
        }
        // Common modifiers for both states
        .navigationBarBackButtonHidden(false)
        .fullScreenCover(isPresented: $showPasswordReset) {
            LibrarianPasswordResetView(showMainApp: $showMainApp, showLibrarianInitialView: $showLibrarianInitialView, showProfileSetup: $showProfileSetup)
        }
        .fullScreenCover(isPresented: $showProfileSetup) {
            if let librarianId = currentLibrarianId {
                LibrarianProfileSetupView(librarianId: librarianId, onComplete: {
                    showProfileSetup = false
                    showLibrarianInitialView = true
                })
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
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
        .onDisappear {
            // Invalidate timer when view disappears to avoid memory leaks
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func loginLibrarian() async {
        if !validateInput() {
            return
        }
        
        isLoading = true
        do {
            let result = try await dataController.authenticateLibrarian(email: email, password: password)
            isLoading = false
            
            if result.isAuthenticated {
                currentLibrarianId = result.librarianId
                // Store librarian ID in UserDefaults
                UserDefaults.standard.set(result.librarianId, forKey: "currentLibrarianID")
                
                if result.isFirstLogin {
                    showPasswordReset = true
                } else if result.requiresOTP {
                    showOTPVerification = true
                    // Start countdown timer for resend button when OTP view appears
                    startResendCountdown()
                } else {
                    // Store authentication state
                    librarianIsLoggedIn = true
                    librarianEmail = email
                    appState.showLibrarianApp = true
                    showLibrarianInitialView = true
                }
            } else {
                alertTitle = "Error"
                alertMessage = "Invalid credentials. Please try again."
                showAlert = true
            }
        } catch let error as NSError {
            isLoading = false
            alertTitle = "Error"
            if error.code == 403 {
                alertMessage = error.userInfo[NSLocalizedDescriptionKey] as? String ?? "Your account has been disabled. Please contact the administrator for assistance."
            } else {
                alertMessage = "Invalid credentials. Please try again."
            }
            showAlert = true
        } catch {
            isLoading = false
            alertTitle = "Error"
            alertMessage = "Invalid credentials. Please try again."
            showAlert = true
        }
    }
    
    private func validateInput() -> Bool {
        if email.isEmpty || password.isEmpty {
            alertTitle = "Error"
            alertMessage = "Please fill in all fields"
            showAlert = true
            return false
        }
        
        // Basic email validation
        if !email.contains("@") || !email.contains(".") {
            alertTitle = "Error"
            alertMessage = "Please enter a valid email address"
            showAlert = true
            return false
        }
        
        return true
    }
    
    private func verifyOTP() async {
        isLoading = true
        
//        do {
            let isValid = dataController.verifyOTP(email: email, otp: otp)
            
            DispatchQueue.main.async {
                isLoading = false
                
                if isValid {
                    // Store authentication state after successful OTP verification
                    librarianIsLoggedIn = true
                    librarianEmail = email
                    // Ensure librarian ID is stored in UserDefaults
                    if let librarianId = currentLibrarianId {
                        UserDefaults.standard.set(librarianId, forKey: "currentLibrarianID")
                    }
                    appState.showLibrarianApp = true
                    showLibrarianInitialView = true
                } else {
                    alertTitle = "Error"
                    alertMessage = "Invalid verification code. Please try again."
                    showAlert = true
                }
            }
//        } catch {
//            DispatchQueue.main.async {
//                isLoading = false
//                alertTitle = "Error"
//                alertMessage = "An error occurred: \(error.localizedDescription)"
//                showAlert = true
//            }
//        }
    }
    
    private func resendOTP() async {
        isLoading = true
        
        do {
            let otp = dataController.generateOTP(for: email)
            let _ = try await dataController.sendOTP(to: email, name: "Librarian", otp: otp)
            
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
    @Binding var showProfileSetup: Bool
    @State private var animateContent = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.accentColor
                    .ignoresSafeArea()
                
                VStack {
                    WaveShape()
                        .fill(Color.white)
                        .padding(.top, -350)
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
                                            .padding()
                                            .background(Color(.secondarySystemBackground))
                                            .cornerRadius(10)
                                    } else {
                                        SecureField("Enter new password", text: $newPassword)
                                            .textContentType(.newPassword)
                                            .padding()
                                            .background(Color(.secondarySystemBackground))
                                            .cornerRadius(10)
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
                                            requirementRow("At least 8 characters",
                                                isValid: newPassword.count >= 8)
                                            
                                            requirementRow("One uppercase letter",
                                                isValid: newPassword.range(of: "[A-Z]", options: .regularExpression) != nil)
                                            
                                            requirementRow("One lowercase letter",
                                                isValid: newPassword.range(of: "[a-z]", options: .regularExpression) != nil)
                                            
                                            requirementRow("One number",
                                                isValid: newPassword.range(of: "[0-9]", options: .regularExpression) != nil)
                                            
                                            requirementRow("One special character",
                                                isValid: newPassword.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil)
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
                                            .padding()
                                            .background(Color(.secondarySystemBackground))
                                            .cornerRadius(10)
                                    } else {
                                        SecureField("Confirm new password", text: $confirmPassword)
                                            .textContentType(.newPassword)
                                            .padding()
                                            .background(Color(.secondarySystemBackground))
                                            .cornerRadius(10)
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
                                    requirementRow("Passwords match",
                                        isValid: !newPassword.isEmpty && newPassword == confirmPassword)
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
            .navigationBarHidden(true)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    animateContent = true
                }
            }
        }
    }
    
    private var passwordsMatch: Bool {
        return newPassword == confirmPassword
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
                    showProfileSetup = true
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
    
    private func requirementRow(_ text: String, isValid: Bool) -> some View {
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

// OTP Digit Box View
//struct OTPDigitBox: View {
//    let index: Int
//    @Binding var otp: String
//    var onTap: () -> Void
//    
//    var body: some View {
//        ZStack {
//            RoundedRectangle(cornerRadius: 8)
//                .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
//                .frame(width: 45, height: 55)
//                .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemBackground)))
//            
//            if index < otp.count {
//                let digit = String(Array(otp)[index])
//                Text(digit)
//                    .font(.title2.bold())
//                    .foregroundColor(.primary)
//                    .transition(.scale.combined(with: .opacity))
//            }
//        }
//        .overlay(
//            RoundedRectangle(cornerRadius: 8)
//                .stroke(index < otp.count ? Color.blue : Color.clear, lineWidth: 1.5)
//        )
//        .animation(.spring(response: 0.2), value: otp.count)
//        .onTapGesture {
//            onTap()
//        }
//    }
//}

#Preview {
    LibrarianLoginView(showMainApp: .constant(false), selectedRole: .constant(nil))
}

#Preview {
    LibrarianPasswordResetView(showMainApp: .constant(false), showLibrarianInitialView: .constant(false), showProfileSetup: .constant(false))
}

