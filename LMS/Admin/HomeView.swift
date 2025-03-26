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
    @State private var showingAddAnnouncementSheet = false
    @State private var selectedAnnouncementType: AnnouncementListType = .active
    @State private var showingAnnouncementList = false
    
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
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Announcements Header
                    HStack {
                        Text("Announcements")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: {
                            showingAddAnnouncementSheet = true
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("New Announcement")
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Announcement Type Cards
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            // Active Announcements Card
                            AnnouncementTypeCard(
                                type: .active,
                                count: announcementStore.activeAnnouncements.count,
                                action: {
                                    selectedAnnouncementType = .active
                                    showingAnnouncementList = true
                                }
                            )
                            
                            // Scheduled Announcements Card
                            AnnouncementTypeCard(
                                type: .scheduled,
                                count: announcementStore.scheduledAnnouncements.count,
                                action: {
                                    selectedAnnouncementType = .scheduled
                                    showingAnnouncementList = true
                                }
                            )
                            
                            // Archived Announcements Card
                            AnnouncementTypeCard(
                                type: .archived,
                                showCount: false,
                                action: {
                                    selectedAnnouncementType = .archived
                                    showingAnnouncementList = true
                                }
                            )
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        AdminHomeView()
                    } label: {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.blue)
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
        }
    }
}

struct AnnouncementTypeCard: View {
    let type: HomeView.AnnouncementListType
    var count: Int = 0
    var showCount: Bool = true
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(type.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if showCount {
                        Text("\(count)")
                            .font(.subheadline)
                            .padding(6)
                            .background(type.color.opacity(0.2))
                            .foregroundColor(type.color)
                            .cornerRadius(8)
                    }
                }
                
                Text("View \(type.title)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(width: 160)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
