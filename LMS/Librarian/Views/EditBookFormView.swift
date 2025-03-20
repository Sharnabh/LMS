import SwiftUI

struct EditBookFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var bookStore: BookStore
    
    let book: LibrarianBook
    @State private var quantity: String
    @State private var shelfLocation: String
    @State private var selectedGenre: String
    @State private var errorMessage: String? = nil
    @State private var showSuccessMessage = false
    
    // List of common book genres
    private let genres = [
        "Fiction", "Science", "Humanities", "Business",
        "Medicine", "Law", "Education", "Arts", "Religion",
        "Mathematics", "Technology", "Reference", "Uncategorized"
    ]
    
    init(book: LibrarianBook) {
        self.book = book
        _quantity = State(initialValue: String(book.totalCopies))
        _shelfLocation = State(initialValue: book.shelfLocation ?? "")
        _selectedGenre = State(initialValue: book.genre)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Book Information")) {
                    HStack(alignment: .top) {
                        if let imageURL = book.imageLink {
                            AsyncImage(url: URL(string: imageURL)) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 120)
                                        .cornerRadius(8)
                                } else {
                                    Image(systemName: "book.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 80, height: 120)
                                        .foregroundColor(.gray)
                                }
                            }
                        } else {
                            Image(systemName: "book.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 120)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(book.title)
                                .font(.headline)
                                .lineLimit(2)
                            
                            if !book.author.isEmpty {
                                Text(book.author.joined(separator: ", "))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Text("ISBN: \(book.ISBN)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Edit Details")) {
                    TextField("Quantity", text: $quantity)
                        .keyboardType(.numberPad)
                    
                    TextField("Shelf Location", text: $shelfLocation)
                        .autocapitalization(.words)
                    
                    Picker("Genre", selection: $selectedGenre) {
                        ForEach(genres, id: \.self) { genre in
                            Text(genre).tag(genre)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Button(action: saveChanges) {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .listRowBackground(Color.appBackground)
                .padding(.vertical)
            }
            .scrollContentBackground(.hidden)
            
            if showSuccessMessage {
                ZStack {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 15) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 60))
                        
                        Text("Changes Saved!")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(25)
                    .background(Color(.systemGray6).opacity(0.95))
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .navigationTitle("Edit Book")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
    
    private func saveChanges() {
        // Validate quantity
        guard let quantityInt = Int(quantity), quantityInt > 0 else {
            errorMessage = "Please enter a valid quantity"
            return
        }
        
        // Validate shelf location
        if shelfLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Please enter a shelf location"
            return
        }
        
        // Create updated book
        var updatedBook = book
        updatedBook = LibrarianBook(
            id: book.id,
            title: book.title,
            author: book.author,
            genre: selectedGenre,
            publicationDate: book.publicationDate,
            totalCopies: quantityInt,
            availableCopies: book.availableCopies,
            ISBN: book.ISBN,
            Description: book.Description,
            shelfLocation: shelfLocation,
            dateAdded: book.dateAdded,
            publisher: book.publisher,
            imageLink: book.imageLink
        )
        
        // Update the book in the store
        bookStore.updateBook(updatedBook)
        
        // Show success message
        withAnimation {
            showSuccessMessage = true
        }
        
        // Wait 1.5 seconds before dismissing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showSuccessMessage = false
            }
            
            // Dismiss the sheet after a short delay to allow the animation to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                dismiss()
            }
        }
    }
}

#Preview {
    EditBookFormView(book: LibrarianBook(
        title: "Sample Book",
        author: ["Author One"],
        genre: "Fiction",
        publicationDate: "2023",
        totalCopies: 1,
        availableCopies: 1,
        ISBN: "9781234567890",
        Description: "Description",
        shelfLocation: "A1",
        dateAdded: Date(),
        publisher: "Publisher",
        imageLink: "https://via.placeholder.com/150x200"
    ))
    .environmentObject(BookStore())
} 
