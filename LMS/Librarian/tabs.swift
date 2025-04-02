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
    @EnvironmentObject private var accessibilityManager: AccessibilityManager
    @StateObject private var dataController = SupabaseDataController()
    @State private var showDisabledAlert = false
    @AppStorage("librarianIsLoggedIn") private var librarianIsLoggedIn = false
    @AppStorage("librarianEmail") private var librarianEmail = ""
    
    // Voice command related states
    @State private var showIsbnScanner = false
    @State private var showBookIssue = false
    @State private var showQRScanner = false
    
    // Tab selection state
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeLibrarianView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(0)
                
                IssueHistoryView()
                    .tabItem {
                        Image(systemName: "person.crop.rectangle.stack.fill")
                        Text("Member Desk")
                    }
                    .tag(1)

                AddView()
                    .tabItem {
                        Image(systemName: "book")
                            .imageScale(.large)
                        Text("Add Books")
                    }
                    .tag(2)
                
                ShelfLocationsView()
                    .tabItem {
                        Image(systemName: "mappin.and.ellipse")
                        Text("Book Shelf")
                    }
                    .tag(3)
            }
            .environmentObject(bookStore)
            .environmentObject(appState)
            .accentColor(.blue)
            
            // Voice command button overlay - always visible
            VStack {
                HStack {
                    Spacer()
                    VoiceCommandButton()
                        .padding(.top, 60)
                        .padding(.trailing, 20)
                }
                Spacer()
            }
            .ignoresSafeArea(.keyboard)
        }
        .sheet(isPresented: $showIsbnScanner) {
            ISBNScannerWrapper { code in
                print("Scanned ISBN: \(code)")
                // Handle the scanned code
                Task {
                    await handleScannedISBN(code)
                }
            }
            .environmentObject(accessibilityManager)
        }
        .sheet(isPresented: $showBookIssue) {
            QRScanner(isPresentedAsFullScreen: false)
                .environmentObject(accessibilityManager)
        }
        .sheet(isPresented: $showQRScanner) {
            QRScanner(isPresentedAsFullScreen: false)
                .environmentObject(accessibilityManager)
        }
        .onChange(of: accessibilityManager.shouldScanISBN) { newValue in
            if newValue {
                showIsbnScanner = true
                accessibilityManager.resetCommands()
            }
        }
        .onChange(of: accessibilityManager.shouldIssueBook) { newValue in
            if newValue {
                showQRScanner = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    UIAccessibility.post(notification: .announcement, argument: "Opening QR scanner for book issue. Please scan member's QR code.")
                }
                
                accessibilityManager.resetCommands()
            }
        }
        .onChange(of: appState.shouldNavigateToAddBooks) { _, shouldNavigate in
            if shouldNavigate {
                print("LibrarianInitialView: Navigating to Add Books tab")
                
                // Navigate to Add Books tab
                withAnimation {
                    selectedTab = 2
                }
                
                // Reset the navigation flag after a short delay to avoid race conditions
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    appState.shouldNavigateToAddBooks = false
                }
            }
        }
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
            
            // Announce voice command availability
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                UIAccessibility.post(notification: .announcement, argument: "Voice commands available for ISBN scanning and book issuing. Tap the microphone button in the top right corner to activate.")
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
    
    // Add function to handle scanned ISBN
    private func handleScannedISBN(_ isbn: String) async {
        print("Processing scanned ISBN in LibrarianInitialView: \(isbn)")
        
        // Create a temporary BookStore to handle the book addition
        let bookStore = BookStore()
        
        do {
            // First, fetch the book details from Google Books API
            let fetchedBook = try await GoogleBooksService.fetchBookByISBN(isbn: isbn)
            
            // Set default copies to 1 for scanned books
            var bookToAdd = fetchedBook
            bookToAdd.totalCopies = 1
            bookToAdd.availableCopies = 1
            
            // Add the book to Supabase
            print("Adding book to Supabase: \(bookToAdd.title) by librarian: \(librarianEmail)")
            bookStore.addBook(bookToAdd)
            
            // Show success feedback to user
            UIAccessibility.post(notification: .announcement, argument: "Book added successfully: \(bookToAdd.title)")
        } catch {
            print("Error processing ISBN: \(error)")
            UIAccessibility.post(notification: .announcement, argument: "Error: Could not find book with ISBN \(isbn)")
        }
    }
}

#Preview {
   LibrarianInitialView()
        .environmentObject(AppState())
        .environmentObject(AccessibilityManager())
}

