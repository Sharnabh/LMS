import SwiftUI

struct ShelfLocationsView: View {
    @StateObject private var shelfLocationStore = ShelfLocationStore()
    @EnvironmentObject var bookStore: BookStore
    
    @State private var isAddingNew = false
    @State private var newShelfNo = ""
    @State private var searchText = ""
    @State private var selectedShelf: BookShelfLocation? = nil
    @State private var showingShelfDetail = false
    
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
                
                if filteredShelves.isEmpty && !isAddingNew {
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
                                showingShelfDetail = true
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
            .sheet(isPresented: $showingShelfDetail) {
                if let shelf = selectedShelf {
                    ShelfDetailView(shelf: shelf)
                        .environmentObject(bookStore)
                        .environmentObject(shelfLocationStore)
                }
            }
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
    @Environment(\.dismiss) private var dismiss
    let shelf: BookShelfLocation
    
    @EnvironmentObject var bookStore: BookStore
    @EnvironmentObject var shelfLocationStore: ShelfLocationStore
    
    var body: some View {
        NavigationView {
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
                    if shelf.bookID.isEmpty {
                        Text("No books assigned to this shelf")
                            .foregroundColor(.gray)
                            .italic()
                    } else {
                        ForEach(booksOnShelf, id: \.id) { book in
                            NavigationLink(destination: BookDetailedView(bookId: book.id)) {
                                VStack(alignment: .leading) {
                                    Text(book.title)
                                        .font(.headline)
                                    
                                    if !book.author.isEmpty {
                                        Text(book.author.joined(separator: ", "))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Shelf \(shelf.shelfNo)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var booksOnShelf: [LibrarianBook] {
        return bookStore.books.filter { book in
            if let id = book.id {
                return shelf.bookID.contains(id)
            }
            return false
        }
    }
}

#Preview {
    NavigationView {
        ShelfLocationsView()
            .environmentObject(BookStore())
    }
} 