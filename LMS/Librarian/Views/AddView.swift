import SwiftUI
import AVFoundation

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
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Toggle between Add and View sections
                    Picker("View Mode", selection: $showingAddSection) {
                        Text("View Books").tag(false)
                        Text("Add Books").tag(true)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    if showingAddSection {
                        // Original Add Books section
                        // Search bar section
                        HStack(spacing: 0) {
                            // Search field
                            TextField("ISBN, Title, Author", text: $searchText)
                                .padding(10)
                                .background(Color.white)
                                .cornerRadius(16)
                                .padding(.vertical, 10)
                                .padding(.leading, 16)
                            
                            // Search button
                            Button(action: {
                                searchBook()
                            }) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "magnifyingglass")
                                            .foregroundColor(.white)
                                    )
                            }
                            .padding(.leading, 8)
                            .padding(.trailing, 16)
                            .disabled(searchText.isEmpty || isSearching)
                        }
                        
                        if isSearching {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, 5)
                                Text("Searching...")
                            }
                            .padding(.top, 10)
                        }
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding(.top, 5)
                        }
                        
                        // Content area
                        if let book = book {
                            BookDetailView(book: book)
                        } else {
                            VStack {
                                Spacer()
                                
                                VStack(spacing: 20) {
                                    // Book icon
                                    Image(systemName: "book.pages")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.gray)
                                    
                                    // Instruction text
                                    Text("Enter an ISBN or scan a barcode to\nadd books")
                                        .font(.system(size: 16))
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                            }
                        }
                    } else {
                        // Embedded AllBooksView
                        AllBooksViewContent()
                            .environmentObject(bookStore)
                    }
                }
                
                // Barcode scanner button at bottom right - only show in Add mode
                if showingAddSection {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                showScanner = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 60, height: 60)
                                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    
                                    Image(systemName: "barcode.viewfinder")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 25, height: 25)
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.trailing, 24)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            .navigationTitle("Add Books")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if showingAddSection {
                        // Show plus menu when in Add Books mode
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
                    } else {
                        // Show standard Edit button when in View Books mode
                        EditButton()
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
                    scannedCode = "" // Reset for next scan
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
}

// Extracted content from AllBooksView to be embedded
struct AllBooksViewContent: View {
    @EnvironmentObject var bookStore: BookStore
    @State private var searchText = ""
    @State private var selectedBook: LibrarianBook? = nil
    @State private var showBookDetails = false
    @State private var isRefreshing = false
    @State private var selectedGenre: String? = nil
    @State private var showGenreFilter = false
    
    // Available genres in the project
    private let genres = ["All", "Science", "Humanities", "Business", "Medicine", "Law",
                         "Education", "Arts", "Religion", "Mathematics", "Technology", "Reference"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar with filter button
            HStack {
                TextField("Search books...", text: $searchText)
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(8)
                
                // Filter button - using standard menu for better HIG compliance
                Menu {
                    Button("All", action: { selectedGenre = nil })
                    
                    Divider()
                    
                    ForEach(genres.dropFirst(), id: \.self) { genre in
                        Button(action: {
                            selectedGenre = genre
                        }) {
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
                            .foregroundColor(.gray)
                    }
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
            
            // Books list
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
                            NavigationLink(destination: BookDetailedView(bookId: book.id)) {
                                BookListItemView(book: book)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
        .onAppear {
            refreshBooks()
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
    
    // Filtered books based on search text and selected genre
    private var filteredBooks: [LibrarianBook] {
        var books = bookStore.books
        
        // Apply genre filter if selected
        if let genre = selectedGenre {
            books = books.filter { $0.genre == genre }
        }
        
        // Apply search text filter
        if !searchText.isEmpty {
            books = books.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                book.author.joined(separator: " ").localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return books
    }
}

#Preview {
    AddView()
        .environmentObject(BookStore())
}
