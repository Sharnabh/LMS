import SwiftUI

struct AdminSignupView: View {
    @StateObject private var viewModel = AdminSignupViewModel()
    @State private var navigateToLogin = false
    
    var body: some View {