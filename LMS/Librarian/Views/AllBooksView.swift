import SwiftUI

struct AllBooksView: View {
    @EnvironmentObject var bookStore: BookStore
    @State private var searchText = ""
    @State private var selectedBook: LibrarianBook? = nil
    @State private var showBookDetails = false
    
    var body: some View {
        ZStack {
            // Background color
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search bar
                TextField("Search books...", text: $searchText)
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                
                // Books list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredBooks) { book in
                            BookListItemView(book: book)
                                .onTapGesture {
                                    selectedBook = book
                                    showBookDetails = true
                                }
                        }
                    }
                }
                
                Spacer()
            }
            
            // Navigation link to book details
            NavigationLink(destination:
                Group {
                    if let book = selectedBook {
                        BookDetailedView(bookId: book.id)
                    } else {
                        EmptyView()
                    }
                },
                isActive: $showBookDetails
            ) {
                EmptyView()
            }
            .hidden()
        }
        .navigationTitle("Added Books")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // Filtered books based on search text
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
}

// Individual book list item view
struct BookListItemView: View {
    let book: LibrarianBook
    
    var body: some View {
        HStack(spacing: 0) {
            // Book cover - sized to match the image exactly
            if let imageURL = book.imageLink {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 90, height: 110)
                            .clipped()
                    case .failure, .empty:
                        Image(systemName: "book.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 90, height: 110)
                            .foregroundColor(.yellow)
                            .background(Color.gray.opacity(0.1))
                    @unknown default:
                        Image(systemName: "book.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 90, height: 110)
                            .foregroundColor(.yellow)
                            .background(Color.gray.opacity(0.1))
                    }
                }
            } else {
                Image(systemName: "book.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 90, height: 110)
                    .foregroundColor(.yellow)
                    .background(Color.gray.opacity(0.1))
            }
            
            // White background card (shorter than the book image)
            ZStack {
                // White background
                Rectangle()
                    .fill(Color.white)
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: -5, y: 0)
                    .frame(height: 80)
                
                // Content on white card
                HStack(spacing: 0) {
                    // Book info (title and author)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.title)
                            .font(.headline)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        
                        Text(book.author.first ?? "Unknown Author")
                            .font(.subheadline)
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 16)
                    
                    // Quantity indicator
//                    VStack(spacing: 4) {
//                        Image(systemName: "tray.fill")
//                            .foregroundColor(.black)
//                        
//                        Text("\(book.quantity)")
//                            .font(.system(size: 22, weight: .bold))
//                            .foregroundColor(.black)
//                    }
                    .padding(8)
                    //.background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.trailing, 12)
                }
            }
            .padding(.leading, -20) // Overlap the book cover more to match the image
            .padding(.trailing, 5)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

#Preview {
    NavigationView {
        AllBooksView()
            .environmentObject(BookStore())
    }
} 
