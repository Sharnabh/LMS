import SwiftUI

struct MemberDetailView: View {
    let member: MemberModel
    @StateObject private var supabaseController = SupabaseDataController()
    @State private var issuedBooks: [IssuedBook] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    struct IssuedBook: Identifiable {
        let id: String
        let bookId: String
        let issueDate: String
        let dueDate: String
        let returnDate: String?
        let fine: Double
        let status: String
        let book: LibrarianBook?
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Member Info Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
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
            }
            .padding()
        }
        .navigationTitle("Member Details")
        .task {
            await fetchIssuedBooks()
        }
    }
    
    private func fetchIssuedBooks() async {
        guard let memberId = member.id else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch all book issues for this member
            let query = supabaseController.client.from("BookIssue")
                .select()
                .eq("memberId", value: memberId)
            
            let response = try await query.execute()
            
            struct BookIssue: Codable {
                let id: String
                let memberId: String
                let bookId: String
                let issueDate: String
                let dueDate: String
                let returnDate: String?
                let fine: Double
                let status: String
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let bookIssues = try decoder.decode([BookIssue].self, from: response.data)
            
            // Fetch book details for each issued book
            var books: [IssuedBook] = []
            for issue in bookIssues {
                let bookQuery = supabaseController.client.from("Books")
                    .select()
                    .eq("id", value: issue.bookId)
                
                let bookResponse = try await bookQuery.execute()
                let book = try? decoder.decode([LibrarianBook].self, from: bookResponse.data).first
                
                books.append(IssuedBook(
                    id: issue.id,
                    bookId: issue.bookId,
                    issueDate: issue.issueDate,
                    dueDate: issue.dueDate,
                    returnDate: issue.returnDate,
                    fine: issue.fine,
                    status: issue.status,
                    book: book
                ))
            }
            
            await MainActor.run {
                self.issuedBooks = books
                isLoading = false
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to fetch issued books: \(error.localizedDescription)"
                isLoading = false
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
                        Text(bookDetails.title)
                            .font(.headline)
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
                        
                        if book.fine > 0 {
                            Text("Fine: ₹\(String(format: "%.2f", book.fine))")
                                .font(.subheadline)
                                .foregroundColor(.red)
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