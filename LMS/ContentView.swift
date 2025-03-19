//
//  ContentView.swift
//  LMS
//
//  Created by Sharnabh on 17/03/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedRole: UserRole?
    @State private var showMainApp = false
    @State private var showAdminLogin = false
    
    var body: some View {
        if showMainApp {
            MainAppView(userRole: selectedRole ?? .member)
        } else if showAdminLogin {
            AdminLoginView(showMainApp: $showMainApp)
        } else {
            OnboardingView(selectedRole: $selectedRole, showMainApp: $showMainApp, showAdminLogin: $showAdminLogin)
        }
    }
}

struct OnboardingView: View {
    @Binding var selectedRole: UserRole?
    @Binding var showMainApp: Bool
    @Binding var showAdminLogin: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Welcome to SampleLMS")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Please select your role to continue")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 60)
            
            Spacer()
            
            // Role selection cards
            VStack(spacing: 20) {
                RoleCard(
                    title: "Admin",
                    description: "Manage the entire library system",
                    iconName: "person.badge.shield.checkmark",
                    color: .purple,
                    isSelected: selectedRole == .admin
                ) {
                    selectedRole = .admin
                }
                
                RoleCard(
                    title: "Librarian",
                    description: "Manage books and member borrowings",
                    iconName: "person.text.rectangle",
                    color: .blue,
                    isSelected: selectedRole == .librarian
                ) {
                    selectedRole = .librarian
                }
                
                RoleCard(
                    title: "Member",
                    description: "Borrow books and manage your account",
                    iconName: "person.crop.circle",
                    color: .green,
                    isSelected: selectedRole == .member
                ) {
                    selectedRole = .member
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Continue button
            Button(action: {
                withAnimation {
                    if selectedRole == .admin {
                        showAdminLogin = true
                    } else {
                        showMainApp = true
                    }
                }
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedRole != nil ? Color.blue : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(selectedRole == nil)
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

struct RoleCard: View {
    let title: String
    let description: String
    let iconName: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: iconName)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                    .frame(width: 60, height: 60)
                    .background(color.opacity(0.1))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MainAppView: View {
    let userRole: UserRole
    
    var body: some View {
        TabView {
            Text("Home Screen for \(userRole.rawValue)")
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            Text("Patrons")
                .tabItem {
                    Label("Patrons", systemImage: "person.2")
                }
            
            Text("Resources")
                .tabItem {
                    Label("Resources", systemImage: "folder")
                }
            
            Text("Policies")
                .tabItem {
                    Label("Policies", systemImage: "book.pages")
                }
        }
    }
}

enum UserRole: String {
    case admin = "Admin"
    case librarian = "Librarian"
    case member = "Member"
}

#Preview {
    ContentView()
}
