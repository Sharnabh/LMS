import Foundation
import Combine

class PasswordChangeViewModel: ObservableObject {
    @Published var currentPassword = ""
    @Published var newPassword = ""
    @Published var confirmPassword = ""
    @Published var errorMessage = ""
    @Published var isLoading = false
    @Published var isPasswordChanged = false
    
    var adminID: String
    
    private let adminService = AdminService()
    private var cancellables = Set<AnyCancellable>()
    
    init(adminID: String) {
        self.adminID = adminID
    }
    
    func changePassword() {
        guard !currentPassword.isEmpty, !newPassword.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "All fields are required"
            return
        }
        
        if newPassword != confirmPassword {
            errorMessage = "New passwords do not match"
            return
        }
        
        if newPassword.count < 8 {
            errorMessage = "Password must be at least 8 characters long"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        adminService.changePassword(adminID: adminID, currentPassword: currentPassword, newPassword: newPassword)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    switch error {
                    case .serverError(let message):
                        self?.errorMessage = message
                    default:
                        self?.errorMessage = "Failed to change password. Please try again."
                    }
                }
            }, receiveValue: { [weak self] response in
                self?.isPasswordChanged = true
                
                // Save token to UserDefaults or Keychain
                UserDefaults.standard.set(response.token, forKey: "adminToken")
            })
            .store(in: &cancellables)
    }
}