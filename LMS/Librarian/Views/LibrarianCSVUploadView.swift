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
            ZStack(alignment: .bottom) {
                Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)
                
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 24) {
                        // Required format section
                        GroupBox {
                            // Format header with download button
                            HStack {
                                Label("Required CSV Format", systemImage: "list.bullet.rectangle")
                                    .font(.headline)
                                    .padding(.top, 8)
                                
                                Spacer()
                                
                                ShareLink(
                                    item: createTemplate(),
                                    preview: SharePreview("Book Upload Template", image: Image(systemName: "doc.text"))
                                ) {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.headline)
                                        .foregroundColor(.accentColor)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            
                            // Format table - using grid with fixed widths to prevent zig-zag layout
                            VStack(spacing: 0) {
                                ForEach(["title", "author", "genre", "ISBN", "publicationDate", "totalCopies"], id: \.self) { field in
                                    VStack(spacing: 0) {
                                        HStack(alignment: .center) {
                                            Text(field)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .frame(width: 150, alignment: .leading)
                                            
                                            Spacer(minLength: 10)
                                            
                                            // Description text with consistent layout
                                            Group {
                                                if field == "title" {
                                                    Text("Book title")
                                                } else if field == "author" {
                                                    Text("Use semicolon (;) to separate multiple authors")
                                                } else if field == "genre" {
                                                    Text("One of the supported genres")
                                                } else if field == "ISBN" {
                                                    Text("ISBN-13 format (with or without hyphens)")
                                                } else if field == "publicationDate" {
                                                    Text("Year of publication")
                                                } else if field == "totalCopies" {
                                                    Text("Number of copies available")
                                                } else {
                                                    Text("")
                                                }
                                            }
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .padding(.vertical, 12)
                                        
                                        if field != "totalCopies" {
                                            Divider()
                                        }
                                    }
                                }
                            }
                        }
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        
                        // Example section
                        GroupBox {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Example CSV Content", systemImage: "doc.text.magnifyingglass")
                                    .font(.headline)
                                
                                // CSV header
                                Text("CSV Headers:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 4)
                                
                                Text("Title, Author, Genre, ISBN, PublicationDate, TotalCopies")
                                    .font(.system(.caption, design: .monospaced))
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(UIColor.tertiarySystemBackground))
                                    .cornerRadius(4)
                                
                                // Example rows
                                Text("Example Rows:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 8)
                                
                                Text("""
                                To Kill a Mockingbird,Harper Lee,Arts,978-0446310789,1960,5
                                Good Omens,Neil Gaiman; Terry Pratchett,Arts,978-0060853976,1990,3
                                """)
                                    .font(.system(.caption, design: .monospaced))
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(UIColor.tertiarySystemBackground))
                                    .cornerRadius(4)
                            }
                            .padding()
                        }
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        
                        // Add spacer to push content up and create space before button
                        Spacer()
                            .frame(height: 40)
                    }
                    .padding(.vertical)
                }
                
                VStack {
                    // Fixed Select CSV File Button at the bottom
                    Button(action: {
                        showFilePicker = true
                    }) {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 18))
                            Text("Select CSV File")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.accentColor)
                        )
                        .foregroundColor(.white)
                    }
                    .buttonStyle(LibrarianScaleButtonStyle())
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .background(
                        Rectangle()
                            .fill(Color(UIColor.systemBackground))
                            .edgesIgnoringSafeArea(.bottom)
                            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: -2)
                    )
                }
                
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.4)
                            .edgesIgnoringSafeArea(.all)
                        
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                            .frame(width: 220, height: 100)
                        
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.2)
                            
                            Text("Processing CSV...")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1) // Ensure loading overlay appears above everything else
                }
            }
            .navigationTitle("Upload CSV")
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
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
        // Check if librarian is disabled
        if try await LibrarianService.checkLibrarianStatus() {
            throw NSError(domain: "", code: 403, userInfo: [NSLocalizedDescriptionKey: "Your account has been disabled. Please contact the administrator."])
        }
        
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
                            "Education", "Arts", "Religion", "Mathematics", "Technology", "Reference", "Fiction", "Non-Fiction", "Literature"]
        
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
                bookDetails = try await GoogleBooksService.fetchBookByISBN(isbn: isbn, useGeminiPrediction: false)
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

struct LibrarianScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
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
