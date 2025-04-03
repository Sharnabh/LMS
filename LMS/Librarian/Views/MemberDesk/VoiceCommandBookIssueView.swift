//
//  VoiceCommandBookIssueView.swift
//  LMS
//
//  Created by Assistant on 01/04/25.
//

import SwiftUI

struct VoiceCommandBookIssueView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var accessibilityManager: AccessibilityManager
    @StateObject private var supabaseController = SupabaseDataController()
    
    @State private var step = 0
    @State private var memberId = ""
    @State private var bookIds: [String] = []
    @State private var memberName = ""
    @State private var bookTitles: [String] = []
    @State private var isProcessing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Information"
    @State private var isSuccess = false
    
    // Voice guidance states
    @State private var isListeningForMember = false
    @State private var isListeningForBook = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Step indicator
                HStack {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(step >= index ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                            .overlay(
                                step == index ? Circle().stroke(Color.blue, lineWidth: 2).scaleEffect(1.3) : nil
                            )
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.top)
                
                Spacer()
                
                // Content based on current step
                Group {
                    if step == 0 {
                        // Member selection step
                        memberSelectionView
                    } else if step == 1 {
                        // Book selection step
                        bookSelectionView
                    } else {
                        // Confirmation step
                        confirmationView
                    }
                }
                
                Spacer()
                
                // Navigation buttons
                HStack {
                    Button(action: {
                        if step > 0 {
                            step -= 1
                        } else {
                            dismiss()
                        }
                    }) {
                        Text(step > 0 ? "Back" : "Cancel")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .accessibilityHint(step > 0 ? "Go back to previous step" : "Cancel book issue process")
                    
                    Spacer()
                    
                    if step < 2 {
                        Button(action: {
                            nextStep()
                        }) {
                            Text("Next")
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(canProceed ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(!canProceed)
                        .accessibilityHint(canProceed ? "Proceed to next step" : "Please complete the current step")
                    } else {
                        Button(action: {
                            issueBooks()
                        }) {
                            Text("Issue Books")
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(isProcessing ? Color.gray : Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(isProcessing)
                        .accessibilityHint("Complete the book issue process")
                    }
                }
                .padding()
            }
            .overlay {
                // Voice command button always visible
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
            .padding()
            .navigationTitle("Issue Books")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                UIAccessibility.post(notification: .announcement, argument: "Voice-guided book issue process started. Say 'issue book to member' followed by the member ID to begin.")
            }
            .onChange(of: accessibilityManager.commandDetected) { oldValue, newValue in
                processVoiceCommand(newValue)
            }
            .onChange(of: accessibilityManager.shouldIssueBook) { oldValue, newValue in
                if newValue {
                    // Reset and start the issue process
                    step = 0
                    memberId = ""
                    bookIds = []
                    memberName = ""
                    bookTitles = []
                    accessibilityManager.resetCommands()
                    UIAccessibility.post(notification: .announcement, argument: "Book issue process started. Please scan or enter member ID.")
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if isSuccess {
                            dismiss()
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Subviews
    
    private var memberSelectionView: some View {
        VStack(spacing: 25) {
            Image(systemName: "person.badge.card")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Scan or Enter Member ID")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Use the scanner to scan member's QR code or say \"member ID\" followed by the member number")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            HStack {
                TextField("Member ID", text: $memberId)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .accessibilityLabel("Member ID input field")
                
                Button(action: {
                    // Validate and lookup member
                    Task {
                        await lookupMember()
                    }
                }) {
                    Image(systemName: "magnifyingglass")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .accessibilityLabel("Look up member")
            }
            
            if !memberName.isEmpty {
                HStack {
                    Text("Member: ")
                        .fontWeight(.medium)
                    Text(memberName)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                .padding(.vertical, 10)
                .padding(.horizontal)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Member identified as \(memberName)")
            }
            
            Button(action: {
                // Show scanner for member QR
                // This would integrate with your QR scanner
                // showMemberQRScanner = true
            }) {
                HStack {
                    Image(systemName: "qrcode.viewfinder")
                    Text("Scan Member QR")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
            }
            .accessibilityLabel("Scan member QR code")
        }
    }
    
    private var bookSelectionView: some View {
        VStack(spacing: 25) {
            Image(systemName: "books.vertical")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Scan or Enter Book IDs")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Use the scanner to scan book barcodes or say \"add book\" followed by the book ISBN")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            HStack {
                TextField("Book ISBN", text: Binding(
                    get: { "" },
                    set: { newValue in
                        if !newValue.isEmpty {
                            Task {
                                await lookupBook(isbn: newValue)
                            }
                        }
                    }
                ))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .accessibilityLabel("Book ISBN input field")
                
                Button(action: {
                    // Open book scanner
                    // showBookScanner = true
                }) {
                    Image(systemName: "barcode.viewfinder")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .accessibilityLabel("Scan book barcode")
            }
            
            if !bookTitles.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Books to Issue:")
                        .fontWeight(.medium)
                    
                    ForEach(0..<bookTitles.count, id: \.self) { index in
                        HStack {
                            Text("\(index + 1). \(bookTitles[index])")
                            Spacer()
                            Button(action: {
                                removeBook(at: index)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .accessibilityLabel("Remove \(bookTitles[index])")
                        }
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                .accessibilityElement(children: .contain)
            }
        }
    }
    
    private var confirmationView: some View {
        VStack(spacing: 25) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 50))
                .foregroundColor(.green)
            
            Text("Confirm Book Issue")
                .font(.title3)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Member:")
                        .fontWeight(.medium)
                    Text(memberName)
                        .padding(.leading)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Books to Issue:")
                        .fontWeight(.medium)
                    
                    ForEach(0..<bookTitles.count, id: \.self) { index in
                        Text("\(index + 1). \(bookTitles[index])")
                            .padding(.leading)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Due Date:")
                        .fontWeight(.medium)
                    Text(dueDateString)
                        .padding(.leading)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .accessibilityElement(children: .contain)
            
            if isProcessing {
                ProgressView("Issuing books...")
                    .padding()
            }
        }
    }
    
    // MARK: - Helper properties
    
    private var canProceed: Bool {
        if step == 0 {
            return !memberName.isEmpty
        } else if step == 1 {
            return !bookIds.isEmpty
        } else {
            return true
        }
    }
    
    private var dueDateString: String {
        let dueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dueDate)
    }
    
    // MARK: - Functions
    
    private func nextStep() {
        if step < 2 {
            step += 1
            
            // Announce the new step for accessibility
            let announcement: String
            if step == 1 {
                announcement = "Now scanning books. Please scan or enter book ISBNs."
            } else {
                announcement = "Please review and confirm book issue details."
            }
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
    }
    
    private func lookupMember() async {
        guard !memberId.isEmpty else { return }
        
        isProcessing = true
        
        do {
            // Query to fetch member from Supabase
            let query = supabaseController.client.from("Members")
                .select()
                .eq("id", value: memberId)
                .single()
            
            struct Member: Codable {
                let id: String
                let name: String
            }
            
            let member: Member = try await query.execute().value
            
            await MainActor.run {
                memberName = member.name
                isProcessing = false
                
                // Announce for accessibility
                UIAccessibility.post(notification: .announcement, argument: "Member found: \(member.name)")
            }
            
        } catch {
            await MainActor.run {
                isProcessing = false
                alertTitle = "Error"
                alertMessage = "Member not found. Please check the ID and try again."
                showAlert = true
            }
        }
    }
    
    private func lookupBook(isbn: String) async {
        isProcessing = true
        
        do {
            // Query to fetch book from Supabase
            let query = supabaseController.client.from("Books")
                .select()
                .eq("ISBN", value: isbn)
                .single()
            
            struct Book: Codable {
                let id: String
                let title: String
                let availableCopies: Int
            }
            
            let book: Book = try await query.execute().value
            
            await MainActor.run {
                if book.availableCopies > 0 {
                    if !bookIds.contains(book.id) {
                        bookIds.append(book.id)
                        bookTitles.append(book.title)
                        
                        // Announce for accessibility
                        UIAccessibility.post(notification: .announcement, argument: "Added book: \(book.title)")
                    } else {
                        alertTitle = "Duplicate Book"
                        alertMessage = "This book is already in your issue list."
                        showAlert = true
                    }
                } else {
                    alertTitle = "Book Unavailable"
                    alertMessage = "This book has no available copies for issue."
                    showAlert = true
                }
                isProcessing = false
            }
            
        } catch {
            await MainActor.run {
                isProcessing = false
                alertTitle = "Error"
                alertMessage = "Book not found. Please check the ISBN and try again."
                showAlert = true
            }
        }
    }
    
    private func removeBook(at index: Int) {
        guard index < bookIds.count else { return }
        
        let removedTitle = bookTitles[index]
        bookIds.remove(at: index)
        bookTitles.remove(at: index)
        
        // Announce for accessibility
        UIAccessibility.post(notification: .announcement, argument: "Removed book: \(removedTitle)")
    }
    
    private func issueBooks() {
        isProcessing = true
        
        Task {
            do {
                // Check if librarian is disabled
                if try await LibrarianService.checkLibrarianStatus() {
                    await MainActor.run {
                        isProcessing = false
                        isSuccess = false
                        alertTitle = "Error"
                        alertMessage = "Your account has been disabled. Please contact the administrator."
                        showAlert = true
                        
                        // Announce for accessibility
                        UIAccessibility.post(notification: .announcement, argument: "Error: Your account has been disabled. Please contact the administrator.")
                    }
                    return
                }
                
                // Issue each book to the member
                for bookId in bookIds {
                    let bookIssue = BookIssueData(
                        id: UUID().uuidString,
                        memberId: memberId,
                        bookId: bookId,
                        issueDate: ISO8601DateFormatter().string(from: Date()),
                        dueDate: ISO8601DateFormatter().string(from: Date().addingTimeInterval(7 * 24 * 60 * 60)), // 7 days
                        returnDate: nil,
                        fine: 0.0,
                        status: "Issued"
                    )
                    
                    let query = try supabaseController.client.from("BookIssue")
                        .insert(bookIssue)
                    
                    try await query.execute()
                    
                    // Update book availability
                    try await updateBookAvailability(bookId: bookId)
                }
                
                await MainActor.run {
                    isProcessing = false
                    isSuccess = true
                    alertTitle = "Success"
                    alertMessage = "\(bookIds.count) book(s) have been issued to \(memberName)."
                    showAlert = true
                    
                    // Announce for accessibility
                    UIAccessibility.post(notification: .announcement, argument: "Success! \(bookIds.count) books have been issued to \(memberName)")
                }
                
            } catch {
                await MainActor.run {
                    isProcessing = false
                    isSuccess = false
                    alertTitle = "Error"
                    alertMessage = "Failed to issue books: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    private func updateBookAvailability(bookId: String) async throws {
        // Get current book data
        let bookQuery = supabaseController.client.from("Books")
            .select()
            .eq("id", value: bookId)
            .single()
        
        struct Book: Codable {
            let availableCopies: Int
        }
        
        let book: Book = try await bookQuery.execute().value
        
        // Update available copies
        let updatedBook = ["availableCopies": book.availableCopies - 1]
        try await supabaseController.client.from("Books")
            .update(updatedBook)
            .eq("id", value: bookId)
            .execute()
    }
    
    private func processVoiceCommand(_ command: String) {
        let lowercasedCommand = command.lowercased()
        
        // Process member ID commands
        if lowercasedCommand.contains("member id") || lowercasedCommand.contains("member number") {
            // Extract the member ID number from the command
            if let memberId = extractIdFromCommand(command, prefix: "member id") ?? 
                              extractIdFromCommand(command, prefix: "member number") {
                self.memberId = memberId
                Task {
                    await lookupMember()
                }
            }
        }
        
        // Process book commands
        if lowercasedCommand.contains("add book") || lowercasedCommand.contains("scan book") {
            // Extract the ISBN from the command
            if let isbn = extractIdFromCommand(command, prefix: "add book") ?? 
                          extractIdFromCommand(command, prefix: "scan book") {
                Task {
                    await lookupBook(isbn: isbn)
                }
            }
        }
        
        // Navigation commands
        if lowercasedCommand.contains("next step") || lowercasedCommand.contains("continue") {
            if canProceed {
                nextStep()
            }
        }
        
        if lowercasedCommand.contains("previous") || lowercasedCommand.contains("go back") {
            if step > 0 {
                step -= 1
            }
        }
        
        // Confirmation command
        if lowercasedCommand.contains("confirm") || lowercasedCommand.contains("issue books") {
            if step == 2 {
                issueBooks()
            }
        }
    }
    
    private func extractIdFromCommand(_ command: String, prefix: String) -> String? {
        let lowercasedCommand = command.lowercased()
        
        guard lowercasedCommand.contains(prefix) else { return nil }
        
        // Get everything after the prefix
        if let range = lowercasedCommand.range(of: prefix) {
            let afterPrefix = lowercasedCommand[range.upperBound...]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Extract only digits
            let digitsOnly = afterPrefix.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            
            if !digitsOnly.isEmpty {
                return digitsOnly
            }
        }
        
        return nil
    }
}

//struct BookIssueData: Codable {
//    let id: String
//    let memberId: String
//    let bookId: String
//    let issueDate: String
//    let dueDate: String
//    let returnDate: String?
//    let fine: Double
//    let status: String
//}
//
//struct BookIssueData: Codable {
//    let id: String
//    let memberId: String
//    let bookId: String
//    let issueDate: String
//    let dueDate: String
//    let returnDate: String?
//    let fine: Double
//    let status: String
//}

#Preview {
    VoiceCommandBookIssueView()
        .environmentObject(AccessibilityManager())
} 
