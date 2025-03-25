import SwiftUI

struct BookInfoView: View {
    let bookInfo: BookInfo
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabaseController = SupabaseDataController()
    @State private var member: MemberModel?
    @State private var books: [LibrarianBook] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    // Member Info Section
                    if let member = member {
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
                    }
                    
                    // Books Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Issued Books")
                            .font(.title3)
                            .bold()
                            .padding(.horizontal)
                        
                        if books.isEmpty {
                            Text("No books found")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(books) { book in
                                BookRow(book: book)
                            }
                        }
                    }
                    
                    // Issue Details Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Issue Details")
                            .font(.title3)
                            .bold()
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            DetailRow(label: "Status", value: bookInfo.issueStatus)
                            DetailRow(label: "Issue Date", value: bookInfo.issueDate)
                            DetailRow(label: "Return Date", value: bookInfo.returnDate)
                            DetailRow(label: "Valid Until", value: Date(timeIntervalSince1970: bookInfo.expirationDate).formatted())
                            DetailRow(label: "QR Generated", value: Date(timeIntervalSince1970: bookInfo.timestamp).formatted())
                            DetailRow(label: "Valid", value: bookInfo.isValid ? "Yes" : "No")
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("QR Code Details")
        .navigationBarItems(trailing: Button("Close") {
            dismiss()
        })
        .task {
            await fetchDetails()
        }
    }
    
    private func fetchDetails() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch member details
            let memberQuery = supabaseController.client.from("Member")
                .select()
                .eq("id", value: bookInfo.memberId)
            
            let memberResponse = try await memberQuery.execute()
            let members = try JSONDecoder().decode([MemberModel].self, from: memberResponse.data)
            member = members.first
            
            // Fetch book details
            var fetchedBooks: [LibrarianBook] = []
            for bookId in bookInfo.bookIds {
                let bookQuery = supabaseController.client.from("Books")
                    .select()
                    .eq("id", value: bookId)
                
                let bookResponse = try await bookQuery.execute()
                let books = try JSONDecoder().decode([LibrarianBook].self, from: bookResponse.data)
                if let book = books.first {
                    fetchedBooks.append(book)
                }
            }
            
            await MainActor.run {
                self.books = fetchedBooks
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to fetch details: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

struct BookRow: View {
    let book: LibrarianBook
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Book Image
                if let imageLink = book.imageLink,
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
                    Text(book.title)
                        .font(.headline)
                    Text(book.author.joined(separator: ", "))
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
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.headline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body)
        }
    }
}

#Preview {
    BookInfoView(bookInfo: BookInfo(
        bookIds: ["2506db6b-b427-4733-b8e7-b993dd3c5300"],
        memberId: "1f7cb028-b331-4050-8d46-40944e60ca09",
        issueStatus: "Issued",
        issueDate: "21-03-2025",
        returnDate: "30-03-2025",
        expirationDate: Date().timeIntervalSince1970 + 86400,
        timestamp: Date().timeIntervalSince1970,
        isValid: true
    ))
} 
