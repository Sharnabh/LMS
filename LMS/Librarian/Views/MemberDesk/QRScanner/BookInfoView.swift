import SwiftUI

// Rename to avoid conflicts with VoiceCommandBookIssueView
struct BookIssueData: Codable {
    let id: String
    let memberId: String
    let bookId: String
    let issueDate: String
    let dueDate: String
    let returnDate: String?
    let fine: Double
    let status: String
}

struct BookUpdateData: Codable {
    let availableCopies: Int
}

struct BookInfoView: View {
    let bookInfo: BookInfo
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabaseController = SupabaseDataController()
    @EnvironmentObject private var accessibilityManager: AccessibilityManager
    @State private var member: MemberModel?
    @State private var books: [LibrarianBook] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("Loading book information")
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .accessibilityLabel("Error: \(error)")
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
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Member information: \(member.firstName ?? "Unknown") \(member.lastName ?? "")")
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
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel("Book: \(book.title) by \(book.author.joined(separator: ", "))")
                            }
                        }
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Books to issue: \(books.count) books")
                    
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
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel("Issue details: Status \(bookInfo.issueStatus), Issue date \(bookInfo.issueDate), Return date \(bookInfo.returnDate)")
                    }
                    
                    // Approve Button
                    if bookInfo.issueStatus == "Pending" {
                        Button(action: {
                            Task {
                                await approveBookIssue()
                            }
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Approve Book Issue")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.top)
                        .disabled(isLoading)
                        .accessibilityLabel("Approve book issue")
                        .accessibilityHint("Double tap to approve issuing these books to the member")
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
            
            // Announce for accessibility when view is loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let bookCount = books.count
                let memberName = member?.firstName ?? "Unknown"
                UIAccessibility.post(notification: .announcement, argument: "Showing issue details for \(memberName). \(bookCount) books ready to issue. Say approve to complete the book issue.")
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(isSuccess ? "Success" : "Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if isSuccess {
                        dismiss()
                    }
                }
            )
        }
        .overlay {
            // Voice command button
            VStack {
                HStack {
                    Spacer()
                    VoiceCommandButton()
                        .padding(.top, 10)
                        .padding(.trailing, 20)
                }
                Spacer()
            }
        }
        .onChange(of: accessibilityManager.commandDetected) { oldValue, command in
            let lowercasedCommand = command.lowercased()
            
            // Handle voice commands
            if (lowercasedCommand.contains("approve") || 
                lowercasedCommand.contains("confirm") || 
                lowercasedCommand.contains("issue")) && 
                bookInfo.issueStatus == "Pending" && !isLoading {
                
                // Provide feedback
                UIAccessibility.post(notification: .announcement, argument: "Approving book issue...")
                
                // Execute approve action
                Task {
                    await approveBookIssue()
                }
            } else if lowercasedCommand.contains("cancel") || lowercasedCommand.contains("close") {
                dismiss()
            } else if lowercasedCommand.contains("read details") || lowercasedCommand.contains("information") {
                // Read out details for accessibility
                let bookNames = books.map { $0.title }.joined(separator: ", ")
                let memberName = member?.firstName ?? "Unknown"
                
                UIAccessibility.post(notification: .announcement, 
                    argument: "Issue for member \(memberName). Books: \(bookNames). Status: \(bookInfo.issueStatus). Say approve to issue the books or cancel to go back.")
            }
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
    
    private func approveBookIssue() async {
        guard !isLoading else { return }
        
        isLoading = true
        
        do {
            // Check if librarian is disabled
            if try await LibrarianService.checkLibrarianStatus() {
                await MainActor.run {
                    isSuccess = false
                    alertMessage = "Your account has been disabled. Please contact the administrator."
                    showAlert = true
                    isLoading = false
                    
                    // Announce for accessibility
                    UIAccessibility.post(notification: .announcement, argument: "Error: Your account has been disabled. Please contact the administrator.")
                }
                return
            }
            
            // Update BookIssue status in Supabase
            for bookId in bookInfo.bookIds {
                let bookIssue = BookIssueData(
                    id: UUID().uuidString,
                    memberId: bookInfo.memberId,
                    bookId: bookId,
                    issueDate: ISO8601DateFormatter().string(from: Date()),
                    dueDate: ISO8601DateFormatter().string(from: Date().addingTimeInterval(7 * 24 * 60 * 60)), // 7 days from now
                    returnDate: nil, // Will be updated when book is returned
                    fine: 0.0, // Initial fine is 0
                    status: "Issued"
                )
                
                let query = try supabaseController.client.from("BookIssue")
                    .insert(bookIssue)
                
                try await query.execute()
            }
            
            // Update book availability
            for bookId in bookInfo.bookIds {
                let bookQuery = supabaseController.client.from("Books")
                    .select()
                    .eq("id", value: bookId)
                
                let bookResponse = try await bookQuery.execute()
                let books = try JSONDecoder().decode([LibrarianBook].self, from: bookResponse.data)
                
                if let book = books.first {
                    let updatedBook = BookUpdateData(
                        availableCopies: book.availableCopies - 1
                    )
                    
                    let updateQuery = try supabaseController.client.from("Books")
                        .update(updatedBook)
                        .eq("id", value: bookId)
                    
                    try await updateQuery.execute()
                }
            }
            
            await MainActor.run {
                isSuccess = true
                alertMessage = "Book issue approved successfully"
                showAlert = true
                isLoading = false
                
                // Announce for accessibility
                UIAccessibility.post(notification: .announcement, argument: "Books have been successfully issued to the member.")
            }
        } catch {
            await MainActor.run {
                isSuccess = false
                alertMessage = "Failed to approve book issue: \(error.localizedDescription)"
                showAlert = true
                isLoading = false
                
                // Announce error for accessibility
                UIAccessibility.post(notification: .announcement, argument: "Failed to issue books. \(error.localizedDescription)")
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
