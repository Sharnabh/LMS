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
    @StateObject private var dataController = SupabaseDataController()
    @State private var showDisabledAlert = false
    @AppStorage("librarianIsLoggedIn") private var librarianIsLoggedIn = false
    @AppStorage("librarianEmail") private var librarianEmail = ""
    
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
        .accentColor(.accentColor)
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
            
            // Check librarian status
            Task {
                await checkLibrarianStatus()
            }
        }
        .alert("Account Disabled", isPresented: $showDisabledAlert) {
            Button("OK") {
                // Logout the librarian
                librarianIsLoggedIn = false
                librarianEmail = ""
                appState.resetToFirstScreen()
            }
        } message: {
            Text("Your account has been disabled. Please contact the administrator for assistance.")
        }
    }
    
    private func checkLibrarianStatus() async {
        if let librarianId = UserDefaults.standard.string(forKey: "currentLibrarianID") {
            do {
                let isDisabled = try await dataController.checkLibrarianStatus(librarianId: librarianId)
                if isDisabled {
                    await MainActor.run {
                        showDisabledAlert = true
                    }
                }
            } catch {
                print("Error checking librarian status: \(error)")
            }
        }
    }
}

#Preview {
   LibrarianInitialView()
        .environmentObject(AppState())
}

