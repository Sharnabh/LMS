import SwiftUI

struct BookCardView: View {
    let book: LibrarianBook
    
    var body: some View {
        NavigationLink(destination: BookDetailedView(bookId: book.id)) {
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
                            .foregroundColor(.accentColor)
                        
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
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    BookCardView(book: LibrarianBook(
        title: "The Design of Everyday Things",
        author: ["Don Norman"],
        genre: "Design",
        publicationDate: "2013",
        totalCopies: 2,
        availableCopies: 2,
        ISBN: "9780465050659",
        Description: "A fascinating book about design",
        shelfLocation: "A12",
        dateAdded: Date(),
        publisher: "Basic Books",
        imageLink: "https://via.placeholder.com/150x200"
    ))
    .padding()
    .background(Color.gray.opacity(0.1))
} 
