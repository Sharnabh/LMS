import SwiftUI

struct AdminCSVPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var bookStore: AdminBookStore
    @EnvironmentObject private var shelfLocationStore: ShelfLocationStore
    
    // Use a @State array of books so we can modify shelf locations
    @State private var booksToImport: [LibrarianBook]
    @State private var isImporting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    @State private var selectedBookIndex: Int? = nil // Track which book is being edited
    @State private var showBookEditor = false
    @State private var tempBook: LibrarianBook? = nil
    
    // Initialize with the books passed in
    init(books: [LibrarianBook]) {
        _booksToImport = State(initialValue: books)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                VStack {
                    // Summary header
                    AdminSummaryHeaderView(booksCount: booksToImport.count)
                    
                    // Books list
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(booksToImport.enumerated()), id: \.element.id) { index, book in
                                AdminCSVBookItemView(book: book)
                                    .onTapGesture {
                                        // Show book editor when tapped
                                        selectedBookIndex = index
                                        tempBook = book
                                        showBookEditor = true
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Loading overlay
                if isImporting {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay(
                            VStack(spacing: 20) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                Text("Importing books...")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .padding(30)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemBackground))
                            )
                            .shadow(radius: 10)
                        )
                }
            }
            .navigationTitle("Preview CSV Books")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Import") {
                    importBooks()
                }
                .disabled(booksToImport.isEmpty)
                .foregroundColor(booksToImport.isEmpty ? .gray : Color.accentColor)
            )
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
        .sheet(isPresented: $showBookEditor) {
            // If sheet is dismissed, don't update
        } content: {
            AdminBookEditorView(
                book: $tempBook,
                onSave: {
                    if let index = selectedBookIndex {
                        // Update the book with edited values
                        updateBook(index: index)
                    }
                    showBookEditor = false
                },
                onCancel: {
                    showBookEditor = false
                }
            )
        }
    }
    
    // Helper function to update the book with edited values
    private func updateBook(index: Int) {
        if let editedBook = tempBook {
            booksToImport[index] = editedBook
        }
    }
    
    private func importBooks() {
        isImporting = true
        
        Task {
            var importedCount = 0
            var updatedCount = 0
            
            for book in booksToImport {
                do {
                    // Convert LibrarianBook to BookService format
                    let authorString = book.author.joined(separator: "; ")
                    
                    // Convert Date to Unix timestamp
                    let timestamp: Int
                    if let date = book.dateAdded {
                        timestamp = Int(date.timeIntervalSince1970)
                    } else {
                        timestamp = Int(Date().timeIntervalSince1970)
                    }
                    
                    // Check shelf capacity if shelf location is set
                    if let shelfLocation = book.shelfLocation {
                        if let shelf = shelfLocationStore.shelfLocations.first(where: { $0.shelfNo == shelfLocation }) {
                            let currentBooks = shelf.bookID.count
                            let newBooks = book.totalCopies
                            
                            if currentBooks + newBooks > shelf.capacity {
                                print("Skipping book '\(book.title)' - Shelf \(shelfLocation) is at capacity")
                                continue // Skip this book and move to the next
                            }
                        }
                    }
                    
                    // Check if book already exists by ISBN
                    let existingBooks = try await BookService.shared.findBooksByISBN(book.ISBN)
                    
                    if let existingBook = existingBooks.first {
                        // Update existing book's copies and other fields
                        let newTotalCopies = existingBook.totalCopies + book.totalCopies
                        let newAvailableCopies = existingBook.availableCopies + book.totalCopies
                        
                        try await BookService.shared.updateBookCopies(
                            id: existingBook.id,
                            totalCopies: newTotalCopies,
                            availableCopies: newAvailableCopies,
                            Description: book.Description,
                            shelfLocation: book.shelfLocation,
                            publisher: book.publisher,
                            imageLink: book.imageLink
                        )
                        updatedCount += 1
                    } else {
                        // Add as new book with all fields
                        let _ = try await BookService.shared.addBook(
                            title: book.title,
                            author: authorString,
                            genre: book.genre,
                            ISBN: book.ISBN,
                            publicationDate: book.publicationDate,
                            totalCopies: book.totalCopies,
                            Description: book.Description,
                            shelfLocation: book.shelfLocation,
                            publisher: book.publisher,
                            imageLink: book.imageLink
                        )
                        importedCount += 1
                    }
                    
                    // Small delay to avoid overwhelming the database
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                } catch {
                    print("Error importing book: \(error)")
                }
            }
            
            // Update the UI on the main thread
            await MainActor.run {
                isImporting = false
                showAlert = true
                alertMessage = "Import complete:\n• Added \(importedCount) new books\n• Updated \(updatedCount) existing books"
                isSuccess = true
            }
        }
    }
}

// Replace with:
// A view for editing book details
struct AdminBookEditorView: View {
    @Binding var book: LibrarianBook?
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @State private var title: String = ""
    @State private var authorText: String = ""
    @State private var genre: String = ""
    @State private var isbn: String = ""
    @State private var publicationDate: String = ""
    @State private var totalCopies: String = ""
    
    var isValid: Bool {
        !title.isEmpty && 
        !authorText.isEmpty && 
        !genre.isEmpty && 
        !isbn.isEmpty && 
        !publicationDate.isEmpty && 
        !totalCopies.isEmpty &&
        Int(totalCopies) != nil
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Edit Book Details")
                        .font(.headline)
                        .padding(.top)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Group {
                        Text("Title")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Book title", text: $title)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        Text("Author")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Author names (use ; for multiple authors)", text: $authorText)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        Text("Genre")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Genre (e.g., Fiction, Science, Technology)", text: $genre)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        Text("ISBN")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("ISBN-13 format", text: $isbn)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    Group {
                        Text("Publication Date")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Year of publication", text: $publicationDate)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        Text("Total Copies")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Number of copies", text: $totalCopies)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .onAppear {
                if let book = book {
                    title = book.title
                    authorText = book.author.joined(separator: "; ")
                    genre = book.genre
                    isbn = book.ISBN
                    publicationDate = book.publicationDate
                    totalCopies = "\(book.totalCopies)"
                }
            }
            .onChange(of: title) { updateBook() }
            .onChange(of: authorText) { updateBook() }
            .onChange(of: genre) { updateBook() }
            .onChange(of: isbn) { updateBook() }
            .onChange(of: publicationDate) { updateBook() }
            .onChange(of: totalCopies) { updateBook() }
            .navigationBarItems(
                leading: Button("Cancel", action: onCancel),
                trailing: Button("Save", action: onSave)
                    .disabled(!isValid)
            )
        }
    }
    
    private func updateBook() {
        guard let existingBook = book else { return }
        
        // Parse author string into array
        let authorArray = authorText.split(separator: ";").map { 
            String($0.trimmingCharacters(in: .whitespaces))
        }
        
        // Create updated book
        book = LibrarianBook(
            id: existingBook.id,
            title: title,
            author: authorArray,
            genre: genre,
            publicationDate: publicationDate,
            totalCopies: Int(totalCopies) ?? existingBook.totalCopies,
            availableCopies: Int(totalCopies) ?? existingBook.availableCopies,
            ISBN: isbn,
            Description: existingBook.Description,
            shelfLocation: existingBook.shelfLocation,
            dateAdded: existingBook.dateAdded,
            publisher: existingBook.publisher,
            imageLink: existingBook.imageLink
        )
    }
}

struct AdminSummaryHeaderView: View {
    let booksCount: Int
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(booksCount) Books Found")
                .font(.headline)
            
            Text("Tap on a book to edit its details")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
    }
}

struct AdminCSVBookItemView: View {
    let book: LibrarianBook
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                // Book cover if available
                if let imageURL = book.imageLink, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 80)
                                .cornerRadius(4)
                        case .empty, .failure:
                            bookPlaceholder
                        @unknown default:
                            bookPlaceholder
                        }
                    }
                    .frame(width: 60, height: 80)
                } else {
                    bookPlaceholder
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(book.author.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        
                    HStack {
                        Text(book.genre)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(4)
                        
                        Spacer()
                        
                        Text(book.publicationDate)
                            .font(.caption)
                    }
                }
                .padding(.leading, 8)
            }
            
            Divider()
            
            HStack {
                BookInfoRow(label: "ISBN", value: book.ISBN)
                Spacer()
                BookInfoRow(label: "Copies", value: "\(book.totalCopies)")
            }
            
            HStack {
                Spacer()
                
                Text("Tap to edit")
                    .font(.caption)
                    .foregroundColor(Color.accentColor)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
        )
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var bookPlaceholder: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 60, height: 80)
            .overlay(
                Image(systemName: "book.fill")
                    .foregroundColor(.gray)
            )
            .cornerRadius(4)
    }
}

#Preview {
    AdminCSVPreviewView(books: [
        LibrarianBook(
            id: UUID(),
            title: "Clean Code",
            author: ["Robert C. Martin"],
            genre: "Technology",
            publicationDate: "2008",
            totalCopies: 2,
            availableCopies: 2,
            ISBN: "9780132350884",
            Description: "Even bad code can function. But if code isn't clean, it can bring a development organization to its knees.",
            shelfLocation: nil,
            dateAdded: Date(),
            publisher: "Prentice Hall",
            imageLink: "https://books.google.com/books/content?id=hjEFCAAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api"
        ),
        LibrarianBook(
            id: UUID(),
            title: "Design Patterns: Elements of Reusable Object-Oriented Software",
            author: ["Erich Gamma", "Richard Helm", "Ralph Johnson", "John Vlissides"],
            genre: "Technology",
            publicationDate: "1994",
            totalCopies: 3,
            availableCopies: 3,
            ISBN: "9780201633610",
            Description: "Capturing a wealth of experience about the design of object-oriented software, four top-notch designers present a catalog of simple and succinct solutions to commonly occurring design problems.",
            shelfLocation: "A2-S3",
            dateAdded: Date(),
            publisher: "Addison-Wesley",
            imageLink: "https://books.google.com/books/content?id=6oHuKQe3TjQC&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api"
        )
    ])
    .environmentObject(AdminBookStore())
    .environmentObject(ShelfLocationStore())
} 
