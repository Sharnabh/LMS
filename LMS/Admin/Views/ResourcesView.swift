import SwiftUI
import UniformTypeIdentifiers

struct ResourcesView: View {
    @StateObject private var bookStore = AdminBookStore()
    @State private var showAddBookSheet = false
    @State private var showCSVUploadSheet = false
    @State private var showScanner = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var isConnected = false
    @State private var retryCount = 0
    @State private var searchText = ""
    @State private var selectedBook: LibrarianBook? = nil
    @State private var showBookDetails = false
    private let maxRetries = 3
    
    private var filteredBooks: [LibrarianBook] {
        if searchText.isEmpty {
            return bookStore.books
        } else {
            return bookStore.books.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                book.author.joined(separator: " ").localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if isConnected {
                    if bookStore.books.isEmpty {
                        VStack(spacing: 20) {
                            Text("No books added yet")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 20) {
                                Button(action: {
                                    showAddBookSheet = true
                                }) {
                                    VStack {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 40))
                                        Text("Add Book")
                                    }
                                }
                                
                                Button(action: {
                                    showCSVUploadSheet = true
                                }) {
                                    VStack {
                                        Image(systemName: "doc.badge.plus")
                                            .font(.system(size: 40))
                                        Text("Upload CSV")
                                    }
                                }
                            }
                            .foregroundColor(.accentColor)
                        }
                    } else {
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Search books...", text: $searchText)
                                .textFieldStyle(.plain)
                        }
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        
                        // Books grid
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 160), spacing: 16)
                            ], spacing: 16) {
                                ForEach(filteredBooks) { book in
                                    BookCard(book: book)
                                        .onTapGesture {
                                            selectedBook = book
                                            showBookDetails = true
                                        }
                                }
                            }
                            .padding()
                        }
                        .refreshable {
                            await bookStore.loadBooks()
                        }
                        
                        // Toolbar with add buttons
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Menu {
                                    Button(action: {
                                        showAddBookSheet = true
                                    }) {
                                        Label("Add Book", systemImage: "plus.circle")
                                    }
                                    
                                    Button(action: {
                                        showCSVUploadSheet = true
                                    }) {
                                        Label("Upload CSV", systemImage: "doc.badge.plus")
                                    }
                                } label: {
                                    Image(systemName: "plus")
                                }
                            }
                        }
                    }
                } else {
                    VStack(spacing: 20) {
                        Text("Unable to connect to database")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            retryConnection()
                        }) {
                            Text("Retry Connection")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.accentColor)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .navigationTitle("Resources")
        }
        .sheet(isPresented: $showAddBookSheet) {
            AddBookView()
                .environmentObject(bookStore)
                .onDisappear {
                    Task {
                        await bookStore.loadBooks()
                    }
                }
        }
        .sheet(isPresented: $showCSVUploadSheet) {
            CSVUploadView()
                .environmentObject(bookStore)
                .onDisappear {
                    Task {
                        await bookStore.loadBooks()
                    }
                }
        }
        .sheet(item: $selectedBook) { book in
            NavigationView {
                AdminBookDetailView(book: book)
                    .environmentObject(bookStore)
                    .navigationBarItems(leading: Button("Cancel") {
                        selectedBook = nil
                    })
            }
            .onDisappear {
                Task {
                    await bookStore.loadBooks()
                }
            }
        }
        .onAppear {
            checkConnection()
        }
    }
    
    private func checkConnection() {
        Task {
            do {
                isConnected = try await bookStore.dataController.testConnection()
            } catch {
                isConnected = false
            }
        }
    }
    
    private func retryConnection() {
        if retryCount < maxRetries {
            retryCount += 1
            checkConnection()
        }
    }
}

struct BookCard: View {
    let book: LibrarianBook
    @State private var fetchedImageURL: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Book cover with actual image or placeholder
            if let imageURL = book.imageLink ?? fetchedImageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 160, height: 200)
                            .background(Color.gray.opacity(0.1))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 160, height: 200)
                            .background(Color.white)
                    case .failure:
                        placeholderCover
                    @unknown default:
                        placeholderCover
                    }
                }
                .cornerRadius(4)
                .padding(.bottom, 8)
            } else {
                placeholderCover
                    .padding(.bottom, 8)
            }
            
            // Book info
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Text(book.author.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Text(book.genre)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .padding(.top, 2)
            }
            .padding(.horizontal, 8)
            .frame(height: 80, alignment: .top)
        }
        .frame(width: 160, height: 290)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .onAppear {
            // If book doesn't have an image link but has an ISBN, try to fetch the image
            if book.imageLink == nil && !book.ISBN.isEmpty {
                fetchBookImage()
            }
        }
    }
    
    private var placeholderCover: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.1))
            .frame(width: 160, height: 200)
            .overlay(
                Image(systemName: "book.closed")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(40)
                    .foregroundColor(Color.gray.opacity(0.5))
            )
            .cornerRadius(4)
    }
    
    private func fetchBookImage() {
        Task {
            do {
                let fetchedBook = try await GoogleBooksService.fetchBookByISBN(isbn: book.ISBN)
                if let imageLink = fetchedBook.imageLink {
                    await MainActor.run {
                        self.fetchedImageURL = imageLink
                    }
                }
            } catch {
                print("Failed to fetch book image for ISBN \(book.ISBN): \(error)")
            }
        }
    }
}

// Add Book View
struct AddBookView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var bookStore: AdminBookStore
    @State private var title = ""
    @State private var author = ""
    @State private var genre = ""
    @State private var isbn = ""
    @State private var publicationDate = ""
    @State private var totalCopies = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    @State private var isLoading = false
    
    let genres = ["Science", "Humanities", "Business", "Medicine", "Law", "Education", "Arts", "Religion", "Mathematics", "Technology", "Reference"]
    
    private var isValid: Bool {
        !title.isEmpty &&
        !author.isEmpty &&
        !genre.isEmpty &&
        !isbn.isEmpty && isbn.count >= 10 &&
        !publicationDate.isEmpty &&
        !totalCopies.isEmpty &&
        Int(publicationDate) != nil &&
        Int(totalCopies) != nil &&
        Int(totalCopies)! > 0
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Book Information")) {
                    TextField("Title", text: $title)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Author(s)", text: $author)
                        Text("For multiple authors, separate with semicolons (;)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("Genre", selection: $genre) {
                        ForEach(genres, id: \.self) { genre in
                            Text(genre).tag(genre)
                        }
                    }
                    
                    TextField("ISBN", text: $isbn)
                        .keyboardType(.numberPad)
                    
                    TextField("Publication Year", text: $publicationDate)
                        .keyboardType(.numberPad)
                    
                    TextField("Total Copies", text: $totalCopies)
                        .keyboardType(.numberPad)
                }
                
                if !isValid {
                    Section {
                        Text("Please fill in all required fields correctly")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add Book")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Add") {
                    addBook()
                }
                .disabled(!isValid)
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
    }
    
    private func addBook() {
        isLoading = true
        
        Task {
            do {
                let result = try await BookService.shared.addBook(
                    title: title,
                    author: author,
                    genre: genre,
                    ISBN: isbn,
                    publicationDate: publicationDate,
                    totalCopies: Int(totalCopies) ?? 1
                )
                
                // Refresh the book list
                await bookStore.loadBooks()
                
                await MainActor.run {
                    isSuccess = true
                    alertMessage = result.isNewBook ? "Book added successfully" : "Book copies updated successfully"
                    showAlert = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isSuccess = false
                    alertMessage = error.localizedDescription
                    showAlert = true
                    isLoading = false
                }
            }
        }
    }
}

// Admin Book Detail View
struct AdminBookDetailView: View {
    let book: LibrarianBook
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Book cover image with better styling
                if let imageURL = book.imageLink {
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 150, height: 200)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 150, height: 200)
                                .clipped()
                                .cornerRadius(8)
                                .shadow(radius: 5)
                        case .failure:
                            Image(systemName: "book.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 150, height: 200)
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .padding(.bottom, 8)
                } else {
                    Image(systemName: "book.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 200)
                        .foregroundColor(.gray)
                        .padding(.bottom, 8)
                }
                
                // Title and authors
                Text(book.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 8)
                
                Text(book.author.joined(separator: ", "))
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                // Stats section
                HStack {
                    AdminStatBox(title: "Total Copies", value: "\(book.totalCopies)", icon: "books.vertical.fill", color: .blue)
                    AdminStatBox(title: "Available", value: "\(book.availableCopies)", icon: "book.closed.fill", color: .green)
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // Additional details
                Group {
                    AdminDetailRow(label: "Genre", value: book.genre)
                    AdminDetailRow(label: "ISBN", value: book.ISBN)
                    AdminDetailRow(label: "Publication Date", value: book.publicationDate)
                    
                    if let publisher = book.publisher {
                        AdminDetailRow(label: "Publisher", value: publisher)
                    }
                }
                
                // Description
                if let description = book.Description, !description.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        Text(description)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Book Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AdminStatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
}

struct AdminDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .fontWeight(.medium)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ResourcesView()
}
