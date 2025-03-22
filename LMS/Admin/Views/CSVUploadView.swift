import SwiftUI
import UniformTypeIdentifiers

struct CSVUploadView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var bookStore: AdminBookStore
    @State private var showFilePicker = false
    @State private var showAlert = false
    @State private var alertMessage = ""
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
                        Text("• genre")
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
                    To Kill a Mockingbird,Harper Lee,Fiction,978-0446310789,1960,5
                    Good Omens,Neil Gaiman; Terry Pratchett,Fiction,978-0060853976,1990,3
                    """)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
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
            AdminCSVPreviewView(books: parsedBooks)
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
            throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "The CSV file appears to be empty"])
        }
        
        var parsedBooks: [LibrarianBook] = []
        let requiredColumns = 6
        
        for (index, row) in dataRows.enumerated() {
            let columns = row.components(separatedBy: ",")
            
            // Check column count for this specific row
            if columns.count < requiredColumns {
                throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Row \(index + 2) has \(columns.count) columns, but \(requiredColumns) columns are required"])
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
                genre: columns[2].trimmingCharacters(in: .whitespaces),
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
} 