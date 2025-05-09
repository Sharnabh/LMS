import SwiftUI

struct BookDeletionRequestsView: View {
    @EnvironmentObject private var bookStore: AdminBookStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingRejectionDialog = false
    @State private var selectedRequest: BookDeletionRequest?
    @State private var rejectionReason = ""
    @State private var isProcessing = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var showIssuedBooksWarning = false
    @State private var issuedBooksCount = 0
    @State private var issuedBookIds: [UUID] = []
    @State private var alertMessage = ""
    @State private var selectedRequestForDetails: BookDeletionRequest?
    @State private var showingBookDetails = false
    @State private var selectedFilter: FilterType = .pending
    
    enum FilterType: String, CaseIterable {
        case pending = "Pending"
        case approved = "Approved" 
        case rejected = "Rejected"
        
        var statusFilter: String {
            switch self {
            case .pending: return "pending"
            case .approved: return "approved"
            case .rejected: return "rejected"
            }
        }
    }
    
    var filteredRequests: [BookDeletionRequest] {
        switch selectedFilter {
        case .pending:
            return bookStore.deletionRequests
        case .approved, .rejected:
            return bookStore.deletionHistory.filter { $0.status == selectedFilter.statusFilter }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter picker
            Picker("Filter", selection: $selectedFilter) {
                ForEach(FilterType.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Request list
            List {
                ForEach(filteredRequests) { request in
                    if selectedFilter == .pending {
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
                        .contentShape(Rectangle())
                    } else {
                        HistoricalRequestCard(request: request)
                            .onTapGesture {
                                selectedRequestForDetails = request
                                showingBookDetails = true
                            }
                            .contentShape(Rectangle())
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
            }
            .listStyle(.plain)
            .overlay {
                if filteredRequests.isEmpty {
                    ContentUnavailableView(
                        "No \(selectedFilter.rawValue) Requests",
                        systemImage: "tray.fill",
                        description: Text("There are no \(selectedFilter.rawValue.lowercased()) book deletion requests to display.")
                    )
                }
            }
        }
        .navigationTitle("Deletion Requests")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
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
        .alert("Books Currently Issued", isPresented: $showIssuedBooksWarning) {
            Button("Cancel", role: .cancel) { }
            Button("Force Delete Anyway", role: .destructive) {
                forceApproval(for: selectedRequest, issuedBookIds: issuedBookIds)
            }
        } message: {
            Text("\(issuedBooksCount) books in this deletion request are currently issued to members. Deleting these books may affect current loans. Would you like to proceed anyway?")
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
        .sheet(isPresented: $showingBookDetails) {
            if let request = selectedRequestForDetails {
                BookDeletionDetailsView(request: request)
                    .environmentObject(bookStore)
                    .interactiveDismissDisabled()
                    .presentationDetents([.large, .medium])
                    .presentationDragIndicator(.visible)
            }
        }
        .onAppear {
            print("📋 BookDeletionRequestsView appeared - fetching deletion requests")
            bookStore.fetchDeletionRequests()
            bookStore.fetchDeletionHistory()
        }
    }
    
    private func handleApproval(for request: BookDeletionRequest) {
        isProcessing = true
        selectedRequest = request
        
        Task {
            do {
                let success = try await bookStore.approveDeletionRequest(request)
                
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
            } catch let error as AdminBookStore.BookDeletionError {
                await MainActor.run {
                    isProcessing = false
                    
                    switch error {
                    case .booksCurrentlyIssued(let bookIds):
                        issuedBookIds = bookIds
                        issuedBooksCount = bookIds.count
                        showIssuedBooksWarning = true
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    alertMessage = "Failed to approve request: \(error.localizedDescription)"
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
    
    private func forceApproval(for request: BookDeletionRequest?, issuedBookIds: [UUID]) {
        guard let request = request else { return }
        
        isProcessing = true
        
        // Force delete despite issued books
        Task {
            do {
                // We're choosing to proceed with deletion despite issued books
                // In a real app, you might want to update the BookIssue records or notify users
                var allBooksDeleted = true
                
                // First try to delete all books
                for bookId in request.bookIDs {
                    if let book = try await bookStore.dataController.fetchBook(by: bookId) {
                        print("Force deleting book: \(book.title) (ID: \(bookId))")
                        let deleteSuccess = try await bookStore.dataController.deleteBook(book)
                        
                        if !deleteSuccess {
                            allBooksDeleted = false
                        }
                    } else {
                        allBooksDeleted = false
                    }
                }
                
                if allBooksDeleted {
                    let success = try await bookStore.dataController.updateDeletionRequestStatus(
                        requestId: request.id!,
                        status: "approved",
                        adminResponse: "Force deleted despite \(issuedBookIds.count) issued books"
                    )
                    
                    await MainActor.run {
                        isProcessing = false
                        if success {
                            bookStore.fetchDeletionRequests()
                            alertMessage = "Request force-approved and books marked as deleted despite being issued."
                            showSuccessAlert = true
                        } else {
                            alertMessage = "Failed to approve request. Please try again."
                            showErrorAlert = true
                        }
                    }
                } else {
                    await MainActor.run {
                        isProcessing = false
                        alertMessage = "Not all books could be deleted."
                        showErrorAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    alertMessage = "Error: \(error.localizedDescription)"
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
            
            HStack {
                Text("Tap to view book details")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
            
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

struct HistoricalRequestCard: View {
    let request: BookDeletionRequest
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
        NavigationStack {
            VStack {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView("Loading book details...")
                            .padding()
                        Text("Request ID: \(request.id?.uuidString ?? "unknown")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Error Loading Books")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(error)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Retry") {
                            Task {
                                await loadBooks()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else if books.isEmpty {
                    ContentUnavailableView(
                        "No Books Found",
                        systemImage: "book.closed",
                        description: Text("Could not find details for the books in this deletion request.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(books) { book in
                                BookDetailCard(book: book)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Books to Mark as Deleted")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("\(books.count) Books")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .onAppear {
                print("📚 BookDeletionDetailsView appeared for request: \(request.id?.uuidString ?? "unknown")")
                print("📚 Request contains \(request.bookIDs.count) book IDs")
            }
        }
        .task {
            print("📚 Starting task to load books")
            await loadBooks()
        }
    }
    
    private func loadBooks() async {
        isLoading = true
        errorMessage = nil
        books = []
        
//        do {
            print("📚 Loading books for deletion request: \(request.id?.uuidString ?? "unknown")")
            print("📚 Book IDs to load: \(request.bookIDs)")
            
            var loadedBooks: [LibrarianBook] = []
            for bookId in request.bookIDs {
                print("📚 Attempting to load book with ID: \(bookId)")
                do {
                    if let book = try await bookStore.dataController.fetchBookForDeletionRequest(by: bookId) {
                        print("📚 Successfully loaded book: \(book.title)")
                        loadedBooks.append(book)
                    } else {
                        print("📚 Book not found with ID: \(bookId)")
                    }
                } catch {
                    print("📚 Error loading book \(bookId): \(error.localizedDescription)")
                    // Continue loading other books even if one fails
                }
            }
            
            await MainActor.run {
                self.books = loadedBooks
                print("📚 Total books loaded: \(loadedBooks.count)")
                self.isLoading = false
            }
//        } catch {
//            print("📚 Error in loadBooks: \(error.localizedDescription)")
//            await MainActor.run {
//                self.errorMessage = "Failed to load book details: \(error.localizedDescription)"
//                self.isLoading = false
//            }
//        }
    }
}

struct BookDetailCard: View {
    let book: LibrarianBook
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    if let isDeleted = book.isDeleted, isDeleted {
                        Text("Already marked as deleted")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray)
                            )
                    } else {
                        Text("To be marked as deleted")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.red.opacity(0.1))
                            )
                    }
                }
                
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
                } else {
                    Image(systemName: "book.closed")
                        .font(.system(size: 40))
                        .frame(width: 60, height: 80)
                        .foregroundColor(.gray)
                        .background(Color.gray.opacity(0.1))
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
            
            if let description = book.Description, !description.isEmpty {
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
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)
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
