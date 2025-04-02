//
//  ContentView.swift
//  QRScanner
//
//  Created by Sharnabh on 21/03/25.
//

import SwiftUI

// Add Return QR Code model
struct ReturnQRCode: Codable {
    let issueId: String
    let action: String
    let timestamp: String
}

// Add Return Confirmation View
struct ReturnConfirmationView: View {
    let issue: BookIssueData
    let book: LibrarianBook
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabaseController = SupabaseDataController()
    @EnvironmentObject private var accessibilityManager: AccessibilityManager
    @State private var isProcessing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Book Info Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "book.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(book.title)
                                    .font(.title2)
                                    .bold()
                                Text("Author: \(book.author.joined(separator: ", "))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("ISBN: \(book.ISBN)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Book details: \(book.title) by \(book.author.joined(separator: ", "))")
                    }
                    
                    // Issue Details Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Issue Details")
                            .font(.title3)
                            .bold()
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            DetailRow(label: "Issue Date", value: formatDate(issue.issueDate))
                            DetailRow(label: "Due Date", value: formatDate(issue.dueDate))
                            DetailRow(label: "Return Date", value: Date().formatted())
                            DetailRow(label: "Fine", value: "₹\(String(format: "%.2f", issue.fine))")
                            
                            // Check if book is overdue
                            if isOverdue() {
                                Text("This book is being returned after the due date.")
                                    .foregroundColor(.red)
                                    .font(.callout)
                                    .padding(.top, 4)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel("Issue details: Issue date \(formatDate(issue.issueDate)), Due date \(formatDate(issue.dueDate)). \(isOverdue() ? "This book is overdue." : "This book is being returned on time.")")
                    }
                    
                    // Confirm Button
                    Button(action: {
                        confirmReturn()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Confirm Return")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isProcessing ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isProcessing)
                    .padding(.top)
                    .accessibilityLabel("Confirm book return")
                    .accessibilityHint("Double tap to confirm the return of this book")
                }
                .padding()
            }
            .navigationTitle("Confirm Return")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertMessage.contains("Success") ? "Success" : "Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if alertMessage.contains("Success") {
                            dismiss()
                        }
                    }
                )
            }
            .overlay {
                if isProcessing {
                    ZStack {
                        Color.black.opacity(0.3)
                        ProgressView("Processing...")
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                    }
                }
                
                // Voice command button overlay
                VStack {
                    HStack {
                        Spacer()
                        VoiceCommandButton()
                            .padding(.top, 60)
                            .padding(.trailing, 20)
                    }
                    Spacer()
                }
            }
            .onAppear {
                // Announce for accessibility
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let message = "Book return confirmation for \(book.title). \(isOverdue() ? "This book is overdue." : "This book is being returned on time.") Say confirm to process the return."
                    UIAccessibility.post(notification: .announcement, argument: message)
                }
            }
            .onChange(of: accessibilityManager.commandDetected) { oldValue, command in
                let lowercasedCommand = command.lowercased()
                
                // Handle voice commands
                if (lowercasedCommand.contains("confirm") || 
                    lowercasedCommand.contains("return")) && 
                    !isProcessing {
                    
                    // Provide feedback
                    UIAccessibility.post(notification: .announcement, argument: "Confirming book return...")
                    
                    // Execute return action
                    confirmReturn()
                } else if lowercasedCommand.contains("cancel") || lowercasedCommand.contains("go back") {
                    dismiss()
                } else if lowercasedCommand.contains("details") || lowercasedCommand.contains("information") {
                    // Read out details for accessibility
                    let message = "Book: \(book.title) by \(book.author.joined(separator: ", ")). Issue date: \(formatDate(issue.issueDate)). Due date: \(formatDate(issue.dueDate)). \(isOverdue() ? "This book is overdue." : "This book is being returned on time.")"
                    
                    UIAccessibility.post(notification: .announcement, argument: message)
                }
            }
        }
    }
    
    private func formatDate(_ isoString: String) -> String {
        if let date = ISO8601DateFormatter().date(from: isoString) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
        return isoString
    }
    
    private func isOverdue() -> Bool {
        let formatter = ISO8601DateFormatter()
        if let dueDate = formatter.date(from: issue.dueDate) {
            return Date() > dueDate
        }
        return false
    }
    
    private func confirmReturn() {
        isProcessing = true
        
        Task {
            do {
                let returnDate = Date()
                let formatter = ISO8601DateFormatter()
                
                // Check if book is being returned late
                let isOverdue = self.isOverdue()
                
                // Calculate the fine if overdue
                var fine = issue.fine
                if isOverdue {
                    // Get the due date
                    if let dueDate = formatter.date(from: issue.dueDate) {
                        // Calculate days overdue
                        let calendar = Calendar.current
                        let components = calendar.dateComponents([.day], from: dueDate, to: returnDate)
                        if let daysOverdue = components.day, daysOverdue > 0 {
                            // This assumes library_policies.fine_amount is 10
                            // Ideally we would fetch this from the database
                            let fineAmount = 10
                            fine = Double(daysOverdue * fineAmount)
                        }
                    }
                }
                
                // Create a proper struct for the update
                struct BookIssueUpdate: Encodable {
                    let status: String
                    let returnDate: String
                    let is_overdue: Bool
                    let fine: Double
                    let is_paid: Bool
                }
                
                let updateData = BookIssueUpdate(
                    status: "Returned",
                    returnDate: formatter.string(from: returnDate),
                    is_overdue: isOverdue,
                    fine: fine,
                    is_paid: false
                )
                
                // Update book issue
                let updateQuery = try supabaseController.client.from("BookIssue")
                    .update(updateData)
                    .eq("id", value: issue.id)
                
                try await updateQuery.execute()
                
                // Update book availability
                let updatedBook = BookUpdateData(
                    availableCopies: book.availableCopies + 1
                )
                
                let updateBookQuery = try supabaseController.client.from("Books")
                    .update(updatedBook)
                    .eq("id", value: book.id!.uuidString)
                
                try await updateBookQuery.execute()
                
                await MainActor.run {
                    isProcessing = false
                    alertMessage = "Successfully returned the book." + (isOverdue ? " Fine of ₹\(String(format: "%.2f", fine)) has been applied." : "")
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    alertMessage = "Error: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}

struct QRScanner: View {
    @State private var scannedCode = ""
    @State private var alertItem: AlertItem?
    @State private var bookInfo: BookInfo?
    @State private var isShowingBookInfo = false
    @State private var isProcessing = false
    @State private var lastProcessedCode = ""
    @State private var isShowingReturnConfirmation = false
    @State private var returnIssue: BookIssueData?
    @State private var returnBook: LibrarianBook?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var supabaseController = SupabaseDataController()
    @EnvironmentObject private var accessibilityManager: AccessibilityManager
    
    // Add flag to check if this is presented as a fullScreenCover
    var isPresentedAsFullScreen: Bool = false
    
    // Add function to check borrowing limits
    private func checkBorrowingLimit(memberId: String, newBooksCount: Int) async throws -> Bool {
        // 1. Fetch library policies
        let policiesQuery = supabaseController.client.from("library_policies")
            .select()
        
        let policiesResponse = try await policiesQuery.execute()
        let policies = try JSONDecoder().decode([PolicyResponse].self, from: policiesResponse.data)
        
        guard let policy = policies.first else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Library policies not found"])
        }
        
        // 2. Count currently issued books for the member
        let issuedBooksQuery = supabaseController.client.from("BookIssue")
            .select()
            .eq("memberId", value: memberId)
            .eq("status", value: "Issued")
        
        let issuedBooksResponse = try await issuedBooksQuery.execute()
        let issuedBooks = try JSONDecoder().decode([BookIssueData].self, from: issuedBooksResponse.data)
        
        // 3. Check if adding new books would exceed the limit
        let currentIssuedCount = issuedBooks.count
        
        print("Current issued books: \(currentIssuedCount)")
        print("New books to be issued: \(newBooksCount)")
        print("Borrowing limit: \(policy.borrowing_limit)")
        
        if (currentIssuedCount + newBooksCount) > policy.borrowing_limit {
            throw NSError(domain: "", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Member has \(currentIssuedCount) books issued out of \(policy.borrowing_limit) limit. Cannot issue \(newBooksCount) more books."
            ])
        }
        
        return true
    }
    
    var body: some View {
        let content = ZStack {
            ScannerView(scannedCode: $scannedCode, alertItem: $alertItem)
                .onAppear {
                    // Reset the scanned code when scanner appears
                    scannedCode = ""
                    lastProcessedCode = ""
                    
                    // Announce for accessibility
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        UIAccessibility.post(notification: .announcement, argument: "QR Scanner active. Please position the member's QR code in the center of the screen.")
                    }
                }
                .accessibilityLabel("QR code scanner")
                .accessibilityHint("Center the QR code in the middle of the screen to scan")
            
            VStack {
                Spacer()
                Text("Scan Library QR Code")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
                    .accessibilityLabel("Scan Library QR Code")
                Spacer().frame(height: 100)
            }
            
            // Add voice command button overlay
            VStack {
                HStack {
                    Spacer()
                    VoiceCommandButton()
                        .padding(.top, 60)
                        .padding(.trailing, 20)
                }
                Spacer()
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onChange(of: scannedCode) { oldValue, newValue in
            // Only process if we have a non-empty code, we're not already processing,
            // and this isn't the same code we just processed
            if !newValue.isEmpty && !isProcessing && newValue != lastProcessedCode {
                lastProcessedCode = newValue
                isProcessing = true
                
                // Announce scanning feedback for accessibility
                UIAccessibility.post(notification: .announcement, argument: "QR code detected. Processing.")
                
                processQRCode(newValue)
            }
        }
        .alert(item: $alertItem) { alertItem in
            Alert(
                title: Text(alertItem.title),
                message: Text(alertItem.message),
                dismissButton: .default(Text("OK")) {
                    // After dismissing an alert, allow processing again
                    isProcessing = false
                    
                    // Announce alert dismissal for accessibility
                    UIAccessibility.post(notification: .announcement, argument: "Alert dismissed. Scanner ready.")
                }
            )
        }
        .sheet(isPresented: $isShowingBookInfo, onDismiss: {
            // After showing book info, prepare for a new scan
            prepareForNewScan()
        }) {
            if let bookInfo = bookInfo {
                BookInfoView(bookInfo: bookInfo)
            }
        }
        .sheet(isPresented: $isShowingReturnConfirmation, onDismiss: {
            // After showing return confirmation, prepare for a new scan
            prepareForNewScan()
        }) {
            if let issue = returnIssue, let book = returnBook {
                ReturnConfirmationView(issue: issue, book: book)
            }
        }
        .onChange(of: accessibilityManager.commandDetected) { oldCommand, command in
            // Process voice commands relevant to QR scanning
            let lowercasedCommand = command.lowercased()
            
            if lowercasedCommand.contains("cancel") || lowercasedCommand.contains("go back") {
                dismiss()
            } else if lowercasedCommand.contains("help") {
                UIAccessibility.post(notification: .announcement, argument: "Position the QR code in the center of the screen. Say cancel or go back to exit.")
            }
        }
        
        // Only wrap in NavigationView if not presented as fullScreenCover
        if isPresentedAsFullScreen {
            return AnyView(content)
        } else {
            return AnyView(NavigationView {
                content.navigationBarItems(trailing: Button("Close") {
                    dismiss()
                }
                .accessibilityLabel("Close scanner")
                .accessibilityHint("Double tap to close the QR scanner"))
            })
        }
    }
    
    private func prepareForNewScan() {
        // Reset all scanner-related state
        isProcessing = false
        scannedCode = ""
        lastProcessedCode = ""
        returnIssue = nil
        returnBook = nil
        
        // Announce ready state for accessibility
        UIAccessibility.post(notification: .announcement, argument: "Scanner ready for next scan.")
    }
    
    private func processQRCode(_ code: String) {
        guard !code.isEmpty else { 
            isProcessing = false
            return 
        }
        
        // First try to parse as return QR code
        if let returnData = try? JSONDecoder().decode(ReturnQRCode.self, from: code.data(using: .utf8) ?? Data()) {
            if returnData.action == "return" {
                handleReturnQRCode(returnData)
                return
            }
        }
        
        // If not a return QR code, try to parse as book issue QR code
        let result = QRCodeParser.parseBookInfo(from: code)
        
        switch result {
        case .success(let parsedInfo):
            // Check if the QR code is expired
            let expirationDate = Date(timeIntervalSince1970: parsedInfo.expirationDate)
            if Date() > expirationDate {
                alertItem = AlertContext.expiredQRCode
                isProcessing = false
                return
            }
            
            // Check if the issue status is valid
            if parsedInfo.issueStatus != "Pending" {
                alertItem = AlertItem(
                    title: "Invalid Issue Status",
                    message: "This QR code has already been processed or is invalid.",
                    dismissButton: .default(Text("OK"))
                )
                isProcessing = false
                return
            }
            
            // Check borrowing limit before showing book info
            Task {
                do {
                    let newBooksCount = parsedInfo.bookIds.count
                    _ = try await checkBorrowingLimit(memberId: parsedInfo.memberId, newBooksCount: newBooksCount)
                    
                    await MainActor.run {
                        bookInfo = parsedInfo
                        isShowingBookInfo = true
                    }
                } catch {
                    await MainActor.run {
                        alertItem = AlertItem(
                            title: "Borrowing Limit Exceeded",
                            message: error.localizedDescription,
                            dismissButton: .default(Text("OK"))
                        )
                        isProcessing = false
                    }
                }
            }
            
        case .failure(let error):
            switch error {
            case .invalidFormat:
                alertItem = AlertContext.invalidQRCode
            case .invalidJSON:
                alertItem = AlertContext.invalidJSONFormat
            case .missingFields:
                alertItem = AlertContext.missingRequiredFields
            case .expired:
                alertItem = AlertContext.expiredQRCode
            case .invalidAction:
                alertItem = AlertItem(
                    title: "Invalid Action",
                    message: "This QR code contains an invalid action.",
                    dismissButton: .default(Text("OK"))
                )
            }
            isProcessing = false
        }
    }
    
    private func handleReturnQRCode(_ returnData: ReturnQRCode) {
        Task {
            do {
                // 1. Verify the issue exists and is in "issued" status
                let query = supabaseController.client.from("BookIssue")
                    .select()
                    .eq("id", value: returnData.issueId)
                
                let response = try await query.execute()
                let issues = try JSONDecoder().decode([BookIssueData].self, from: response.data)
                
                guard let issue = issues.first else {
                    await MainActor.run {
                        alertItem = AlertItem(
                            title: "Invalid Issue",
                            message: "The book issue record was not found.",
                            dismissButton: .default(Text("OK"))
                        )
                        isProcessing = false
                    }
                    return
                }
                
                guard issue.status == "Issued" else {
                    await MainActor.run {
                        alertItem = AlertItem(
                            title: "Invalid Status",
                            message: "This book has already been returned or is not in issued status.",
                            dismissButton: .default(Text("OK"))
                        )
                        isProcessing = false
                    }
                    return
                }
                
                // 2. Get book details
                let bookQuery = supabaseController.client.from("Books")
                    .select()
                    .eq("id", value: issue.bookId)
                
                let bookResponse = try await bookQuery.execute()
                let books = try JSONDecoder().decode([LibrarianBook].self, from: bookResponse.data)
                
                guard let book = books.first else {
                    await MainActor.run {
                        alertItem = AlertItem(
                            title: "Error",
                            message: "Book details not found.",
                            dismissButton: .default(Text("OK"))
                        )
                        isProcessing = false
                    }
                    return
                }
                
                // 3. Show confirmation view - the actual return will be handled by the confirmation screen
                await MainActor.run {
                    returnIssue = issue
                    returnBook = book
                    isShowingReturnConfirmation = true
                    isProcessing = false
                }
                
            } catch {
                await MainActor.run {
                    alertItem = AlertItem(
                        title: "Error",
                        message: "Failed to process book return: \(error.localizedDescription)",
                        dismissButton: .default(Text("OK"))
                    )
                    isProcessing = false
                }
            }
        }
    }
}

#Preview {
    QRScanner(isPresentedAsFullScreen: false)
}
