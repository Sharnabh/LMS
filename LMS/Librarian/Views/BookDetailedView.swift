import SwiftUI

struct BookDetailedView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var bookStore: BookStore
    let book: LibrarianBook
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Book cover and basic info
                HStack(alignment: .top, spacing: 20) {
                    // Book cover image with improved display and fill instead of fit
                    if let imageURL = book.imageLink {
                        AsyncImage(url: URL(string: imageURL)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 130, height: 190)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 130, height: 190)
                                    .clipped()
                                    .cornerRadius(8)
                                    .shadow(radius: 5)
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            case .failure:
                                Image(systemName: "book.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 130, height: 190)
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Image(systemName: "book.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 130, height: 190)
                            .foregroundColor(.gray)
                    }
                    
                    // Book details
                    VStack(alignment: .leading, spacing: 8) {
                        Text(book.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .lineLimit(3)
                        
                        if !book.author.isEmpty {
                            Text(book.author.joined(separator: ", "))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let publisher = book.publisher {
                            Text(publisher)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("ISBN: \(book.ISBN)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 8)
                
                // Book stats
                VStack(spacing: 12) {
                    HStack {
                        StatBox(title: "Total Copies", value: "\(book.totalCopies)", icon: "books.vertical.fill", color: .blue)
                        StatBox(title: "Available", value: "\(book.availableCopies)", icon: "book.closed.fill", color: .green)
                    }
                    
                    if let shelfLocation = book.shelfLocation {
                        StatBox(title: "Shelf Location", value: shelfLocation, icon: "mappin.and.ellipse", color: .orange)
                    }
                }
                
                // Description
                if let description = book.Description, !description.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        ExpandableText(description)
                    }
                }
            }
            .padding()
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Book Details")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingEditSheet = true }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditBookFormView(book: book)
        }
        .alert("Delete Book", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                bookStore.deleteBook(book)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this book? This action cannot be undone.")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct CollectionInfoRow: View {
    var label: String
    var value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
        }
    }
}

// Renamed to avoid conflicts with BookDetailView.swift
struct DetailInfoRow: View {
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

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    NavigationView {
        BookDetailedView(book: LibrarianBook(
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
        ))
        .environmentObject(BookStore())
    }
} 
