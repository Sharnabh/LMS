import SwiftUI

struct LibrarianAddBookView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var bookStore: BookStore
    @StateObject private var shelfLocationStore = ShelfLocationStore()
    
    @State private var title = ""
    @State private var author = ""
    @State private var genre = "Science"
    @State private var isbn = ""
    @State private var publicationDate = ""
    @State private var totalCopies = "1"
    @State private var shelfLocation = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    @State private var isLoading = false
    @State private var isLoadingShelves = true
    @State private var showAddNewShelfSheet = false
    @State private var newShelfName = ""
    
    let genres = ["Science", "Humanities", "Business", "Medicine", "Law", "Education", "Arts", "Religion", "Mathematics", "Technology", "Reference", "Fiction", "Non-Fiction", "Literature"]
    
    private var isValid: Bool {
        !title.isEmpty && 
        !author.isEmpty && 
        !genre.isEmpty && 
        !isbn.isEmpty && isbn.count >= 10 &&
        !publicationDate.isEmpty && 
        !totalCopies.isEmpty &&
        !shelfLocation.isEmpty &&
        Int(publicationDate) != nil &&
        Int(totalCopies) != nil &&
        Int(totalCopies)! > 0
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Book Information")) {
                    TextField("Title", text: $title)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Author(s)", text: $author)
                        Text("For multiple authors, separate with semicolons (;)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("Genre", selection: $genre) {
                        ForEach(genres, id: \.self) { genre in
                            Text(genre).tag(genre)
                        }
                    }
                    
                    TextField("ISBN", text: $isbn)
                        .keyboardType(.numberPad)
                    
                    TextField("Publication Year", text: $publicationDate)
                        .keyboardType(.numberPad)
                    
                    TextField("Total Copies", text: $totalCopies)
                        .keyboardType(.numberPad)
                    
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
                            .foregroundColor(.blue)
                        }
                    }
                }
                
                if !isValid {
                    Section {
                        Text("Please fill in all required fields correctly")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add Book")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Add") {
                    addBook()
                }
                .disabled(!isValid)
            )
            .overlay(
                Group {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.2))
                    }
                }
            )
            .onAppear {
                loadShelfLocations()
            }
            .sheet(isPresented: $showAddNewShelfSheet) {
                addNewShelfView
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(isSuccess ? "Success" : "Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if isSuccess {
                        dismiss()
                    }
                }
            )
        }
    }
    
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
                .background(newShelfName.isEmpty ? Color.gray : Color.blue)
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
                if shelfLocationStore.shelfLocations.count == 1 {
                    shelfLocation = shelfLocationStore.shelfLocations[0].shelfNo
                }
            }
        }
    }
    
    private func addNewShelf() {
        guard !newShelfName.isEmpty else { return }
        
        if !shelfLocationStore.shelfLocations.contains(where: { $0.shelfNo == newShelfName }) {
            let newShelf = BookShelfLocation(
                id: UUID(),
                shelfNo: newShelfName,
                bookID: []
            )
            
            shelfLocationStore.addShelfLocation(newShelf)
            
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                await shelfLocationStore.loadShelfLocations()
                
                await MainActor.run {
                    shelfLocation = newShelfName
                    showAddNewShelfSheet = false
                    newShelfName = ""
                }
            }
        } else {
            shelfLocation = newShelfName
            showAddNewShelfSheet = false
            newShelfName = ""
        }
    }
    
    private func addBook() {
        isLoading = true
        
        let authorArray = author.split(separator: ";").map { String($0.trimmingCharacters(in: .whitespaces)) }
        
        let newBook = LibrarianBook(
            id: UUID(),
            title: title,
            author: authorArray,
            genre: genre,
            publicationDate: publicationDate,
            totalCopies: Int(totalCopies) ?? 1,
            availableCopies: Int(totalCopies) ?? 1,
            ISBN: isbn,
            Description: nil,
            shelfLocation: shelfLocation,
            dateAdded: Date(),
            publisher: nil,
            imageLink: nil
        )
        
        Task {
            do {
                let success = try await bookStore.dataController.addBook(newBook)
                
                if success {
                    await bookStore.loadBooks()
                    
                    let bookWasAdded = bookStore.books.contains { $0.ISBN == isbn }
                    
                    // Update the shelf location with the book ID
                    if let bookID = newBook.id {
                        let shelfUpdateSuccess = await shelfLocationStore.addBookToShelf(bookID: bookID, shelfNo: shelfLocation)
                        
                        if !shelfUpdateSuccess {
                            print("Warning: Book was added but shelf location update failed")
                        }
                    }
                    
                    await MainActor.run {
                        if bookWasAdded {
                            isSuccess = true
                            alertMessage = "Book added successfully and verified in database"
                        } else {
                            isSuccess = false
                            alertMessage = "Book appears to be added but not found in database. Please check and try again."
                        }
                        showAlert = true
                        isLoading = false
                    }
                } else {
                    await MainActor.run {
                        isSuccess = false
                        alertMessage = "Failed to add book to database"
                        showAlert = true
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    isSuccess = false
                    alertMessage = "Error: \(error.localizedDescription)"
                    showAlert = true
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    LibrarianAddBookView()
        .environmentObject(BookStore())
} 
