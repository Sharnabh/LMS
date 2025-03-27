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
            MainAppView(userRole: selectedRole ?? .member, initialTab: 0)
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
    @State private var animateHeader = false
    @State private var animateCards = false
    @State private var animateButton = false
    @State private var animateGradient = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Updated gradient background with slower animation
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.15),
                        Color.purple.opacity(0.15),
                        Color.blue.opacity(0.15)
                    ],
                    startPoint: animateGradient ? .topLeading : .bottomLeading,
                    endPoint: animateGradient ? .bottomTrailing : .topTrailing
                )
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: true)) {
                        animateGradient.toggle()
                    }
                }
                
                // Add subtle pattern overlay
                Color.white.opacity(0.1)
                    .blendMode(.overlay)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Header with subtle animation
                    VStack(spacing: 16) {
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                            .scaleEffect(animateHeader ? 1.05 : 1.0)
                            .rotationEffect(.degrees(animateHeader ? 2 : -2))
                        
                        Text("Welcome to Pustakalaya")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .opacity(animateHeader ? 1 : 0)
                            .offset(y: animateHeader ? 0 : 10)
                    }
                    .padding(.top, 60)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.5)) {
                            animateHeader = true
                        }
                    }
                    
                    Spacer()
                    
                    // Role selection text
                    Text("Please select your role to continue")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : 10)
                        .padding(.bottom, 10)
                    
                    // Role selection cards with subtle animation
                    VStack(spacing: 20) {
                        RoleCard(
                            title: "Admin",
                            description: "Manage the entire\nlibrary system",
                            iconName: "person.badge.shield.checkmark",
                            color: .purple,
                            isSelected: selectedRole == .admin,
                            delay: 0.2
                        ) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                selectedRole = .admin
                            }
                        }
                        
                        RoleCard(
                            title: "Librarian",
                            description: "Manage books and\nmember borrowings",
                            iconName: "person.text.rectangle",
                            color: .blue,
                            isSelected: selectedRole == .librarian,
                            delay: 0.3
                        ) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                selectedRole = .librarian
                            }
                        }
                    }
                    .padding(.horizontal)
                    .opacity(animateCards ? 1 : 0)
                    .offset(y: animateCards ? 0 : 20)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                            animateCards = true
                        }
                    }
                    
                    Spacer()
                    
                    // Continue button with subtle animation
                    NavigationLink(destination: {
                        if selectedRole == .admin {
                            AdminLoginView(showMainApp: $showMainApp)
                        } else if selectedRole == .librarian {
                            LibrarianLoginView(showMainApp: $showMainApp, selectedRole: $selectedRole)
                        } else {
                            EmptyView()
                        }
                    }) {
                        Text("Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(minWidth: 120, maxWidth: 280)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 24)
                            .background(
                                selectedRole != nil ?
                                LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [.gray, .gray.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(12)
                            .shadow(color: selectedRole != nil ? .blue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                    }
                    .disabled(selectedRole == nil)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                    .opacity(animateButton ? 1 : 0)
                    .offset(y: animateButton ? 0 : 10)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                            animateButton = true
                        }
                    }
                }
            }
        }
    }
}

struct RoleCard: View {
    let title: String
    let description: String
    let iconName: String
    let color: Color
    let isSelected: Bool
    let delay: Double
    let action: () -> Void
    @State private var animateCard = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(color.opacity(0.2))
                            .blur(radius: 2)
                    )
                    .rotationEffect(.degrees(animateCard ? 0 : -180))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .frame(height: 90)
            .background(
                ZStack {
                    // Glassmorphism background
                    Color.white.opacity(0.2)
                    Color.white.opacity(0.1)
                        .blur(radius: 8)
                    
                    // Subtle gradient overlay
                    LinearGradient(
                        colors: [
                            color.opacity(0.1),
                            color.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                color.opacity(0.5),
                                color.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? color.opacity(0.3) : .black.opacity(0.1),
                radius: isSelected ? 10 : 8,
                x: 0,
                y: isSelected ? 5 : 3
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(delay)) {
                animateCard = true
            }
        }
    }
}

struct MainAppView: View {
    let userRole: UserRole
    @State private var selectedTab: Int
    
    init(userRole: UserRole, initialTab: Int = 0) {
        self.userRole = userRole
        _selectedTab = State(initialValue: initialTab)
    }
    
    var body: some View {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(0)
                
                PatronsView()
                    .tabItem {
                        Image(systemName: "person.2")
                        Text("Patrons")
                    }
                    .tag(1)
                
                ResourcesView()
                    .tabItem {
                        Image(systemName: "folder.fill")
                        Text("Resources")
                    }
                    .tag(2)
                
                PoliciesView()
                    .tabItem {
                        Image(systemName: "book.pages")
                        Text("Policies")
                    }
                    .tag(3)
            }
            .toolbar(selectedTab == 0 ? .visible : .hidden, for: .navigationBar)
        }
}

enum UserRole: String {
    case admin = "Admin"
    case librarian = "Librarian"
    case member = "Member"
}

// The rest of the file remains the same
#Preview {
    ContentView()
}
