import SwiftUI

struct AllBooksWithoutShelfLocationView: View {
    @EnvironmentObject var bookStore: BookStore
    @State private var isRefreshing = false
    @State private var searchText = ""
    @State private var selectedBook: LibrarianBook? = nil
    
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
                                    print("Selected book: \(book.title), ID: \(book.id?.uuidString ?? "nil")")
                                    selectedBook = book
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
            .sheet(item: $selectedBook, onDismiss: {
                print("Sheet dismissed")
            }) { book in
                AssignShelfLocationView(book: book)
                    .environmentObject(bookStore)
            }
        }
        .onAppear {
            print("AllBooksWithoutShelfLocationView appeared")
            print("Books without location: \(filteredBooks.count)")
        }
    }
}

// New component that adds an assign button to the standard BookCardView
struct BookCardWithAssignButton: View {
    let book: LibrarianBook
    let onAssignTap: () -> Void
    @State private var navigateToDetail = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Custom card that doesn't include a NavigationLink
            CustomBookCard(book: book)
                .onTapGesture {
                    // Set the flag to navigate to detail view
                    navigateToDetail = true
                }
            
            // The location button with clear background to prevent NavigationLink activation
            ZStack {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 50, height: 50)
                
                Button(action: {
                    // Only perform the assign action, don't navigate
                    onAssignTap()
                }) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
            }
            .padding(8)
        }
        .background(
            ZStack {
                // Use the modern NavigationLink style but keep it hidden like before
                NavigationLink(value: book.id) {
                    EmptyView()
                }
                .opacity(0)
            }
        )
        // This modifier detects when navigateToDetail changes and programmatically triggers navigation
        .onChange(of: navigateToDetail) { oldValue, newValue in
            if newValue {
                // Reset the flag when navigation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    navigateToDetail = false
                }
            }
        }
    }
}

// Custom book card without navigation link
struct CustomBookCard: View {
    let book: LibrarianBook
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Book cover
            if let imageURL = book.imageLink {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 150)
                            .clipped()
                    case .failure, .empty:
                        Image(systemName: "book.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(20)
                            .frame(height: 150)
                            .foregroundColor(.gray)
                    @unknown default:
                        Image(systemName: "book.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(20)
                            .frame(height: 150)
                            .foregroundColor(.gray)
                    }
                }
                .frame(height: 160)
                .frame(maxWidth: .infinity)
            } else {
                Image(systemName: "book.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(20)
                    .frame(height: 150)
                    .foregroundColor(.gray)
                    .frame(height: 160)
                    .frame(maxWidth: .infinity)
            }
            
            // Book title and author
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                if !book.author.isEmpty {
                    Text(book.author.first ?? "")
                        .font(.subheadline)
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Label("Qty: \(book.totalCopies)", systemImage: "number")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    if let location = book.shelfLocation {
                        Label(location, systemImage: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 6)
            .padding(.top, 4)
            
            Spacer()
        }
        .frame(width: 170, height: 240)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        AllBooksWithoutShelfLocationView()
            .environmentObject(BookStore())
            .navigationDestination(for: UUID?.self) { bookId in
                if let id = bookId {
                    BookDetailedView(bookId: id)
                        .environmentObject(BookStore())
                }
            }
    }
} 
