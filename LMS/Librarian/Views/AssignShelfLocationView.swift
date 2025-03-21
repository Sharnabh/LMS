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
                    if shelfLocationStore.shelfLocations.isEmpty {
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
        }
    }
    
    private func assignShelfLocation() {
        guard !shelfLocation.isEmpty else { return }
        
        isUpdating = true
        
        Task {
            // 1. Update the book in BookStore
            if let bookId = book.id {
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