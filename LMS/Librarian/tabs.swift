//
//  tabs.swift
//  isbn search
//
//  Created by Piyush on 20/03/25.
//

import Foundation
import SwiftUI

struct LibrarianInitialView: View {
    @StateObject private var bookStore = BookStore()
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        TabView {
            HomeLibrarianView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            IssueHistoryView()
                .tabItem {
                    Image(systemName: "person.crop.rectangle.stack.fill")
                    Text("Member Desk")
                }

            AddView()
                .tabItem {
                    Image(systemName: "book")
                        .imageScale(.large)
                    Text("Add Books")
                        
                }
            ShelfLocationsView()
                .tabItem {
                    Image(systemName: "mappin.and.ellipse")
                    Text("Book Shelf")
                }
        }
        .environmentObject(bookStore)
        .environmentObject(appState)
        .accentColor(.blue)
        .onAppear {
            // Set the app-wide background color
            let appearance = UITabBarAppearance()
            appearance.backgroundColor = UIColor(Color.appBackground)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            
            // Set the navigation bar appearance
            let navAppearance = UINavigationBarAppearance()
            navAppearance.backgroundColor = UIColor(Color.appBackground)
            UINavigationBar.appearance().standardAppearance = navAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        }
    }
}

#Preview {
   LibrarianInitialView()
        .environmentObject(AppState())
}

