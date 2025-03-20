import SwiftUI

struct AddBookFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var bookStore: BookStore
    
    var book: LibrarianBook
    @State private var quantity: String = "1"
    @State private var shelfLocation: String = ""
    @State private var selectedGenre: String = "Uncategorized"
    @State private var errorMessage: String? = nil
    @State private var showSuccessMessage = false
    
    // List of common book genres
    private let genres = [
        "Fiction", "Science", "Humanities", "Business",
        "Medicine", "Law", "Education", "Arts", "Religion",
        "Mathematics", "Technology", "Reference", "Uncategorized"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                Form {
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
                                            .clipped()
                                    } else {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 80, height: 120)
                                            .cornerRadius(8)
                                    }
                                }
                                .padding(.trailing, 8)
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
                    
                    Section(header: Text("Add to Collection")) {
                        TextField("Quantity", text: $quantity)
                            .keyboardType(.numberPad)
                        
                        TextField("Shelf Location", text: $shelfLocation)
                            .autocapitalization(.words)
                        
                        // Genre Dropdown
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
                    
                    Button(action: addBookToCollection) {
                        Text("Add to Collection")
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
                .scrollContentBackground(.hidden) // Hide default Form background on iOS 16+
                
                // Success message overlay
                if showSuccessMessage {
                    ZStack {
                        Color.black.opacity(0.4)
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 15) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 60))
                            
                            Text("Successfully Added!")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(book.title)
                                .font(.callout)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 250)
                                .lineLimit(2)
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
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addBookToCollection() {
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
        
        // Create a new book with the quantity and shelf location
        let newBook = LibrarianBook(
            title: book.title,
            author: book.author,
            genre: selectedGenre,
            publicationDate: book.publicationDate,
            totalCopies: quantityInt,
            availableCopies: quantityInt,
            ISBN: book.ISBN,
            Description: book.Description,
            shelfLocation: shelfLocation,
            dateAdded: Date(),
            publisher: book.publisher,
            imageLink: book.imageLink
        )
        
        // Add the book to the store
        bookStore.addBook(newBook)
        
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
    AddBookFormView(book: LibrarianBook(
        title: "Sample Book",
        author: ["Author One"],
        genre: "Fiction",
        publicationDate: "2023",
        totalCopies: 1,
        availableCopies: 1,
        ISBN: "9781234567890",
        Description: "Description",
        shelfLocation: nil,
        dateAdded: Date(),
        publisher: "Publisher",
        imageLink: "https://via.placeholder.com/150x200"
    ))
    .environmentObject(BookStore())
} 
