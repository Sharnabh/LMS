import SwiftUI

struct MemberDetailView: View {
    let member: MemberModel
    @StateObject private var supabaseController = SupabaseDataController()
    @State private var issuedBooks: [IssuedBook] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var totalFine: Double = 0.0
    @State private var pendingFine: Double = 0.0
    @State private var isCollectingFine = false
    
    struct IssuedBook: Identifiable {
        let id: String
        let bookId: String
        let issueDate: String
        let dueDate: String
        let returnDate: String?
        let fine: Double
        let status: String
        let book: LibrarianBook?
        var isPaid: Bool
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Member Info Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(member.firstName ?? "Unknown") \(member.lastName ?? "")")
                                .font(.title2)
                                .bold()
                            if let email = member.email {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            if let enrollmentNumber = member.enrollmentNumber {
                                Text("Enrollment: \(enrollmentNumber)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Display total fine and pending fine
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Fine Collected: ₹\(String(format: "%.2f", totalFine))")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                
                                if pendingFine > 0 {
                                    Text("Fine Pending: ₹\(String(format: "%.2f", pendingFine))")
                                        .font(.headline)
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                }
                
                // Issued Books Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Issued Books")
                        .font(.title3)
                        .bold()
                        .padding(.horizontal)
                    
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    } else if issuedBooks.isEmpty {
                        Text("No books currently issued")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(issuedBooks) { book in
                            IssuedBookRow(book: book)
                        }
                    }
                }
                
                // Add button at the bottom - only show if there's an unpaid fine
                if pendingFine > 0 {
                    Button(action: {
                        Task {
                            await collectFine()
                        }
                    }) {
                        if isCollectingFine {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Collect Fine")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.top, 20)
                    .padding(.horizontal)
                    .disabled(isCollectingFine)
                }
            }
            .padding()
        }
        .navigationTitle("Member Details")
        .task {
            await fetchIssuedBooks()
        }
    }
    
    private func collectFine() async {
        guard let memberId = member.id, pendingFine > 0 else { return }
        
        isCollectingFine = true
        
        do {
            // Step 1: Update each unpaid book issue to mark it as paid
            for book in issuedBooks where book.fine > 0 && !book.isPaid {
                let updateQuery = try supabaseController.client.from("BookIssue")
                    .update(["is_paid": true])
                    .eq("id", value: book.id)
                
                try await updateQuery.execute()
            }
            
            // Step 2: Update member's fine to 0
            let memberUpdateQuery = try supabaseController.client.from("Member")
                .update(["fine": 0])
                .eq("id", value: memberId)
            
            try await memberUpdateQuery.execute()
            
            // Step 3: Update UI state immediately
            await MainActor.run {
                // Update issuedBooks to mark all as paid
                self.issuedBooks = self.issuedBooks.map { book in
                    var updatedBook = book
                    if !book.isPaid {
                        updatedBook.isPaid = true
                    }
                    return updatedBook
                }
                self.pendingFine = 0
                isCollectingFine = false
            }
            
            // Step 4: Refresh the data from server
            await fetchIssuedBooks()
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to collect fine: \(error.localizedDescription)"
                isCollectingFine = false
            }
        }
    }
    
    private func fetchIssuedBooks() async {
        guard let memberId = member.id else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch all book issues for this member
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
                        imageLink,
                        is_deleted
                    )
                """)
                .eq("memberId", value: memberId)
            
            let response = try await query.execute()
            
            // Print response for debugging
            print("BookIssue Response: \(response.data)")
            
            struct BookIssue: Codable {
                let id: String
                let memberId: String
                let bookId: String
                let issueDate: String
                let dueDate: String
                let returnDate: String?
                let fine: Double
                let status: String
                let isPaid: Bool
                let book: LibrarianBook?
                
                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    id = try container.decode(String.self, forKey: .id)
                    memberId = try container.decode(String.self, forKey: .memberId)
                    bookId = try container.decode(String.self, forKey: .bookId)
                    issueDate = try container.decode(String.self, forKey: .issueDate)
                    dueDate = try container.decode(String.self, forKey: .dueDate)
                    returnDate = try container.decodeIfPresent(String.self, forKey: .returnDate)
                    fine = try container.decode(Double.self, forKey: .fine)
                    status = try container.decode(String.self, forKey: .status)
                    
                    // Try to decode is_paid with both possible keys
                    if let isPaidValue = try? container.decode(Bool.self, forKey: .isPaid) {
                        isPaid = isPaidValue
                    } else if let isPaidValue = try? container.decode(Bool.self, forKey: .isPaidSnakeCase) {
                        isPaid = isPaidValue
                    } else {
                        // If neither key is found, use the default value from the database
                        isPaid = true
                    }
                    
                    print("Decoded is_paid value: \(isPaid) for book issue \(id)")
                    book = try container.decodeIfPresent(LibrarianBook.self, forKey: .book)
                }
                
                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                    try container.encode(memberId, forKey: .memberId)
                    try container.encode(bookId, forKey: .bookId)
                    try container.encode(issueDate, forKey: .issueDate)
                    try container.encode(dueDate, forKey: .dueDate)
                    try container.encodeIfPresent(returnDate, forKey: .returnDate)
                    try container.encode(fine, forKey: .fine)
                    try container.encode(status, forKey: .status)
                    try container.encode(isPaid, forKey: .isPaidSnakeCase)
                    try container.encodeIfPresent(book, forKey: .book)
                }
                
                enum CodingKeys: String, CodingKey {
                    case id, memberId, bookId, issueDate, dueDate, returnDate, fine, status
                    case isPaid
                    case isPaidSnakeCase = "is_paid"
                    case book = "Books"
                }
            }
            
            let decoder = JSONDecoder()
            // Remove the keyDecodingStrategy since we're handling the keys manually
            // decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            // Print the raw response data for debugging
            if let jsonString = String(data: response.data, encoding: .utf8) {
                print("Raw JSON response: \(jsonString)")
            }
            
            let bookIssues = try decoder.decode([BookIssue].self, from: response.data)
            print("Decoded BookIssues: \(bookIssues)")
            
            // Calculate total fine and pending fine
            var totalFineAmount: Double = 0.0
            var pendingFineAmount: Double = 0.0
            
            // Create IssuedBook array from book issues
            let books = bookIssues.map { issue in
                // Add paid fines to total collected
                if issue.isPaid {
                    totalFineAmount += issue.fine
                }
                
                // Add unpaid fines to pending total
                if !issue.isPaid {
                    pendingFineAmount += issue.fine
                }
                
                let issuedBook = IssuedBook(
                    id: issue.id,
                    bookId: issue.bookId,
                    issueDate: issue.issueDate,
                    dueDate: issue.dueDate,
                    returnDate: issue.returnDate,
                    fine: issue.fine,
                    status: issue.status,
                    book: issue.book,
                    isPaid: issue.isPaid
                )
                print("Created IssuedBook with isPaid: \(issuedBook.isPaid) for book \(issue.id)")
                return issuedBook
            }
            
            print("Final books array: \(books)")
            
            await MainActor.run {
                self.issuedBooks = books
                self.totalFine = totalFineAmount
                self.pendingFine = pendingFineAmount
                isLoading = false
                isCollectingFine = false
            }
            
        } catch {
            print("Error in fetchIssuedBooks: \(error)")
            await MainActor.run {
                errorMessage = "Failed to fetch issued books: \(error.localizedDescription)"
                isLoading = false
                isCollectingFine = false
            }
        }
    }
}

struct IssuedBookRow: View {
    let book: MemberDetailView.IssuedBook
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let bookDetails = book.book {
                HStack(spacing: 12) {
                    // Book Image
                    if let imageLink = bookDetails.imageLink,
                       let url = URL(string: imageLink) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Image(systemName: "book.fill")
                                .foregroundColor(.gray)
                        }
                        .frame(width: 60, height: 80)
                        .cornerRadius(8)
                    } else {
                        Image(systemName: "book.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                            .frame(width: 60, height: 80)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(bookDetails.title)
                                .font(.headline)
                            Spacer()
                            Text(book.status)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(statusColor(for: book.status))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                        
                        Text(bookDetails.author.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Issue Date: \(book.issueDate)")
                                .font(.caption)
                            Spacer()
                            Text("Due Date: \(book.dueDate)")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        
                        if let returnDate = book.returnDate {
                            Text("Returned: \(returnDate)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if book.fine > 0 {
                            HStack {
                                Text("Fine: ₹\(String(format: "%.2f", book.fine))")
                                    .font(.subheadline)
                                    .foregroundColor(book.isPaid ? .green : .red)
                                
                                if book.isPaid {
                                    Text("(Paid)")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                } else {
                                    Text("(Unpaid)")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "issued":
            return .blue
        case "returned":
            return .green
        case "overdue":
            return .red
        default:
            return .gray
        }
    }
}

#Preview {
    NavigationView {
        MemberDetailView(member: MemberModel(
            id: "1",
            firstName: "John",
            lastName: "Doe",
            email: "john@example.com",
            enrollmentNumber: "ENR001"
        ))
    }
}
