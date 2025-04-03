//
//  LostBookView.swift
//  LMS
//
//  Created by Sharnabh on 03/04/25.
//

import SwiftUI

struct LostBookResponse: Codable {
    let id: String
    let memberId: String
    let bookId: String
    let issueDate: String
    let dueDate: String
    let returnDate: String?
    let fine: Double
    let status: String
    let isLost: Bool
    let isPaid: Bool
    let book: LibrarianBook?
    let member: MemberModel?
    
    enum CodingKeys: String, CodingKey {
        case id, memberId, bookId, issueDate, dueDate, returnDate, fine, status
        case isLost = "is_lost"
        case isPaid = "is_paid"
        case book = "Books"
        case member = "Member"
    }
}

struct LostBookView: View {
    @StateObject private var supabaseController = SupabaseDataController()
    @State private var lostBooks: [LostBookResponse] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isProcessing = false
    @State private var processingBookId: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .padding()
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else if lostBooks.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("No Lost Books")
                            .font(.title2.bold())
                        
                        Text("There are currently no books marked as lost.")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 50)
                } else {
                    ForEach(lostBooks, id: \.id) { lostBook in
                        LostBookCard(
                            lostBook: lostBook, 
                            isProcessing: processingBookId == lostBook.id,
                            onAccept: { handleAcceptLostBook(lostBook) }
                        )
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Lost Books")
        .onAppear {
            Task {
                await fetchLostBooks()
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertMessage.contains("Success") ? "Success" : "Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if alertMessage.contains("Success") {
                        Task {
                            await fetchLostBooks() // Refresh the list
                        }
                    }
                }
            )
        }
    }
    
    private func fetchLostBooks() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch all book issues that are marked as lost
            let query = supabaseController.client.from("BookIssue")
                .select("""
                    id,
                    memberId,
                    bookId,
                    issueDate,
                    dueDate,
                    returnDate,
                    fine,
                    status,
                    is_lost,
                    is_paid,
                    Books (
                        id,
                        title,
                        author,
                        genre,
                        publicationDate,
                        totalCopies,
                        availableCopies,
                        ISBN,
                        Description,
                        shelfLocation,
                        publisher,
                        imageLink
                    ),
                    Member (
                        id,
                        firstName,
                        lastName,
                        email,
                        enrollmentNumber
                    )
                """)
                .eq("is_lost", value: true)
            
            let response = try await query.execute()
            let decoder = JSONDecoder()
            
            lostBooks = try decoder.decode([LostBookResponse].self, from: response.data)
            isLoading = false
        } catch {
            print("Error fetching lost books: \(error)")
            errorMessage = "Failed to load lost books: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    private func handleAcceptLostBook(_ lostBook: LostBookResponse) {
        guard !lostBook.isPaid else {
            alertMessage = "This fine has already been paid."
            showAlert = true
            return
        }
        
        processingBookId = lostBook.id
        isProcessing = true
        
        Task {
            do {
                // Check if librarian is disabled
                if try await LibrarianService.checkLibrarianStatus() {
                    await MainActor.run {
                        alertMessage = "Your account has been disabled. Please contact the administrator."
                        showAlert = true
                        isProcessing = false
                        processingBookId = nil
                    }
                    return
                }
                
                // 1. Get the lost book fine from library_policies
                let libraryPolicies = try await supabaseController.fetchLibraryPolicies()
                let lostBookFine = Double(libraryPolicies.lostBookFine)
                
                // 2. Update the member's fine (set to 0)
                guard let memberId = lostBook.member?.id else {
                    throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Member ID not found"])
                }
                
                // Update member's fine
                try await supabaseController.client.from("Member")
                    .update(["fine": 0])
                    .eq("id", value: memberId)
                    .execute()
                
                // 3. Update the BookIssue record to mark it as paid
                try await supabaseController.client.from("BookIssue")
                    .update(["is_paid": true])
                    .eq("id", value: lostBook.id)
                    .execute()
                
                // 4. Show success message
                await MainActor.run {
                    alertMessage = "Success! Lost book fine of ₹\(lostBookFine) has been added to member's account."
                    showAlert = true
                    isProcessing = false
                    processingBookId = nil
                }
                
            } catch {
                await MainActor.run {
                    alertMessage = "Error processing lost book: \(error.localizedDescription)"
                    showAlert = true
                    isProcessing = false
                    processingBookId = nil
                }
            }
        }
    }
}

struct LostBookCard: View {
    let lostBook: LostBookResponse
    let isProcessing: Bool
    let onAccept: () -> Void
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Book and Member Info Header
            HStack(alignment: .center) {
                // Book Cover
                if let imageLink = lostBook.book?.imageLink, !imageLink.isEmpty,
                   let url = URL(string: imageLink) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 70, height: 100)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 70, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        case .failure:
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 70, height: 100)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 70, height: 100)
                        .overlay(
                            Image(systemName: "book.closed")
                                .foregroundColor(.orange)
                        )
                }
                
                // Book and Member Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(lostBook.book?.title ?? "Unknown Book")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    if let authors = lostBook.book?.author, !authors.isEmpty {
                        Text(authors.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer(minLength: 8)
                    
                    HStack {
                        Label {
                            Text(lostBook.isPaid ? "Paid" : "Lost")
                                .font(.caption)
                        } icon: {
                            Image(systemName: lostBook.isPaid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        }
                        .foregroundColor(lostBook.isPaid ? .green : .red)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 8)
                        .background(Color(lostBook.isPaid ? .green : .red).opacity(0.1))
                        .clipShape(Capsule())
                        
                        Spacer()
                        
                        Text("₹\(lostBook.fine, specifier: "%.2f")")
                            .font(.callout.bold())
                            .foregroundColor(.red)
                    }
                }
                .padding(.leading, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Details section (expandable)
            if showDetails {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                    
                    // Member Information
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Member Details")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(lostBook.member?.firstName ?? "") \(lostBook.member?.lastName ?? "")")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                if let enrollment = lostBook.member?.enrollmentNumber, !enrollment.isEmpty {
                                    Text(enrollment)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if let email = lostBook.member?.email, !email.isEmpty {
                                    Text(email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Issue Details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Issue Information")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Issue Date")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(formatDate(lostBook.issueDate))
                                    .font(.caption2)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading) {
                                Text("Due Date")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(formatDate(lostBook.dueDate))
                                    .font(.caption2)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading) {
                                Text("Lost Fine")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("₹\(lostBook.fine, specifier: "%.2f")")
                                    .font(.caption2.bold())
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Book details like ISBN, etc.
                    if let book = lostBook.book {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Book Details")
                                .font(.subheadline.bold())
                                .foregroundColor(.secondary)
                            
                            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 4) {
                                GridRow {
                                    Text("ISBN")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(book.ISBN)
                                        .font(.caption2)
                                }
                                
                                GridRow {
                                    Text("Genre")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(book.genre)
                                        .font(.caption2)
                                }
                                
                                if let publisher = book.publisher, !publisher.isEmpty {
                                    GridRow {
                                        Text("Publisher")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(publisher)
                                            .font(.caption2)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()
                    
                    HStack {
                        Spacer()
                        
                        Button(action: onAccept) {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Label("Accept", systemImage: lostBook.isPaid ? "checkmark.circle.fill" : "creditcard.fill")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(lostBook.isPaid ? .gray : .blue)
                        .disabled(lostBook.isPaid || isProcessing)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.secondarySystemBackground))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                showDetails.toggle()
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func formatDate(_ dateString: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: dateString) else {
            return dateString
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

#Preview("Lost Books List") {
    NavigationView {
        LostBookView()
    }
    .onAppear {
        // In a real scenario, this would be loaded from the database
    }
}
