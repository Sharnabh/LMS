import SwiftUI

struct AddLibrarianView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataController = SupabaseDataController()
    @State private var librarianName = ""
    @State private var librarianEmail = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header Image
                    VStack(spacing: 16) {
                        Image(systemName: "person.badge.plus.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)
                        
                        Text("Add New Librarian")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Fill in the details to create a new librarian account")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Form Fields
                    VStack(spacing: 25) {
                        // Full Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.purple)
                                Text("Full Name")
                                    .font(.headline)
                            }
                            .foregroundColor(.secondary)
                            
                            TextField("Enter librarian's full name", text: $librarianName)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.purple)
                                Text("Email Address")
                                    .font(.headline)
                            }
                            .foregroundColor(.secondary)
                            
                            TextField("Enter librarian's email", text: $librarianEmail)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Add Librarian Button
                    Button(action: {
                        Task {
                            await addLibrarian()
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Add Librarian")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.purple)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Notification"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func addLibrarian() async {
        if librarianName.isEmpty || librarianEmail.isEmpty {
            alertMessage = "Please fill in all librarian details."
            showAlert = true
            return
        }
        
        isLoading = true
        
        do {
            _ = try await dataController.createLibrarian(
                name: librarianName,
                email: librarianEmail
            )
            
            DispatchQueue.main.async {
                isLoading = false
                alertMessage = "Librarian added successfully! A welcome email has been sent with login credentials."
                showAlert = true
                
                // Clear fields after successful addition
                librarianName = ""
                librarianEmail = ""
                
                // Dismiss the sheet
                dismiss()
            }
        } catch {
            DispatchQueue.main.async {
                isLoading = false
                alertMessage = "Error adding librarian: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}

#Preview {
    AddLibrarianView()
} 