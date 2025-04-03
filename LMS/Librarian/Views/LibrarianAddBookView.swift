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
    @State private var isPredictingGenre = false
    @State private var showGenrePrediction = false
    @State private var predictedGenre: String? = nil
    @State private var isbnWasAutoFilled = false
    @State private var yearWasAutoFilled = false
    @State private var authorWasAutoFilled = false
    
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
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Genre")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        
                        Picker("", selection: $genre) {
                            Text("Select a genre").tag("")
                            ForEach(genres, id: \.self) { genre in
                                Text(genre).tag(genre)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                        
                        if let predictedGenre = predictedGenre, showGenrePrediction {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                    
                                    Text("AI suggestion: ")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                    
                                    Text(predictedGenre)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Button("Use") {
                                        withAnimation {
                                            genre = predictedGenre
                                            showGenrePrediction = false
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundColor(.accentColor)
                                    .padding(.vertical, 2)
                                    .padding(.horizontal, 8)
                                    .background(Color.accentColor.opacity(0.1))
                                    .cornerRadius(4)
                                }
                                .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(8)
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(8)
                            .padding(.top, 4)
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
                            .foregroundColor(.accentColor)
                        }
                    }
                }
                
                // Add Auto-Fill with AI button above the AI Prediction section
                if !showGenrePrediction {
                    Section {
                        if isPredictingGenre {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Predicting book details with AI...")
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 8)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 4)
                        } else {
                            Button(action: {
                                predictGenre()
                            }) {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.blue)
                                    Text("Auto-Fill with AI")
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 4)
                            }
                            .disabled(title.isEmpty && author.isEmpty)
                            .opacity((title.isEmpty && author.isEmpty) ? 0.5 : 1.0)
                        }
                    }
                    .listRowBackground(Color.accentColor.opacity(0.1))
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
                // Automatically predict genre if title or ISBN is provided
                if !title.isEmpty || !isbn.isEmpty {
                    predictGenre()
                }
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
                if shelfLocationStore.shelfLocations.count == 1 {
                    shelfLocation = shelfLocationStore.shelfLocations[0].shelfNo
                }
            }
        }
    }
    
    private func addNewShelf() {
        guard !newShelfName.isEmpty else { return }
        
        Task {
            do {
                // Check if librarian is disabled
                if try await LibrarianService.checkLibrarianStatus() {
                    return
                }
                
                if !shelfLocationStore.shelfLocations.contains(where: { $0.shelfNo == newShelfName }) {
                    let newShelf = BookShelfLocation(
                        id: UUID(),
                        shelfNo: newShelfName,
                        bookID: []
                    )
                    
                    shelfLocationStore.addShelfLocation(newShelf)
                    
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    await shelfLocationStore.loadShelfLocations()
                    
                    await MainActor.run {
                        shelfLocation = newShelfName
                        showAddNewShelfSheet = false
                        newShelfName = ""
                    }
                } else {
                    shelfLocation = newShelfName
                    showAddNewShelfSheet = false
                    newShelfName = ""
                }
            } catch {
                print("Error adding new shelf: \(error)")
            }
        }
    }
    
    private func addBook() {
        isLoading = true
        
        Task {
            do {
                // Check if librarian is disabled
                if try await LibrarianService.checkLibrarianStatus() {
                    return
                }
                
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
    
    private func predictGenre() {
        isPredictingGenre = true
        
        Task {
            do {
                // Check if librarian is disabled
                if try await LibrarianService.checkLibrarianStatus() {
                    await MainActor.run {
                        isPredictingGenre = false
                    }
                    return
                }
                
                // Parse the author string into an array
                let authorArray = author.split(separator: ";").map { String($0.trimmingCharacters(in: .whitespaces)) }
                
                // Use GenrePredictionService to predict book details
                let prediction = try await GenrePredictionService.shared.predictGenre(
                    title: title,
                    description: "", 
                    authors: authorArray,
                    availableGenres: genres
                )
                
                await MainActor.run {
                    withAnimation {
                        predictedGenre = prediction.genre
                        showGenrePrediction = true
                        
                        // Update ISBN
                        if !prediction.isbn.isEmpty {
                            isbn = prediction.isbn
                            isbnWasAutoFilled = true
                        }
                        
                        // Update publication year
                        if !prediction.publicationYear.isEmpty {
                            publicationDate = prediction.publicationYear
                            yearWasAutoFilled = true
                        }
                        
                        // Update author if it's different from current value
                        if !prediction.author.isEmpty && prediction.author != author {
                            author = prediction.author
                            authorWasAutoFilled = true
                        }
                        
                        isPredictingGenre = false
                    }
                }
            } catch {
                await MainActor.run {
                    isPredictingGenre = false
                    alertMessage = "Failed to predict book details: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}

#Preview {
    LibrarianAddBookView()
        .environmentObject(BookStore())
} 
