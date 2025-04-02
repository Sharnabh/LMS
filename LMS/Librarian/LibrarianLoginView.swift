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
            if showOTPVerification {
                // OTP Verification View - Clean focused layout
                VStack(spacing: 16) {
                    // Icon and title area
                    VStack(spacing: 10) {
                        Image(systemName: "person.badge.key.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Verify OTP")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Enter the verification code sent to your email")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.bottom, 5)
                    }
                    
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
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
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
                                    .foregroundColor(.blue)
                            }
                        }
                        .disabled(isLoading || resendCountdown > 0)
                    }
                    .padding(.top, 5)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 30)
                .background(Color(.systemBackground))
                .onAppear {
                    // Auto-focus OTP field when view appears
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
//                        Image(systemName: "person.text.rectangle")
//                            .font(.system(size: 80))
//                            .foregroundColor(.blue)
                        
                        Text("Librarian Login")
                            .font(.title)
                            .fontWeight(.bold)
                        
//                        Text("Enter your credentials to access as librarian dashboard")
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                            .multilineTextAlignment(.center)
//                            .padding(.horizontal)
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
                            .foregroundColor(.accentColor)
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
                    .background(Color.accentColor)
                    .cornerRadius(12)
                    .disabled(isLoading)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                }
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
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
        
        do {
            let isValid = dataController.verifyOTP(email: email, otp: otp)
            
            DispatchQueue.main.async {
                isLoading = false
                
                if isValid {
                    // Store authentication state after successful OTP verification
                    librarianIsLoggedIn = true
                    librarianEmail = email
                    appState.showLibrarianApp = true
                    showLibrarianInitialView = true
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
                    // Instead of directly showing the initial view, show profile setup first
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
