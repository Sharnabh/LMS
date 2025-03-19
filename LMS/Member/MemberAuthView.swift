import SwiftUI

struct MemberAuthView: View {
    @State private var isLoginMode = true
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Binding var showMainApp: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text(isLoginMode ? "Member Login" : "Sign Up")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(isLoginMode ? "Enter your credentials to access your account" : "Create your account to start borrowing books")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 60)
            
            Spacer()
            
            // Form fields
            VStack(spacing: 20) {
                if !isLoginMode {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter your full name", text: $name)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter your email", text: $email)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .keyboardType(.emailAddress)
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
                
                if !isLoginMode {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        SecureField("Confirm your password", text: $confirmPassword)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Action button
            Button(action: {
                handleAuth()
            }) {
                Text(isLoginMode ? "Login" : "Sign Up")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 30)
            
            // Toggle mode button
            Button(action: {
                withAnimation {
                    isLoginMode.toggle()
                    // Clear fields when switching modes
                    email = ""
                    password = ""
                    confirmPassword = ""
                    name = ""
                }
            }) {
                Text(isLoginMode ? "Don't have an account? Sign Up" : "Already have an account? Login")
                    .foregroundColor(.green)
            }
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarBackButtonHidden(false)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Notice"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func handleAuth() {
        if isLoginMode {
            // Handle login
            if email.isEmpty || password.isEmpty {
                alertMessage = "Please fill in all fields"
                showAlert = true
                return
            }
            // In a real app, you would validate credentials here
            showMainApp = true
        } else {
            // Handle signup
            if email.isEmpty || password.isEmpty || confirmPassword.isEmpty || name.isEmpty {
                alertMessage = "Please fill in all fields"
                showAlert = true
                return
            }
            if password != confirmPassword {
                alertMessage = "Passwords do not match"
                showAlert = true
                return
            }
            // In a real app, you would create the account here
            showMainApp = true
        }
    }
}

#Preview {
    MemberAuthView(showMainApp: .constant(false))
}
