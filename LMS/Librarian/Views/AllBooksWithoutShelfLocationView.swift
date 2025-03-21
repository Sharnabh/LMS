import SwiftUI

struct AllBooksWithoutShelfLocationView: View {
    @EnvironmentObject var bookStore: BookStore
    @State private var isRefreshing = false
    @State private var searchText = ""
    @State private var selectedBook: LibrarianBook? = nil
    @State private var showingAssignSheet = false
    
    private var filteredBooks: [LibrarianBook] {
        let booksWithoutLocation = bookStore.books.filter { $0.shelfLocation == nil || $0.shelfLocation?.isEmpty == true }
        
        if searchText.isEmpty {
            return booksWithoutLocation
        } else {
            return booksWithoutLocation.filter { book in
                book.title.lowercased().contains(searchText.lowercased()) ||
                book.author.joined(separator: " ").lowercased().contains(searchText.lowercased()) ||
                book.ISBN.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    // Grid layout with adaptive columns
    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search books", text: $searchText)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                if filteredBooks.isEmpty {
                    Spacer()
                    VStack {
                        Image(systemName: "book.closed")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text(searchText.isEmpty ? "No books need a shelf location" : "No results found")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.top)
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Text("Clear Search")
                                    .foregroundColor(.blue)
                            }
                            .padding()
                        }
                    }
                    Spacer()
                } else {
                    // Book grid
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(filteredBooks) { book in
                                BookCardWithAssignButton(book: book) {
                                    selectedBook = book
                                    showingAssignSheet = true
                                }
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        isRefreshing = true
                        await bookStore.loadBooks()
                        isRefreshing = false
                    }
                }
            }
            .navigationTitle("Needs Shelf Location")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAssignSheet) {
                if let book = selectedBook {
                    AssignShelfLocationView(book: book)
                }
            }
        }
    }
}

// New component that adds an assign button to the standard BookCardView
struct BookCardWithAssignButton: View {
    let book: LibrarianBook
    let onAssignTap: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            BookCardView(book: book)
            
            Button(action: onAssignTap) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
            .padding(8)
        }
    }
}

#Preview {
    NavigationView {
        AllBooksWithoutShelfLocationView()
            .environmentObject(BookStore())
    }
} 