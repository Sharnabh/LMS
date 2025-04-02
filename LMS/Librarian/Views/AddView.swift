import SwiftUI
import AVFoundation
import UIKit

struct AddView: View {
    @EnvironmentObject private var bookStore: BookStore
    @State private var searchText: String = ""
    @State private var book: LibrarianBook? = nil
    @State private var isSearching = false
    @State private var errorMessage: String? = nil
    @State private var showScanner = false
    @State private var showAddBookSheet = false
    @State private var showCSVUploadSheet = false
    @State private var scannedCode: String = ""

    @State private var showingAddSection = false // Toggle between add and view sections


//    @State private var showingAddSection = true

    @State private var isEditing = false
    @State private var selectedBooks: Set<LibrarianBook> = []
    @State private var showSearchBar = false
    @State private var selectedGenre: String? = nil
    @State private var searchQuery = ""
    
    // Alert states
    @State private var showDeletionConfirmation = false
    @State private var showDeletionSuccess = false
    @State private var showDeletionError = false
    @State private var isProcessingDeletion = false

    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Segmented Control
                    Picker("View Mode", selection: $showingAddSection) {
                        Text("View Books").tag(false)
                        Text("Add Books").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    if showingAddSection {
                        // Add Books section
                        VStack(spacing: 16) {
                            // Search bar section
                            HStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.secondary)
                                    TextField("ISBN, Title, Author", text: $searchText)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                }
                                .padding(12)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(10)
                                
                                // Search button
                                Button(action: { searchBook() }) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.accentColor)
                                }
                                .disabled(searchText.isEmpty || isSearching)
                            }
                            .padding(.horizontal)
                            
                            if isSearching {
                                HStack {
                                    ProgressView()
                                        .padding(.trailing, 5)
                                    Text("Searching...")
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if let errorMessage = errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.subheadline)
                            }
                            
                            // Content area
                            if let book = book {
                                BookDetailView(book: book)
                            } else {
                                VStack(spacing: 20) {
                                    Spacer()
                                    Image(systemName: "book.pages")
                                        .font(.system(size: 60))
                                        .foregroundColor(.secondary)
                                    
                                    Text("Enter an ISBN or scan a barcode to\nadd books")
                                        .font(.subheadline)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                            }
                        }
                    } else {
                        // View Books section
                        AllBooksViewContent(isEditing: $isEditing, selectedBooks: $selectedBooks, searchQuery: $searchQuery, selectedGenre: $selectedGenre)
                            .environmentObject(bookStore)
                    }
                }
                
                // Floating scan button
                if showingAddSection {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: { showScanner = true }) {
                                Image(systemName: "barcode.viewfinder")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56)
                                    .background(Color.accentColor)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("Add Books")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if showingAddSection {
                        Menu {
                            Button(action: { showAddBookSheet = true }) {
                                Label("Add Book", systemImage: "plus.circle")
                            }
                            Button(action: { showCSVUploadSheet = true }) {
                                Label("Upload CSV", systemImage: "doc.badge.plus")
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    } else {
                        HStack(spacing: 16) {
                            if isEditing {
                                Button(action: { selectAllBooks() }) {
                                    Image(systemName: selectedBooks.count == bookStore.books.count ? "checkmark.square.fill" : "square")
                                }
                                Button(action: { deleteSelectedBooks() }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(selectedBooks.isEmpty ? .secondary : .red)
                                }
                                .disabled(selectedBooks.isEmpty)
                            }
                            Button(isEditing ? "Done" : "Edit") { 
                                withAnimation { isEditing.toggle() }
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showScanner) {
                BarcodeScannerView(scannedCode: $scannedCode)
                    .ignoresSafeArea()
            }
            .onChange(of: scannedCode) { oldCode, newCode in
                if !newCode.isEmpty {
                    searchText = newCode
                    searchBook()
                    scannedCode = ""
                }
            }
        }
        .sheet(isPresented: $showAddBookSheet) {
            LibrarianAddBookView()
                .environmentObject(bookStore)
        }
        .sheet(isPresented: $showCSVUploadSheet) {
            LibrarianCSVUploadView()
                .environmentObject(bookStore)
        }
        .alert("Request Book Deletion", isPresented: $showDeletionConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Send Request", role: .destructive) {
                isProcessingDeletion = true
                Task {
                    let isRequestSuccessful = await bookStore.createDeletionRequest(for: selectedBooks)
                    
                    await MainActor.run {
                        isProcessingDeletion = false
                        if isRequestSuccessful {
                            showDeletionSuccess = true
                            selectedBooks.removeAll()
                            isEditing = false
                        } else {
                            showDeletionError = true
                        }
                    }
                }
            }
        } message: {
            Text("This will send a request to the admin for approval to delete \(selectedBooks.count) book(s). Continue?")
        }
        .alert("Request Sent", isPresented: $showDeletionSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your deletion request has been sent to the admin for approval.")
        }
        .alert("Request Failed", isPresented: $showDeletionError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Failed to send deletion request. Please try again later.")
        }
        .overlay {
            if isProcessingDeletion {
                ZStack {
                    Color.black.opacity(0.4)
                    VStack {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.5)
                        Text("Sending request...")
                            .foregroundColor(.white)
                            .padding(.top, 10)
                    }
                }
                .ignoresSafeArea()
            }
        }
    }
    
    private func searchBook() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedBook = try await GoogleBooksService.fetchBookByISBN(isbn: searchText)
                
                // Update UI on main thread
                DispatchQueue.main.async {
                    self.book = fetchedBook
                    self.isSearching = false
                }
            } catch {
                // Handle error
                DispatchQueue.main.async {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                    self.isSearching = false
                }
            }
        }
    }
    
    private func deleteSelectedBooks() {
        // Show confirmation alert for sending deletion request
        showDeletionConfirmation = true
    }
    
    private func selectAllBooks() {
        if selectedBooks.count == bookStore.books.count {
            // If all books are selected, deselect all
            selectedBooks.removeAll()
        } else {
            // If not all books are selected, select all
            selectedBooks = Set(bookStore.books)
        }
    }
}

// Extracted content from AllBooksView to be embedded
struct AllBooksViewContent: View {
    @EnvironmentObject var bookStore: BookStore
    @State private var isRefreshing = false
    @Binding var isEditing: Bool
    @Binding var selectedBooks: Set<LibrarianBook>
    @Binding var searchQuery: String
    @Binding var selectedGenre: String?
    
    private let genres = ["All", "Science", "Humanities", "Business", "Medicine", "Law",
                         "Education", "Arts", "Religion", "Mathematics", "Technology", "Reference", "Fiction", "Non-Fiction", "Literature"]
    
    private var filteredBooks: [LibrarianBook] {
        var books = bookStore.books
        
        // Apply genre filter
        if let genre = selectedGenre {
            books = books.filter { $0.genre == genre }
        }
        
        // Apply search filter
        if !searchQuery.isEmpty {
            books = books.filter { book in
                book.title.localizedCaseInsensitiveContains(searchQuery) ||
                book.author.joined(separator: " ").localizedCaseInsensitiveContains(searchQuery) ||
                book.ISBN.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        
        return books
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed search bar
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search by title, author, or ISBN...", text: $searchQuery)
                        .textFieldStyle(PlainTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding(10)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(10)
                
                Menu {
                    Button("All", action: { selectedGenre = nil })
                    Divider()
                    ForEach(genres.dropFirst(), id: \.self) { genre in
                        Button(action: { selectedGenre = genre }) {
                            HStack {
                                Text(genre)
                                if selectedGenre == genre {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedGenre ?? "All")
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))
            
            ScrollView {
                if isRefreshing {
                    ProgressView("Refreshing...")
                        .padding()
                }
                
                if filteredBooks.isEmpty {
                    Text("No books found")
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.top, 50)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredBooks) { book in
                            HStack {
                                if isEditing {
                                    Button(action: {
                                        toggleSelection(for: book)
                                    }) {
                                        Image(systemName: selectedBooks.contains(book) ? "checkmark.square.fill" : "square")
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                
                                NavigationLink(destination: BookDetailedView(bookId: book.id)) {
                                    BookListItemView(book: book)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
        }
        .onAppear { refreshBooks() }
    }
    
    private func toggleSelection(for book: LibrarianBook) {
        if selectedBooks.contains(book) {
            selectedBooks.remove(book)
        } else {
            selectedBooks.insert(book)
        }
    }
    
    // Refresh books from database
    private func refreshBooks() {
        isRefreshing = true
        Task {
            await bookStore.loadBooks()
            await MainActor.run {
                isRefreshing = false
            }
        }
    }
}

#Preview {
    AddView()
        .environmentObject(BookStore())
}
