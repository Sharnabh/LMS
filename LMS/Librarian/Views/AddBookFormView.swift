import SwiftUI

struct AddBookFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var bookStore: BookStore
    
    // Add ShelfLocationStore to get available shelves
    @StateObject private var shelfLocationStore = ShelfLocationStore()
    
    var book: LibrarianBook
    @State private var quantity: String = "1"
    @State private var shelfLocation: String = ""
    @State private var selectedGenre: String = "Uncategorized"
    @State private var errorMessage: String? = nil
    @State private var showSuccessMessage = false
    @State private var isLoadingShelves = true
    @State private var showAddNewShelfSheet = false
    @State private var newShelfName = ""
    @State private var alertMessage: String? = nil
    @State private var showAlert = false
    
    // List of common book genres
    private let genres = [
        "Science", "Humanities", "Business", "Medicine", "Law", 
        "Education", "Arts", "Religion", "Mathematics", "Technology", "Reference", "Fiction", "Non-Fiction", "Literature"
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
                        
                        // Replace TextField with Picker for shelf locations
                        if isLoadingShelves {
                            HStack {
                                Text("Loading shelf locations...")
                                Spacer()
                                ProgressView()
                            }
                        } else {
                            if shelfLocationStore.shelfLocations.isEmpty {
                                HStack {
                                    Text("No shelves available")
                                    Spacer()
                                    Button("Add New") {
                                        showAddNewShelfSheet = true
                                    }
                                }
                            } else {
                                Picker("Shelf Location", selection: $shelfLocation) {
                                    Text("Select a shelf").tag("")
                                    ForEach(shelfLocationStore.shelfLocations, id: \.id) { shelf in
                                        Text(shelf.shelfNo).tag(shelf.shelfNo)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                
                                Button("Add New Shelf") {
                                    showAddNewShelfSheet = true
                                }
                                .font(.caption)
                                .foregroundColor(.accentColor)
                            }
                        }
                        
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
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowBackground(Color.appBackground)
                    .padding(.vertical)
                    .disabled(shelfLocation.isEmpty && !shelfLocationStore.shelfLocations.isEmpty)
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
            .onAppear {
                // Load shelf locations when view appears
                selectedGenre = book.genre
                loadShelfLocations()
            }
            .sheet(isPresented: $showAddNewShelfSheet) {
                addNewShelfView
            }
        }
    }
    
    // New view for adding a shelf
    private var addNewShelfView: some View {
        NavigationView {
            Form {
                Section(header: Text("Add New Shelf Location")) {
                    TextField("Shelf Name", text: $newShelfName)
                }
                
                Button("Add Shelf") {
                    addNewShelf()
                }
                .disabled(newShelfName.isEmpty)
                .frame(maxWidth: .infinity)
                .padding()
                .background(newShelfName.isEmpty ? Color.gray : Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding()
            }
            .navigationTitle("New Shelf")
            .navigationBarItems(trailing: Button("Cancel") {
                showAddNewShelfSheet = false
                newShelfName = ""
            })
        }
    }
    
    private func loadShelfLocations() {
        isLoadingShelves = true
        Task {
            await shelfLocationStore.loadShelfLocations()
            
            await MainActor.run {
                isLoadingShelves = false
                // If there's only one shelf, select it automatically
                if shelfLocationStore.shelfLocations.count == 1 {
                    shelfLocation = shelfLocationStore.shelfLocations[0].shelfNo
                }
            }
        }
    }
    
    private func addNewShelf() {
        guard !newShelfName.isEmpty else { return }
        
        Task {
            // Check if librarian is disabled
            if try await LibrarianService.checkLibrarianStatus() {
                await MainActor.run {
                    alertMessage = "Your account has been disabled. Please contact the administrator."
                    showAlert = true
                }
                return
            }
            
            // Check if shelf already exists
            if !shelfLocationStore.shelfLocations.contains(where: { $0.shelfNo == newShelfName }) {
                let newShelf = BookShelfLocation(
                    id: UUID(),
                    shelfNo: newShelfName,
                    bookID: []
                )
                
                shelfLocationStore.addShelfLocation(newShelf)
                
                // Wait briefly for the new shelf to be added to the database
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 sec
                await shelfLocationStore.loadShelfLocations()
                
                await MainActor.run {
                    shelfLocation = newShelfName
                    showAddNewShelfSheet = false
                    newShelfName = ""
                }
            } else {
                // Just select the existing shelf and close
                shelfLocation = newShelfName
                showAddNewShelfSheet = false
                newShelfName = ""
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
            errorMessage = "Please select a shelf location"
            return
        }
        
        Task {
            // Check if librarian is disabled
            if try await LibrarianService.checkLibrarianStatus() {
                await MainActor.run {
                    alertMessage = "Your account has been disabled. Please contact the administrator."
                    showAlert = true
                }
                return
            }
            
            // Create a new book with the quantity and shelf location
            let newBook = LibrarianBook(
                id: UUID(), // Explicitly create a UUID
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
            
            // Add the book to the database directly for better error tracking
            do {
                print("Adding book to collection with ID: \(newBook.id?.uuidString ?? "nil")")
                
                // Add the book to database
                let success = try await bookStore.dataController.addBook(newBook)
                
                if success {
                    // Refresh the book list to verify addition
                    await bookStore.loadBooks()
                    
                    // Verify the book was actually added
                    let addedBook = bookStore.books.first { $0.ISBN == newBook.ISBN && $0.shelfLocation == shelfLocation }
                    
                    if addedBook != nil {
                        print("Book successfully verified in database: \(newBook.title)")
                        
                        // Show success message on main thread
                        await MainActor.run {
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
                    } else {
                        await MainActor.run {
                            errorMessage = "Book was processed but not found in database. Please try again."
                        }
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "Failed to add book to database"
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error: \(error.localizedDescription)"
                }
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
