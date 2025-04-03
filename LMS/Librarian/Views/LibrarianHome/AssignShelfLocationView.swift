import SwiftUI

struct AssignShelfLocationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var bookStore: BookStore
    @StateObject private var shelfLocationStore = ShelfLocationStore()
    
    let book: LibrarianBook
    @State private var shelfLocation = ""
    @State private var isUpdating = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Book Details")) {
                    Text(book.title)
                        .font(.headline)
                    
                    if !book.author.isEmpty {
                        Text("By: \(book.author.joined(separator: ", "))")
                            .font(.subheadline)
                    }
                    
                    if let existingLocation = book.shelfLocation, !existingLocation.isEmpty {
                        Text("Current Location: \(existingLocation)")
                            .foregroundColor(.blue)
                    } else {
                        Text("No current shelf location")
                            .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("Assign Shelf Location")) {
                    HStack {
                        TextField("Enter shelf location (e.g. A12)", text: $shelfLocation)
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                        
                        Button(action: {
                            assignShelfLocation()
                        }) {
                            Text("Assign")
                        }
                        .disabled(shelfLocation.isEmpty || isUpdating)
                    }
                }
                
                Section(header: Text("Existing Shelf Locations")) {
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if shelfLocationStore.shelfLocations.isEmpty {
                        Text("No shelf locations found")
                            .foregroundColor(.gray)
                    } else {
                        List(shelfLocationStore.shelfLocations) { location in
                            Button(action: {
                                shelfLocation = location.shelfNo
                            }) {
                                HStack {
                                    Text(location.shelfNo)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("\(location.bookID.count) books")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Assign Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK") {
                    if alertMessage.contains("successfully") {
                        dismiss()
                    }
                }
            }
            .overlay(
                Group {
                    if isUpdating {
                        ProgressView("Updating...")
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .shadow(radius: 10)
                    }
                }
            )
            .onAppear {
                // Debug prints
                print("AssignShelfLocationView appeared")
                print("Book: \(book.title), ID: \(book.id?.uuidString ?? "nil")")
                
                // Manually load shelf locations when view appears
                Task {
                    isLoading = true
                    await shelfLocationStore.loadShelfLocations()
                    
                    await MainActor.run {
                        isLoading = false
                        print("Loaded \(shelfLocationStore.shelfLocations.count) shelf locations")
                        
                        // Pre-fill with existing location if available
                        if let existingLocation = book.shelfLocation, !existingLocation.isEmpty {
                            shelfLocation = existingLocation
                            print("Pre-filled with existing location: \(existingLocation)")
                        }
                    }
                }
            }
        }
    }
    
    private func assignShelfLocation() {
        guard !shelfLocation.isEmpty else { return }
        
        isUpdating = true
        print("Attempting to assign shelf location: \(shelfLocation)")
        
        Task {
            // Check if librarian is disabled
            if try await LibrarianService.checkLibrarianStatus() {
                await MainActor.run {
                    isUpdating = false
                    alertMessage = "Your account has been disabled. Please contact the administrator."
                    showAlert = true
                }
                return
            }
            
            // 1. Update the book in BookStore
            if let bookId = book.id {
                print("Updating book with ID: \(bookId)")
                let bookUpdateSuccess = await bookStore.updateBookShelfLocation(
                    bookId: bookId,
                    shelfLocation: shelfLocation
                )
                
                // 2. Add the book to the shelf in ShelfLocationStore
                let shelfUpdateSuccess = await shelfLocationStore.addBookToShelf(
                    bookID: bookId,
                    shelfNo: shelfLocation
                )
                
                await MainActor.run {
                    isUpdating = false
                    print("Book update success: \(bookUpdateSuccess), Shelf update success: \(shelfUpdateSuccess)")
                    
                    if bookUpdateSuccess && shelfUpdateSuccess {
                        alertMessage = "Location assigned successfully!"
                    } else {
                        alertMessage = "Failed to assign location. Please try again."
                    }
                    
                    showAlert = true
                }
            } else {
                await MainActor.run {
                    isUpdating = false
                    alertMessage = "Invalid book ID. Please try again."
                    showAlert = true
                    print("Invalid book ID")
                }
            }
        }
    }
}

#Preview {
    AssignShelfLocationView(book: LibrarianBook(
        id: UUID(),
        title: "The Design of Everyday Things",
        author: ["Don Norman"],
        genre: "Design",
        publicationDate: "2013",
        totalCopies: 2,
        availableCopies: 2,
        ISBN: "9780465050659"
    ))
    .environmentObject(BookStore())
} 