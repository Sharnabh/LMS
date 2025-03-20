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
            
            // Combined continue button
            Group {
                if selectedRole == .member {
                    NavigationLink(destination: {
                        MemberAuthView(showMainApp: $showMainApp)
                    }) {
                        Text("Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(minWidth: 120, maxWidth: 280)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 24)
                            .background(selectedRole != nil ? Color.blue : Color.gray)
                            .cornerRadius(12)
                    }
                } else {
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
                            .background(selectedRole != nil ? Color.blue : Color.gray)
                            .cornerRadius(12)
                    }
                }
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
            
           // AnalyticsView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Analytics")
                }
                .tag(2)
            
            ResourcesView()
                .tabItem {
                    Image(systemName: "folder.fill")
                    Text("Resources")
                }
                .tag(3)
            
            PoliciesView()
                .tabItem {
                    Image(systemName: "book.pages")
                    Text("Policies")
                }
                .tag(4)
        }
    }
}

//struct HomeView: View {
//    var body: some View {
//        NavigationView {
//            ScrollView {
//                VStack(spacing: 20) {
//                    // Header
//                    VStack(spacing: 16) {
//                        Image(systemName: "house.fill")
//                            .font(.system(size: 60))
//                            .foregroundColor(.purple)
//
//                        Text("Welcome to LMS")
//                            .font(.title)
//                            .fontWeight(.bold)
//
//                        Text("Your Library Management System")
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                    }
//                    .padding(.top, 20)
//
//                    // Quick Stats
//                    HStack(spacing: 20) {
//                        StatCard(title: "Total Books", value: "1,234", icon: "book.fill", color: .blue)
//                        StatCard(title: "Active Members", value: "567", icon: "person.2.fill", color: .green)
//                        StatCard(title: "Borrowed", value: "89", icon: "arrow.right.circle.fill", color: .orange)
//                    }
//                    .padding(.horizontal)
//
//                    // Recent Activity
//                    VStack(alignment: .leading, spacing: 15) {
//                        Text("Recent Activity")
//                            .font(.headline)
//                            .padding(.horizontal)
//
//                        ForEach(0..<5) { index in
//                            ActivityRow(
//                                icon: "arrow.right.circle.fill",
//                                title: "Book Borrowed",
//                                subtitle: "Book Title \(index + 1)",
//                                time: "2 hours ago"
//                            )
//                        }
//                    }
//                    .padding(.top)
//                }
//            }
//            .navigationTitle("Home")
//            .navigationBarTitleDisplayMode(.large)
//        }
//    }
//}

//struct StatCard: View {
//    let title: String
//    let value: String
//    let icon: String
//    let color: Color
//
//    var body: some View {
//        VStack(spacing: 8) {
//            Image(systemName: icon)
//                .font(.system(size: 30))
//                .foregroundColor(color)
//
//            Text(value)
//                .font(.title2)
//                .fontWeight(.bold)
//
//            Text(title)
//                .font(.caption)
//                .foregroundColor(.secondary)
//        }
//        .frame(maxWidth: .infinity)
//        .padding()
//        .background(Color(.secondarySystemBackground))
//        .cornerRadius(12)
//    }
//}

//struct ActivityRow: View {
//    let icon: String
//    let title: String
//    let subtitle: String
//    let time: String
//
//    var body: some View {
//        HStack(spacing: 15) {
//            Image(systemName: icon)
//                .font(.system(size: 24))
//                .foregroundColor(.purple)
//
//            VStack(alignment: .leading, spacing: 4) {
//                Text(title)
//                    .font(.subheadline)
//                    .fontWeight(.medium)
//
//                Text(subtitle)
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//            }
//
//            Spacer()
//
//            Text(time)
//                .font(.caption2)
//                .foregroundColor(.secondary)
//        }
//        .padding(.horizontal)
//        .padding(.vertical, 8)
//    }
//}
//
//struct AnalyticsView: View {
//    var body: some View {
//        NavigationView {
//            Text("Analytics View")
//                .navigationTitle("Analytics")
//        }
//    }
//}

enum UserRole: String {
    case admin = "Admin"
    case librarian = "Librarian"
    case member = "Member"
}

// The rest of the file remains the same
#Preview {
    ContentView()
}
