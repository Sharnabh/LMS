import SwiftUI

struct AddView: View {
    @EnvironmentObject private var bookStore: BookStore
    @State private var searchText: String = ""
    @State private var book: LibrarianBook? = nil
    @State private var isSearching = false
    @State private var errorMessage: String? = nil
    @State private var showScanner = false
    @State private var showAddBookSheet = false
    @State private var showCSVUploadSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar section
                    HStack(spacing: 0) {
                        // Search field
                        TextField("ISBN, Title, Autor", text: $searchText)
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(20)
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
                }
                
                // Barcode scanner button at bottom right
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 60, height: 60)
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                            
                            Button(action: {
                                showScanner = true
                            }) {
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
            .navigationTitle("Add Books")
            .navigationBarTitleDisplayMode(.large)
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
            .onChange(of: showScanner) { newValue in
                if newValue == true {
                    // In a real app, this would be the result from a barcode scanner
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        searchText = "9781788294669"  // Example ISBN
                        showScanner = false
                        searchBook()
                    }
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

#Preview {
    AddView()
} 
