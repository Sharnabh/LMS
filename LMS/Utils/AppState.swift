import SwiftUI

// Import the UserRole enum from ContentView
enum UserRole: String {
    case admin = "Admin"
    case librarian = "Librarian"
    case member = "Member"
}

class AppState: ObservableObject {
    @Published var selectedRole: UserRole?
    @Published var showMainApp = false
    @Published var showAdminLogin = false
    @Published var showLibrarianApp = false
    
    // For ISBN scanning from widget and navigation
    @Published var isbnToProcess: String = ""
    @Published var shouldNavigateToAddBooks = false
    @Published var scannedBook: LibrarianBook? = nil
    
    func resetToFirstScreen() {
        // Clear navigation state
        showMainApp = false
        showAdminLogin = false
        showLibrarianApp = false
        
        // Clear role selection
        selectedRole = nil
        
        // Clear ISBN and book data
        isbnToProcess = ""
        shouldNavigateToAddBooks = false
        scannedBook = nil
    }
} 