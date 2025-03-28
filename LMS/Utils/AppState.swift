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
    
    func resetToFirstScreen() {
        showMainApp = false
        showAdminLogin = false
        showLibrarianApp = false
        selectedRole = nil
    }
} 