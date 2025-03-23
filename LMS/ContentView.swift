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
                // Enhanced animated gradient background
                LinearGradient(
                    colors: [
                        Color(hex: "8B5CF6").opacity(0.15),  // Violet
                        Color(hex: "D946EF").opacity(0.15),  // Fuchsia
                        Color(hex: "EC4899").opacity(0.15),  // Pink
                        Color(hex: "8B5CF6").opacity(0.15)   // Violet
                    ],
                    startPoint: animateGradient ? .topLeading : .bottomLeading,
                    endPoint: animateGradient ? .bottomTrailing : .topTrailing
                )
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.linear(duration: 15.0).repeatForever(autoreverses: true)) {
                        animateGradient.toggle()
                    }
                }
                
                // Enhanced pattern overlay
                ZStack {
                    Color.white.opacity(0.1)
                        .blendMode(.overlay)
                    Circle()
                        .fill(Color(hex: "32CE7A").opacity(0.1))
                        .frame(width: 300, height: 300)
                        .blur(radius: 20)
                        .offset(x: animateGradient ? 50 : -50, y: animateGradient ? -100 : 100)
                    Circle()
                        .fill(Color(hex: "FFEC19").opacity(0.1))
                        .frame(width: 250, height: 250)
                        .blur(radius: 20)
                        .offset(x: animateGradient ? -100 : 100, y: animateGradient ? 50 : -50)
                    Circle()
                        .fill(Color(hex: "091C27").opacity(0.1))
                        .frame(width: 200, height: 200)
                        .blur(radius: 15)
                        .offset(x: animateGradient ? 80 : -80, y: animateGradient ? 80 : -80)
                    Circle()
                        .fill(Color(hex: "D9D9D9").opacity(0.1))
                        .frame(width: 200, height: 200)
                        .blur(radius: 15)
                        .offset(x: animateGradient ? 80 : -80, y: animateGradient ? 80 : -80)
                    Circle()
                        .fill(Color(hex: "FFFFFF").opacity(0.1))
                        .frame(width: 200, height: 200)
                        .blur(radius: 15)
                        .offset(x: animateGradient ? 80 : -80, y: animateGradient ? 80 : -80)
                }
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Enhanced header with 3D animation
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "8B5CF6").opacity(0.1))
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "books.vertical.fill")
                                    .font(.system(size: 80))
                                    .foregroundStyle(
                                        .linearGradient(
                                            colors: [
                                                Color(hex: "8B5CF6"),
                                                Color(hex: "D946EF")
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            .padding(.top, 40)
                            
                            Text("Welcome to Pustak")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    .linearGradient(
                                        colors: [
                                            Color(hex: "8B5CF6"),
                                            Color(hex: "D946EF")
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .opacity(animateHeader ? 1 : 0)
                                .offset(y: animateHeader ? 0 : 20)
                                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: animateHeader)
                            
                            Text("Your Digital Library Companion")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .opacity(animateHeader ? 1 : 0)
                                .offset(y: animateHeader ? 0 : 10)
                                .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2), value: animateHeader)
                        }
                        .padding(.bottom, 40)
                        .onAppear {
                            animateHeader = true
                        }
                        
                        // Role selection cards with enhanced spacing
                        VStack(spacing: 24) {
                            Text("Select your role")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .opacity(animateCards ? 1 : 0)
                            
                            RoleCard(
                                title: "Admin",
                                description: "Manage the entire library system",
                                iconName: "person.badge.shield.checkmark",
                                color: .purple,
                                isSelected: selectedRole == .admin,
                                delay: 0.2
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedRole = .admin
                                }
                            }
                            
                            RoleCard(
                                title: "Librarian",
                                description: "Manage books and member borrowings",
                                iconName: "person.text.rectangle",
                                color: .blue,
                                isSelected: selectedRole == .librarian,
                                delay: 0.3
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedRole = .librarian
                                }
                            }
                        }
                        .padding(.horizontal)
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : 20)
                        .onAppear {
                            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                                animateCards = true
                            }
                        }
                        
                        Spacer(minLength: 40)
                        
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
                            HStack {
                                Text("Continue")
                                    .font(.headline)
                                if selectedRole != nil {
                                    Image(systemName: "arrow.right")
                                        .font(.headline)
                                        .opacity(animateButton ? 1 : 0)
                                        .offset(x: animateButton ? 0 : -10)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .padding(.horizontal, 40)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "8B5CF6"),
                                        Color(hex: "D946EF")
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(
                                color: Color(hex: "8B5CF6").opacity(0.3),
                                radius: 15,
                                x: 0,
                                y: 8
                            )
                        }
                        .disabled(selectedRole == nil)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                        .opacity(animateButton ? 1 : 0)
                        .offset(y: animateButton ? 0 : 10)
                        .onAppear {
                            withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
                                animateButton = true
                            }
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
                    .font(.system(size: 30))
                    .foregroundColor(color)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(color.opacity(0.2))
                            .blur(radius: 2)
                    )
                    .rotationEffect(.degrees(animateCard ? 0 : -180))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
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
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding()
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
        NavigationView {
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
}

enum UserRole: String {
    case admin = "Admin"
    case librarian = "Librarian"
    case member = "Member"
}

#Preview {
    ContentView()
}
