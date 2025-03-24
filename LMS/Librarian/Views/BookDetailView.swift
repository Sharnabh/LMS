import SwiftUI

struct BookDetailView: View {
    let book: LibrarianBook
    let showAddToCollectionButton: Bool
    @State private var showingAddForm = false
    @EnvironmentObject var bookStore: BookStore
    
    init(book: LibrarianBook, showAddToCollectionButton: Bool = true) {
        self.book = book
        self.showAddToCollectionButton = showAddToCollectionButton
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Book cover image with fill instead of fit
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
                
                // Book info
                VStack(alignment: .leading, spacing: 16) {
                    Text(book.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if !book.author.isEmpty {
                        Text(book.author.joined(separator: ", "))
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let publisher = book.publisher {
                        InfoRow(label: "Publisher", value: publisher)
                    }
                    
                    InfoRow(label: "ISBN", value: book.ISBN)
                    
                    if let description = book.Description {
                        Text("Description")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        Text(description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                if showAddToCollectionButton {
                    Button(action: {
                        showingAddForm = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add to Collection")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.top, 20)
                    }
                }
            }
            .padding()
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Book Details")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAddForm) {
            AddBookFormView(book: book)
        }
    }
}

struct InfoRow: View {
    var label: String
    var value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text("\(label):")
                .fontWeight(.semibold)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    VStack {
        // Preview with Add to Collection button
        NavigationView {
            BookDetailView(book: LibrarianBook(
                title: "Sample Book",
                author: ["Author One", "Author Two"],
                genre: "Fiction",
                publicationDate: "2023",
                totalCopies: 1,
                availableCopies: 1,
                ISBN: "9781234567890",
                Description: "This is a sample description for the book. It contains information about the book's content and other relevant details that a reader might find useful.",
                shelfLocation: "A1",
                dateAdded: Date(),
                publisher: "Sample Publisher",
                imageLink: "https://via.placeholder.com/150x200"
            ), showAddToCollectionButton: true)
            .environmentObject(BookStore())
        }
        .previewDisplayName("With Add to Collection Button")
        
        // Preview without Add to Collection button
        NavigationView {
            BookDetailView(book: LibrarianBook(
                title: "Sample Book",
                author: ["Author One", "Author Two"],
                genre: "Fiction",
                publicationDate: "2023",
                totalCopies: 1,
                availableCopies: 1,
                ISBN: "9781234567890",
                Description: "This is a sample description for the book. It contains information about the book's content and other relevant details that a reader might find useful.",
                shelfLocation: "A1",
                dateAdded: Date(),
                publisher: "Sample Publisher",
                imageLink: "https://via.placeholder.com/150x200"
            ), showAddToCollectionButton: false)
            .environmentObject(BookStore())
        }
        .previewDisplayName("Without Add to Collection Button")
    }
} 
