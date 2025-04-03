import SwiftUI

struct ShelfLocationsView: View {
    @StateObject private var shelfLocationStore = ShelfLocationStore()
    @EnvironmentObject var bookStore: BookStore
    
    @State private var isAddingNew = false
    @State private var newShelfNo = ""
    @State private var searchText = ""
    @State private var selectedShelf: BookShelfLocation? = nil
    @State private var showingShelfDetailSheet = false
    @State private var selectedBookId: UUID? = nil
    @State private var showingBookDetailSheet = false
    @State private var isInitialLoaded = false
    
    private var filteredShelves: [BookShelfLocation] {
        if searchText.isEmpty {
            return shelfLocationStore.shelfLocations
        } else {
            return shelfLocationStore.shelfLocations.filter { shelf in
                shelf.shelfNo.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search shelf locations", text: $searchText)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    if !isInitialLoaded {
                        VStack {
                            ProgressView("Loading shelf locations...")
                            Text("Please wait...")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if filteredShelves.isEmpty && !isAddingNew {
                        VStack(spacing: 20) {
                            Image(systemName: "mappin.slash")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text(searchText.isEmpty ? "No shelf locations found" : "No matching shelf locations")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Button(action: {
                                isAddingNew = true
                            }) {
                                Label("Add Shelf Location", systemImage: "plus")
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .padding()
                        Spacer()
                    } else {
                        List {
                            if isAddingNew {
                                HStack {
                                    TextField("New shelf location (e.g. A12)", text: $newShelfNo)
                                        .autocapitalization(.allCharacters)
                                        .disableAutocorrection(true)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    
                                    Button(action: addNewShelfLocation) {
                                        Text("Add")
                                    }
                                    .disabled(newShelfNo.isEmpty)
                                    
                                    Button(action: {
                                        isAddingNew = false
                                        newShelfNo = ""
                                    }) {
                                        Text("Cancel")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.vertical, 5)
                            }
                            
                            ForEach(filteredShelves) { shelf in
                                Button(action: {
                                    selectedShelf = shelf
                                    
                                    // Pre-load books data so it's ready when sheet appears
                                    Task {
                                        do {
                                            try await Task.sleep(nanoseconds: 50_000_000) // 50ms delay
                                            await bookStore.loadBooks()
                                            showingShelfDetailSheet = true
                                        } catch {
                                            print("Sleep interrupted: \(error)")
                                            showingShelfDetailSheet = true
                                        }
                                    }
                                }) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(shelf.shelfNo)
                                                .font(.headline)
                                            
                                            Text("\(shelf.bookID.count) books")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .onDelete(perform: deleteShelfLocations)
                        }
                        .refreshable {
                            Task {
                                await shelfLocationStore.loadShelfLocations()
                            }
                        }
                    }
                }
                .navigationTitle("Shelf Locations")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            isAddingNew.toggle()
                            if !isAddingNew {
                                newShelfNo = ""
                            }
                        }) {
                            Label(isAddingNew ? "Cancel" : "Add", systemImage: isAddingNew ? "xmark" : "plus")
                        }
                    }
                }
                .onAppear {
                    Task {
                        // Load all data first time
                        isInitialLoaded = false
                        await shelfLocationStore.loadShelfLocations()
                        await bookStore.loadBooks()
                        isInitialLoaded = true
                    }
                }
                .fullScreenCover(isPresented: $showingShelfDetailSheet, onDismiss: {
                    selectedShelf = nil
                }) {
                    if let shelf = selectedShelf {
                        NavigationView {
                            ShelfDetailView(
                                shelf: shelf,
                                onBookSelected: { bookId in
                                    selectedBookId = bookId
                                    showingShelfDetailSheet = false
                                    
                                    // Ensure the book detail is shown after a slight delay
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        showingBookDetailSheet = true
                                    }
                                }
                            )
                            .environmentObject(bookStore)
                            .environmentObject(shelfLocationStore)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button("Done") {
                                        showingShelfDetailSheet = false
                                    }
                                }
                            }
                        }
                    }
                }
                .fullScreenCover(isPresented: $showingBookDetailSheet, onDismiss: {
                    selectedBookId = nil
                    
                    // Only reopen shelf view if we still have a shelf selected
                    if selectedShelf != nil {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingShelfDetailSheet = true
                        }
                    }
                }) {
                    if let bookId = selectedBookId {
                        NavigationView {
                            BookDetailedView(bookId: bookId)
                                .environmentObject(bookStore)
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarLeading) {
                                        Button("Back") {
                                            showingBookDetailSheet = false
                                        }
                                    }
                                }
                        }
                    }
                }
            }
            .navigationTitle("Book Shelf")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func addNewShelfLocation() {
        guard !newShelfNo.isEmpty else { return }
        
        // Check if shelf already exists
        if shelfLocationStore.shelfLocations.contains(where: { $0.shelfNo == newShelfNo }) {
            // Show an alert or handle duplicate case
            return
        }
        
        let newShelf = BookShelfLocation(
            id: UUID(),
            shelfNo: newShelfNo,
            bookID: []
        )
        
        shelfLocationStore.addShelfLocation(newShelf)
        isAddingNew = false
        newShelfNo = ""
    }
    
    private func deleteShelfLocations(at offsets: IndexSet) {
        for index in offsets {
            let shelf = filteredShelves[index]
            shelfLocationStore.deleteShelfLocation(shelf)
        }
    }
}

// View to show details of a specific shelf
struct ShelfDetailView: View {
    let shelf: BookShelfLocation
    var onBookSelected: (UUID) -> Void
    
    @EnvironmentObject var bookStore: BookStore
    @EnvironmentObject var shelfLocationStore: ShelfLocationStore
    
    @State private var isLoading = true
    @State private var booksOnCurrentShelf: [LibrarianBook] = []
    
    var body: some View {
        List {
            Section(header: Text("Shelf Information")) {
                HStack {
                    Text("Shelf Location")
                    Spacer()
                    Text(shelf.shelfNo)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Number of Books")
                    Spacer()
                    Text("\(shelf.bookID.count)")
                        .fontWeight(.semibold)
                }
            }
            
            Section(header: Text("Books on this Shelf")) {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding()
                } else if shelf.bookID.isEmpty {
                    Text("No books assigned to this shelf")
                        .foregroundColor(.gray)
                        .italic()
                } else if booksOnCurrentShelf.isEmpty {
                    Text("Could not find book details")
                        .foregroundColor(.red)
                        .italic()
                } else {
                    ForEach(booksOnCurrentShelf) { book in
                        if let bookId = book.id {
                            Button(action: {
                                onBookSelected(bookId)
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(book.title)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        if !book.author.isEmpty {
                                            Text(book.author.joined(separator: ", "))
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Shelf \(shelf.shelfNo)")
        .refreshable {
            await loadBooksData()
        }
        .onAppear {
            Task {
                await loadBooksData()
            }
        }
    }
    
    private func loadBooksData() async {
        isLoading = true
        print("Loading data for shelf: \(shelf.shelfNo)")
        
        // Force refresh the book store
        await bookStore.loadBooks()
        
        // Get books that are on this shelf
        let shelfBooks = bookStore.books.filter { book in
            if let id = book.id {
                return shelf.bookID.contains(id)
            }
            return false
        }
        
        print("Found \(shelfBooks.count) books on shelf \(shelf.shelfNo)")
        for book in shelfBooks.prefix(3) {
            print("Book on shelf: \(book.title) (ID: \(book.id?.uuidString ?? "nil"))")
        }
        
        booksOnCurrentShelf = shelfBooks
        isLoading = false
    }
}

#Preview {
    NavigationView {
        ShelfLocationsView()
            .environmentObject(BookStore())
    }
}
