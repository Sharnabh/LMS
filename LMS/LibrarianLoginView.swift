import SwiftUI

struct LibrarianLoginView: View {
    @State private var librarianID = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Binding var showMainApp: Bool
    @Binding var selectedRole: UserRole?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 30) {
            // Header with back button
            HStack {
                Spacer()
            }
            
            // Header
            VStack(spacing: 16) {
                Image(systemName: "person.text.rectangle")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Librarian Login")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Enter your credentials to access the librarian dashboard")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 20)
            
            Spacer()
            
            // Login Form
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Librarian ID")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter your librarian ID", text: $librarianID)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .autocapitalization(.none)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    SecureField("Enter your password", text: $password)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Login button
            Button(action: {
                // Since we don't need authentication, directly show main app
                withAnimation {
                    showMainApp = true
                }
            }) {
                Text("Login")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarBackButtonHidden(false)
    }
}

#Preview {
    LibrarianLoginView(showMainApp: .constant(false), selectedRole: .constant(nil))
}
