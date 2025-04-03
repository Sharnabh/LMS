//
//  HomeView.swift
//  LMS
//
//  Created by Utkarsh Raj Saxena on 19/03/25.
//

import Foundation
import SwiftUI

struct HomeView: View {
    @StateObject private var announcementStore = AnnouncementStore()
    @StateObject private var bookStore = AdminBookStore()
    @State private var showingAddAnnouncementSheet = false
    @State private var selectedAnnouncementType: AnnouncementListType = .active
    @State private var showingAnnouncementList = false
    @State private var totalMembersCount: Int = 0
    @State private var isLoadingMembers: Bool = false
    @EnvironmentObject private var appState: AppState
    @State private var memberError: String? = nil
    
    // Analytics states
    @State private var totalBooksCount: Int = 0
    @State private var issuedBooksCount: Int = 0
    @State private var overdueBooksCount: Int = 0
    @State private var booksDueToday: Int = 0
    @State private var totalRevenue: Double = 0
    @State private var membersWithOverdueBooks: Int = 0
    
    @State private var isLoadingBooks: Bool = false
    @State private var isLoadingAnalytics: Bool = false
    @State private var bookError: String? = nil
    @State private var analyticsError: String? = nil
    
    // Add loading state for announcements
    private var isLoadingAnnouncements: Bool {
        announcementStore.isLoading
    }
    
    enum AnnouncementListType {
        case active, scheduled, archived
        
        var title: String {
            switch self {
            case .active: return "Active"
            case .scheduled: return "Scheduled"
            case .archived: return "Archived"
            }
        }
        
        var color: Color {
            switch self {
            case .active: return .green
            case .scheduled: return .blue
            case .archived: return .gray
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // Divider line between Navigation Title and Dashboard
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color.gray.opacity(0.3))
                        .padding(.bottom, 8)
                    
                    // Dashboard Header
                    Text("Dashboard")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    // Four Cards Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        // Card 1: Total Books
                        HomeCard(
                            title: "Total Books",
                            value: bookCountDisplay,
                            icon: "book.fill",
                            color: .blue
                            
                        )
                        .overlay(
                            Group {
                                if bookError != nil {
                                    Button(action: {
                                        Task {
                                            await loadBooksCount()
                                        }
                                    }) {
                                        Image(systemName: "arrow.clockwise")
                                            .foregroundColor(.blue)
                                    }
                                    .padding(8)
                                }
                            },
                            alignment: .topTrailing
                        )
                        
                        // Card 2: Issued Books
                        HomeCard(
                            title: "Issued Books",
                            value: issuedBooksDisplay,
                            icon: "book.closed.fill",
                            color: .purple
                        )
                        .overlay(
                            Group {
                                if analyticsError != nil {
                                    Button(action: {
                                        Task {
                                            await loadAnalytics()
                                        }
                                    }) {
                                        Image(systemName: "arrow.clockwise")
                                            .foregroundColor(.purple)
                                    }
                                    .padding(8)
                                }
                            },
                            alignment: .topTrailing
                        )
                        
                        // Card 3: Revenue
                        HomeCard(
                            title: "Revenue",
                            value: revenueDisplay,
                            icon: "indianrupeesign",
                            color: .red
                        )
                        
                        HomeCard(
                            title: "Today's Returns",
                            value: booksDueTodayDisplay,
                            icon: "return",
                            color: .orange
                        )
                       
                    }
                    .padding(.horizontal)
//                    .frame(maxWidth: .infinity, maxHeight: 150)
//                            .background(Color(.systemBackground))
//                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    // Announcements Header
                    HStack {
                        Text("Announcements")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: {
                            showingAddAnnouncementSheet = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.horizontal)
                    
                    
                    // Announcement Type Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        // Active Announcements Card
                        AnnouncementTypeCard(
                            type: .active,
                            count: announcementStore.activeAnnouncements.count,
                            showCount: true,
                            isLoading: isLoadingAnnouncements,
                            action: {
                                selectedAnnouncementType = .active
                                showingAnnouncementList = true
                            }
                        )
                        
                        // Scheduled Announcements Card
                        AnnouncementTypeCard(
                            type: .scheduled,
                            count: announcementStore.scheduledAnnouncements.count,
                            showCount: true,
                            isLoading: isLoadingAnnouncements,
                            action: {
                                selectedAnnouncementType = .scheduled
                                showingAnnouncementList = true
                            }
                        )
                        
                        // Archived Announcements Card
                        AnnouncementTypeCard(
                            type: .archived,
                            showCount: false,
                            isLoading: isLoadingAnnouncements,
                            action: {
                                selectedAnnouncementType = .archived
                                showingAnnouncementList = true
                            }
                        )
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.automatic)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        NavigationLink {
                            BookDeletionRequestsView()
                                .environmentObject(bookStore)
                        } label: {
                            ZStack {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(.accentColor)
                                
                                if !bookStore.deletionRequests.isEmpty {
                                    Text("\(bookStore.deletionRequests.count)")
                                        .font(.caption2)
                                        .padding(5)
                                        .background(Color.red)
                                        .foregroundColor(.white)
                                        .clipShape(Circle())
                                        .offset(x: 10, y: -10)
                                }
                            }
                        }
                        
                        NavigationLink {
                            AdminProfileView()
                                .environmentObject(appState)
                        } label: {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddAnnouncementSheet) {
                AddAnnouncementView(announcementStore: announcementStore)
            }
            .sheet(isPresented: $showingAnnouncementList) {
                AnnouncementListView(
                    type: selectedAnnouncementType,
                    announcementStore: announcementStore
                )
            }
            .task {
                print("🏠 HomeView task started - loading data")
                await loadInitialData()
                print("🏠 HomeView - Fetched all data")
            }
        }
    }
    
    private func loadInitialData() async {
        await loadBooksCount()
        await loadAnalytics()
        bookStore.fetchDeletionRequests()
    }
    
    private func loadBooksCount() async {
        isLoadingBooks = true
        bookError = nil
        
        do {
            totalBooksCount = try await BookService.shared.getTotalBooksCount()
            print("Successfully loaded book count: \(totalBooksCount)")
        } catch {
            print("Error loading books count: \(error)")
            bookError = error.localizedDescription
        }
        
        isLoadingBooks = false
    }
    
    private func loadAnalytics() async {
        isLoadingAnalytics = true
        analyticsError = nil
        
        do {
            async let issuedBooks = AnalyticsService.shared.getIssuedBooksCount()
            async let overdueBooks = AnalyticsService.shared.getOverdueBooksCount()
            async let dueToday = AnalyticsService.shared.getBooksDueToday()
            async let revenue = AnalyticsService.shared.getTotalRevenue()
            async let membersOverdue = AnalyticsService.shared.getMembersWithOverdueBooks()
            
            let (issued, overdue, due, rev, overdueMembers) = try await (issuedBooks, overdueBooks, dueToday, revenue, membersOverdue)
            
            await MainActor.run {
                self.issuedBooksCount = issued
                self.overdueBooksCount = overdue
                self.booksDueToday = due
                self.totalRevenue = rev
                self.membersWithOverdueBooks = overdueMembers
                self.isLoadingAnalytics = false
            }
        } catch {
            print("Error loading analytics: \(error)")
            analyticsError = error.localizedDescription
            isLoadingAnalytics = false
        }
    }
    
    var bookCountDisplay: String {
        if isLoadingBooks {
            return "Loading..."
        }
        if bookError != nil {
            return "Tap to retry"
        }
        return "\(totalBooksCount)"
    }
    
    var issuedBooksDisplay: String {
        if isLoadingAnalytics {
            return "Loading..."
        }
        if analyticsError != nil {
            return "Tap to retry"
        }
        return "\(issuedBooksCount)"
    }
    
    var revenueDisplay: String {
        if isLoadingAnalytics {
            return "Loading..."
        }
        if analyticsError != nil {
            return "Tap to retry"
        }
        return "₹\(String(format: "%.2f", totalRevenue))"
    }
    
    var booksDueTodayDisplay: String {
        if isLoadingAnalytics {
            return "Loading..."
        }
        if analyticsError != nil {
            return "Tap to retry"
        }
        return "\(booksDueToday)"
    }
    
    var overdueBooksDisplay: String {
        if isLoadingAnalytics {
            return "Loading..."
        }
        if analyticsError != nil {
            return "Tap to retry"
        }
        return "\(overdueBooksCount)"
    }
}

struct HomeCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Spacer()
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: 150)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct AnnouncementTypeCard: View {
    let type: HomeView.AnnouncementListType
    var count: Int = 0
    var showCount: Bool = true
    var isLoading: Bool = false
    var action: () -> Void
    
    private var icon: String {
        switch type {
        case .active: return "megaphone.fill"
        case .scheduled: return "calendar"
        case .archived: return "archivebox"
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(type.color)
                    
                    if showCount {
                        Spacer()
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Text("\(count)")
                                .font(.footnote)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(type.color.opacity(0.2))
                                .foregroundColor(type.color)
                                .cornerRadius(6)
                        }
                    }
                }
                
                Text(type.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 90)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: type.color.opacity(0.1), radius: 8, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(type.color.opacity(0.2), lineWidth: 1)
                    )
            )
            .opacity(isLoading ? 0.7 : 1)
        }
        .disabled(isLoading)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AppState())
    }
}
