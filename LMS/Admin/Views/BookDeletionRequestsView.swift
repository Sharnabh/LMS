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
    @State private var selectedRequestForDetails: BookDeletionRequest?
    @State private var showingBookDetails = false
    
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
                .onTapGesture {
                    selectedRequestForDetails = request
                    showingBookDetails = true
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
        .fullScreenCover(isPresented: $showingBookDetails) {
            if let request = selectedRequestForDetails {
                BookDeletionDetailsView(request: request)
            }
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

struct BookDeletionDetailsView: View {
    let request: BookDeletionRequest
    @EnvironmentObject private var bookStore: AdminBookStore
    @Environment(\.dismiss) private var dismiss
    @State private var books: [LibrarianBook] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading book details...")
                } else if let error = errorMessage {
                    VStack {
                        Text(error)
                            .foregroundColor(.red)
                        Button("Retry") {
                            Task {
                                await loadBooks()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                } else if books.isEmpty {
                    ContentUnavailableView(
                        "No Books Found",
                        systemImage: "book.closed",
                        description: Text("Could not find details for the requested books.")
                    )
                } else {
                    List(books) { book in
                        BookDetailCard(book: book)
                    }
                }
            }
            .navigationTitle("Books to Delete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .interactiveDismissDisabled()
        .task(id: request.id) {
            await loadBooks()
        }
    }
    
    private func loadBooks() async {
        isLoading = true
        errorMessage = nil
        books = []
        
        do {
            var loadedBooks: [LibrarianBook] = []
            for bookId in request.bookIDs {
                if let book = try await bookStore.dataController.fetchBook(by: bookId) {
                    loadedBooks.append(book)
                }
            }
            
            await MainActor.run {
                self.books = loadedBooks
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load book details: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

struct BookDetailCard: View {
    let book: LibrarianBook
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(book.title)
                    .font(.headline)
                Spacer()
                if let imageLink = book.imageLink {
                    AsyncImage(url: URL(string: imageLink)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .frame(width: 60, height: 80)
                    .cornerRadius(4)
                }
            }
            
            Text("Authors: \(book.author.joined(separator: ", "))")
                .font(.subheadline)
            
            HStack {
                Text("Genre: \(book.genre)")
                Spacer()
                Text("ISBN: \(book.ISBN)")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            if let description = book.Description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            HStack {
                Text("Publication Date: \(book.publicationDate)")
                Spacer()
                Text("Copies: \(book.totalCopies)")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
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