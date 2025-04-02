//
//  LoginView.swift
//  LMS
//
//  Created by Utkarsh Raj Saxena on 01/04/25.
//

import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
   // @State private var rememberMe = false
    
    var body: some View {
        ZStack {
            // Background color
            Color("AccentColor")
                .ignoresSafeArea()
            
            VStack {
                // Wave shape
                WaveShape()
                    .fill(Color.white)
                    .padding(.top, -350) // Changes
                    .frame(height: UIScreen.main.bounds.height * 0.9)
                    .offset(y: UIScreen.main.bounds.height * 0.04)
                
                Spacer()
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Back button
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 90) // Changes
                    
                    // Sign in text
                    Text("Sign in")
                        .font(.system(size: 40, weight: .bold))
                        .padding(.top, 40)
                        .padding(.horizontal, 20)
                    
                    // Login form
                    VStack(spacing: 20) {
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .foregroundColor(.gray)
                            
                            TextField("example@email.com", text: $email)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        
                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .foregroundColor(.gray)
                            
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Remember me and Forgot Password
                        HStack {
//                            Toggle("Remember me", isOn: $rememberMe)
//                                .toggleStyle(CheckboxToggleStyle())
                            
                            Spacer()
                            
                            Button("Forgot Password?") {
                                // Handle forgot password
                            }
                            .foregroundColor(.red)
                        }
                        
                        // Login button
                        Button(action: {
                            // Handle login
                        }) {
                            Text("Login")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("AccentColor"))
                                .cornerRadius(15)
                        }
                        .padding(.top, 20)
                        
                        // Sign up link
                        HStack {
                            Text("Don't have an account?")
                                .foregroundColor(.gray)
                            
                            Button("Sign up") {
                                // Handle sign up
                            }
                            .foregroundColor(.red)
                        }
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

//struct CustomTextFieldStyle: TextFieldStyle {
//    func _body(configuration: TextField<Self._Label>) -> some View {
//        configuration
//            .padding()
//            .background(
//                RoundedRectangle(cornerRadius: 12)
//                    .fill(Color.gray.opacity(0.1))
//            )
//    }
//}



#Preview {
    LoginView()
}
