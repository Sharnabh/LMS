import SwiftUI

struct BookDeletionRequestsView: View {
    @EnvironmentObject private var bookStore: AdminBookStore
    @State private var showingRejectionDialog = false
    @State private var selectedRequest: BookDeletionRequest?
    @State private var rejectionReason = ""
    @State private var isProcessing = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        List {
            ForEach(bookStore.deletionRequests) { request in
                DeletionRequestCard(request: request) {
                    // Approve action
                    handleApproval(for: request)
                } onReject: {
                    // Show rejection dialog
                    selectedRequest = request
                    showingRejectionDialog = true
                }
            }
        }
        .navigationTitle("Deletion Requests")
        .overlay {
            if bookStore.deletionRequests.isEmpty {
                ContentUnavailableView(
                    "No Deletion Requests",
                    systemImage: "tray.fill",
                    description: Text("There are no pending deletion requests to review.")
                )
            }
            
            if isProcessing {
                ZStack {
                    Color.black.opacity(0.4)
                    VStack {
                        ProgressView()
                            .tint(.white)
                        Text("Processing...")
                            .foregroundColor(.white)
                            .padding(.top, 10)
                    }
                }
                .ignoresSafeArea()
            }
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingRejectionDialog) {
            NavigationView {
                Form {
                    Section(header: Text("Rejection Reason")) {
                        TextEditor(text: $rejectionReason)
                            .frame(height: 100)
                    }
                    
                    Section {
                        Button("Submit", action: submitRejection)
                            .disabled(rejectionReason.isEmpty)
                    }
                }
                .navigationTitle("Reject Request")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        showingRejectionDialog = false
                        rejectionReason = ""
                    }
                )
            }
            .presentationDetents([.medium])
        }
        .onAppear {
            bookStore.fetchDeletionRequests()
        }
    }
    
    private func handleApproval(for request: BookDeletionRequest) {
        isProcessing = true
        
        Task {
            let success = await bookStore.approveDeletionRequest(request)
            
            await MainActor.run {
                isProcessing = false
                if success {
                    alertMessage = "Request approved and books deleted successfully."
                    showSuccessAlert = true
                } else {
                    alertMessage = "Failed to approve request. Please try again."
                    showErrorAlert = true
                }
            }
        }
    }
    
    private func submitRejection() {
        guard let request = selectedRequest else { return }
        isProcessing = true
        showingRejectionDialog = false
        
        Task {
            let success = await bookStore.rejectDeletionRequest(request, reason: rejectionReason)
            
            await MainActor.run {
                isProcessing = false
                rejectionReason = ""
                
                if success {
                    alertMessage = "Request rejected successfully."
                    showSuccessAlert = true
                } else {
                    alertMessage = "Failed to reject request. Please try again."
                    showErrorAlert = true
                }
            }
        }
    }
}

struct DeletionRequestCard: View {
    let request: BookDeletionRequest
    let onApprove: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(request.bookIDs.count) Books")
                    .font(.headline)
                Spacer()
                StatusBadge(status: request.status)
            }
            
            Text("Requested by: \(request.requestedBy)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Date: \(request.requestDate.formatted())")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if request.status == "pending" {
                HStack(spacing: 12) {
                    Button(action: onApprove) {
                        Label("Approve", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: onReject) {
                        Label("Reject", systemImage: "xmark.circle.fill")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct StatusBadge: View {
    let status: String
    
    var body: some View {
        Text(status.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(.white)
            .clipShape(Capsule())
    }
    
    private var backgroundColor: Color {
        switch status {
        case "pending":
            return .orange
        case "approved":
            return .green
        case "rejected":
            return .red
        default:
            return .gray
        }
    }
}

#Preview {
    NavigationView {
        BookDeletionRequestsView()
            .environmentObject(AdminBookStore())
    }
} 