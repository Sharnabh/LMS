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
    @State private var selectedBookIndex: Int? = nil // Track which book is being edited
    @State private var showShelfLocationEditor = false
    @State private var tempShelfLocation = ""
    
    // Initialize with the books passed in
    init(books: [LibrarianBook]) {
        _booksToImport = State(initialValue: books)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack {
                    // Summary header
                    SummaryHeaderView(booksCount: booksToImport.count)
                    
                    // Books list
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(booksToImport.enumerated()), id: \.element.id) { index, book in
                                CSVBookItemView(book: book, shelfLocation: book.shelfLocation ?? "Not Set")
                                    .onTapGesture {
                                        // Show shelf location editor when book is tapped
                                        selectedBookIndex = index
                                        tempShelfLocation = book.shelfLocation ?? ""
                                        showShelfLocationEditor = true
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
                trailing: Button("Import All") {
                    importBooks()
                }
                .disabled(booksToImport.isEmpty)
                .foregroundColor(booksToImport.isEmpty ? .gray : .blue)
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
        .sheet(isPresented: $showShelfLocationEditor) {
            // If sheet is dismissed, don't update
        } content: {
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
            var newBooksCount = 0
            var updatedBooksCount = 0
            
            for book in booksToImport {
                let result = await bookStore.addOrUpdateBook(book)
                if result.isNewBook {
                    newBooksCount += 1
                } else {
                    updatedBooksCount += 1
                }
                
                // Small delay to avoid overwhelming the database
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            }
            
            // Explicitly reload books to ensure they're updated across all views
            await bookStore.loadBooks()
            
            // Short delay to ensure UI updates
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
            
            await MainActor.run {
                isSuccess = true
                alertMessage = "Import summary:\n• Added \(newBooksCount) new books\n• Updated quantities for \(updatedBooksCount) existing books"
                isImporting = false
                showAlert = true
            }
        }
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
                            .background(Color.blue.opacity(0.1))
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
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(shelfLocation == "Not Set" ? .red : .green)
                Text(shelfLocation)
                    .font(.caption)
                    .foregroundColor(shelfLocation == "Not Set" ? .red : .primary)
                
                Spacer()
                
                Text("Tap to edit")
                    .font(.caption2)
                    .foregroundColor(.blue)
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