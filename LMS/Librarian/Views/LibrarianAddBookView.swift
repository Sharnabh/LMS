import SwiftUI

struct LibrarianAddBookView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var bookStore: BookStore
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
    
    let genres = ["Science", "Humanities", "Business", "Medicine", "Law", "Education", "Arts", "Religion", "Mathematics", "Technology", "Reference"]
    
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
                        
                    TextField("Shelf Location", text: $shelfLocation)
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
            // Adding book asynchronously
            bookStore.addBook(newBook)
            
            // Explicitly reload the books to ensure they're updated across all views
            await bookStore.loadBooks()
            
            // Giving time for the database operation
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            
            await MainActor.run {
                isSuccess = true
                alertMessage = "Book added successfully"
                showAlert = true
                isLoading = false
            }
        }
    }
}

#Preview {
    LibrarianAddBookView()
        .environmentObject(BookStore())
} 