import SwiftUI
import UniformTypeIdentifiers

struct LibrarianCSVUploadView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var bookStore: BookStore
    @State private var showFilePicker = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    @State private var isLoading = false
    @State private var showPreview = false
    @State private var parsedBooks: [LibrarianBook] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Upload a CSV file with the following columns:")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
                // Required format section
                GroupBox(label: Text("Required CSV Format").font(.headline)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• title")
                        Text("• author (use ; for multiple authors)")
                        Text("• genre (Science, Humanities, Business, Medicine, Law, Education, Arts, Religion, Mathematics, Technology, Reference)")
                        Text("• ISBN")
                        Text("• publicationDate")
                        Text("• totalCopies")
                    }
                    .font(.system(.body, design: .monospaced))
                }
                .padding(.horizontal)
                
                // Example section
                GroupBox(label: Text("Example CSV Content").font(.headline)) {
                    Text("""
                    Title,Author,Genre,ISBN,PublicationDate,TotalCopies
                    To Kill a Mockingbird,Harper Lee,Arts,978-0446310789,1960,5
                    Good Omens,Neil Gaiman; Terry Pratchett,Arts,978-0060853976,1990,3
                    """)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                HStack(spacing: 15) {
                    Button(action: {
                        showFilePicker = true
                    }) {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                            Text("Select CSV File")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    ShareLink(
                        item: createTemplate(),
                        preview: SharePreview(
                            "Book Upload Template",
                            image: Image(systemName: "doc.text")
                        )
                    ) {
                        HStack {
                            Image(systemName: "arrow.down.doc")
                            Text("Download Template")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                if isLoading {
                    ProgressView("Processing CSV...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.2)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.9)))
                        .shadow(radius: 2)
                }
                
                Spacer()
            }
            .navigationTitle("Upload CSV")
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
            .background(Color.appBackground.ignoresSafeArea())
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showPreview) {
            CSVPreviewView(books: parsedBooks)
                .environmentObject(bookStore)
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        isLoading = true
        
        Task {
            do {
                let urls = try result.get()
                guard let url = urls.first else {
                    throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "No file selected"])
                }
                
                // Parse the CSV file to get the books
                let books = try await parseCSVFile(url: url)
                
                // Update the UI
                await MainActor.run {
                    self.parsedBooks = books
                    isLoading = false
                    
                    // Show the preview screen
                    if !books.isEmpty {
                        showPreview = true
                    } else {
                        alertMessage = "No valid books found in the CSV file."
                        showAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    isSuccess = false
                    alertMessage = error.localizedDescription
                    showAlert = true
                    isLoading = false
                }
            }
        }
    }
    
    private func parseCSVFile(url: URL) async throws -> [LibrarianBook] {
        let csvContent = try String(contentsOf: url, encoding: .utf8)
        let rows = csvContent.components(separatedBy: .newlines)
        
        // Skip header row and empty rows
        let dataRows = rows.dropFirst().filter { !$0.isEmpty }
        
        if dataRows.isEmpty {
            throw CSVError.emptyFile
        }
        
        var parsedBooks: [LibrarianBook] = []
        let requiredColumns = 6  // Reduced from 7 since we removed shelfLocation
        
        // List of allowed genres - must match the controller
        let allowedGenres = ["Science", "Humanities", "Business", "Medicine", "Law", 
                            "Education", "Arts", "Religion", "Mathematics", "Technology", "Reference"]
        
        for (index, row) in dataRows.enumerated() {
            let columns = row.components(separatedBy: ",")
            
            // Check column count for this specific row
            if columns.count < requiredColumns {
                throw CSVError.invalidColumn(row: index + 2, expected: requiredColumns, found: columns.count)
            }
            
            // Get genre and validate it
            let genre = columns[2].trimmingCharacters(in: .whitespaces)
            if !allowedGenres.contains(genre) {
                throw CSVError.invalidGenre(row: index + 2, genre: genre)
            }
            
            // Get author string and split into array by semicolons
            let authorString = columns[1].trimmingCharacters(in: .whitespaces)
            let authorArray = authorString.split(separator: ";").map { String($0.trimmingCharacters(in: .whitespaces)) }
            
            // ISBN for GoogleBooks API
            let isbn = columns[3].trimmingCharacters(in: .whitespaces)
            
            // Try to fetch book details from Google Books
            var bookDetails: LibrarianBook? = nil
            do {
                bookDetails = try await GoogleBooksService.fetchBookByISBN(isbn: isbn)
            } catch {
                print("Could not fetch book details from GoogleBooks API: \(error)")
            }
            
            // Create the book with either fetched details or CSV data
            let book = LibrarianBook(
                id: UUID(),
                title: columns[0].trimmingCharacters(in: .whitespaces),
                author: authorArray,
                genre: genre,
                publicationDate: columns[4].trimmingCharacters(in: .whitespaces),
                totalCopies: Int(columns[5]) ?? 1,
                availableCopies: Int(columns[5]) ?? 1,
                ISBN: isbn,
                Description: bookDetails?.Description,
                shelfLocation: nil, // Initially null, to be set during preview
                dateAdded: Date(),
                publisher: bookDetails?.publisher,
                imageLink: bookDetails?.imageLink
            )
            
            parsedBooks.append(book)
        }
        
        return parsedBooks
    }
    
    private func createTemplate() -> URL {
        let csvString = """
        Title,Author,Genre,ISBN,PublicationDate,TotalCopies
        To Kill a Mockingbird,Harper Lee,Arts,978-0446310789,1960,5
        Good Omens,Neil Gaiman; Terry Pratchett,Arts,978-0060853976,1990,3
        """
        
        // Create a temporary file with .csv extension
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "book_upload_template.csv"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        // Write the CSV content to the file
        try? csvString.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }
}

enum CSVError: Error, LocalizedError {
    case invalidFormat
    case emptyFile
    case invalidColumn(row: Int, expected: Int, found: Int)
    case invalidGenre(row: Int, genre: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "The CSV file format is invalid. Please check that it matches the required format."
        case .emptyFile:
            return "The CSV file appears to be empty."
        case .invalidColumn(let row, let expected, let found):
            return "Row \(row) has \(found) columns, but \(expected) columns are required."
        case .invalidGenre(let row, let genre):
            return "Row \(row) contains invalid genre '\(genre)'. Allowed genres are: Science, Humanities, Business, Medicine, Law, Education, Arts, Religion, Mathematics, Technology, Reference."
        }
    }
}

#Preview {
    LibrarianCSVUploadView()
        .environmentObject(BookStore())
} 