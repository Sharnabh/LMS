//
//  LMSApp.swift
//  LMS
//
//  Created by Sharnabh on 17/03/25.
//

import SwiftUI

@main
struct LMSApp: App {
    @StateObject private var appState = AppState()
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false
    @AppStorage("adminIsLoggedIn") private var adminIsLoggedIn = false
    @AppStorage("studentIsLoggedIn") private var studentIsLoggedIn = false
    @AppStorage("librarianIsLoggedIn") private var librarianIsLoggedIn = false
    
    var body: some Scene {
        WindowGroup {
            if !hasLaunchedBefore {
                WelcomeScreenView()
                    .environmentObject(appState)
                    .onAppear {
                        // Set hasLaunchedBefore to true so it only shows once
                        hasLaunchedBefore = true
                    }
            } else if adminIsLoggedIn {
                MainAppView(userRole: .admin, initialTab: 0)
                    .environmentObject(appState)
            } else if librarianIsLoggedIn {
                MainAppView(userRole: .librarian, initialTab: 0)
                    .environmentObject(appState)
            } else if studentIsLoggedIn {
                MainAppView(userRole: .member, initialTab: 0)
                    .environmentObject(appState)
            } else {
                // User is not logged in, show login screen
                WelcomeScreenView()
                    .environmentObject(appState)
            }
        }
    }
}
