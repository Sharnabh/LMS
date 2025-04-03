import SwiftUI

struct CSVPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var bookStore: BookStore
    
    // Use a @State array of books so we can modify shelf locations
    @State private var booksToImport: [LibrarianBook]
    @State private var isImporting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    @State private var selectedBookIndex: Int? = nil
    @State private var showShelfLocationEditor = false
    @State private var showBookEditor = false
    @State private var tempBook: LibrarianBook? = nil
    @State private var tempShelfLocation = ""
    
    // Initialize with the books passed in
    init(books: [LibrarianBook]) {
        _booksToImport = State(initialValue: books)
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack {
                // Navigation bar with Import/Cancel buttons
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.accentColor)
                    
                    Spacer()
                    
                    Text("Preview CSV Books")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("Import") {
                        importBooks()
                    }
                    .disabled(booksToImport.isEmpty)
                    .foregroundColor(booksToImport.isEmpty ? .gray : .accentColor)
                }
                .padding()
                
                // Summary header
                SummaryHeaderView(booksCount: booksToImport.count)
                
                // Books list
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(booksToImport.enumerated()), id: \.element.id) { index, book in
                            CSVBookItemView(
                                book: book,
                                shelfLocation: book.shelfLocation ?? "Not Set",
                                onEditDetails: {
                                    selectedBookIndex = index
                                    tempBook = book
                                    showBookEditor = true
                                },
                                onSetLocation: {
                                    selectedBookIndex = index
                                    tempShelfLocation = book.shelfLocation ?? ""
                                    showShelfLocationEditor = true
                                }
                            )
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
        .navigationBarHidden(true)
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
        .sheet(isPresented: $showShelfLocationEditor) {
            ShelfLocationEditorView(
                bookTitle: selectedBookIndex != nil ? booksToImport[selectedBookIndex!].title : "",
                shelfLocation: $tempShelfLocation,
                onSave: {
                    if let index = selectedBookIndex {
                        // Create a new book with the updated shelf location
                        let updatedBook = updateBookShelfLocation(book: booksToImport[index], newLocation: tempShelfLocation)
                        // Update the book in the array
                        booksToImport[index] = updatedBook
                    }
                    showShelfLocationEditor = false
                },
                onCancel: {
                    showShelfLocationEditor = false
                }
            )
        }
        .sheet(isPresented: $showBookEditor) {
            // If sheet is dismissed, don't update
        } content: {
            BookEditorView(
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
    
    // Helper function to update a book's shelf location
    private func updateBookShelfLocation(book: LibrarianBook, newLocation: String) -> LibrarianBook {
        return LibrarianBook(
            id: book.id,
            title: book.title,
            author: book.author,
            genre: book.genre,
            publicationDate: book.publicationDate,
            totalCopies: book.totalCopies,
            availableCopies: book.availableCopies,
            ISBN: book.ISBN,
            Description: book.Description,
            shelfLocation: newLocation,
            dateAdded: book.dateAdded,
            publisher: book.publisher,
            imageLink: book.imageLink
        )
    }
    
    private func importBooks() {
        isImporting = true
        
        Task {
            var importedCount = 0
            var updatedCount = 0
            
            for book in booksToImport {
                if book.shelfLocation == nil || book.shelfLocation!.isEmpty {
                    await MainActor.run {
                        isImporting = false
                        alertMessage = "Please set shelf location for all books before importing."
                        showAlert = true
                    }
                    return
                }
                
                do {
                    let (isNewBook, _) = await bookStore.addOrUpdateBook(book)
                    if isNewBook {
                        importedCount += 1
                    } else {
                        updatedCount += 1
                    }
                } catch {
                    print("Error importing book: \(error)")
                }
            }
            
            await MainActor.run {
                isImporting = false
                isSuccess = true
                alertMessage = """
                    Import completed successfully!
                    New books added: \(importedCount)
                    Existing books updated: \(updatedCount)
                    """
                showAlert = true
            }
        }
    }
}

struct BookEditorView: View {
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
                    .foregroundColor(isValid ? .accentColor : .gray)
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

// A view for editing shelf location
struct ShelfLocationEditorView: View {
    let bookTitle: String
    @Binding var shelfLocation: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Set Shelf Location")
                    .font(.headline)
                    .padding(.top)
                
                Text(bookTitle)
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                TextField("Shelf Location (e.g., A1-S3)", text: $shelfLocation)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                Text("Enter the shelf location where this book will be stored.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationBarItems(
                leading: Button("Cancel", action: onCancel),
                trailing: Button("Save", action: onSave)
            )
        }
    }
}

struct SummaryHeaderView: View {
    let booksCount: Int
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(booksCount) Books Found")
                .font(.headline)
            
            Text("Tap on a book to set its shelf location")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
    }
}

struct CSVBookItemView: View {
    let book: LibrarianBook
    let shelfLocation: String
    var onEditDetails: () -> Void
    var onSetLocation: () -> Void
    
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
                Button(action: onSetLocation) {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(shelfLocation == "Not Set" ? .red : .green)
                        Text(shelfLocation)
                            .font(.caption)
                            .foregroundColor(shelfLocation == "Not Set" ? .red : .primary)
                    }
                }
                
                Spacer()
                
                Button(action: onEditDetails) {
                    Label("Edit Details", systemImage: "pencil")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
        )
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .onTapGesture {
            onSetLocation()
        }
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

struct BookInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .lineLimit(1)
        }
    }
}

#Preview {
    CSVPreviewView(books: [
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
    .environmentObject(BookStore())
} 
