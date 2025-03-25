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
                    Image(systemName: "plus.app")
                        .imageScale(.large)
                    Text("Add Books")
                        
                }

//            ProfileView()
//                .tabItem {
//                    Image(systemName: "person.fill")
//                    Text("Profile")
//                }
        }
        .environmentObject(bookStore)
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
}

