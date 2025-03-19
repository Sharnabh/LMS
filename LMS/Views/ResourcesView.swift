import SwiftUI
import UniformTypeIdentifiers

struct ResourcesView: View {
    @State private var showAddBookSheet = false
    @State private var showCSVUploadSheet = false
    @State private var showScanner = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var isConnected = false
    @State private var retryCount = 0
    private let maxRetries = 3
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 60))
                        .foregroundColor(.purple)
                    
                    Text("Library Resources")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Manage your library's book collection")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 30)
                
                // Connection Status
                HStack {
                    Circle()
                        .fill(isConnected ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                    Text(isConnected ? "Connected to Database" : "Database Connection Error")
                        .font(.subheadline)
                        .foregroundColor(isConnected ? .green : .red)
                    
                    if !isConnected && retryCount < maxRetries {
                        Button(action: {
                            Task {
                                await checkConnection()
                            }
                        }) {
                            Text("Retry")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 20) {
                    Button(action: {
                        showAddBookSheet = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("Add Book Manually")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(12)
                    }
                    .disabled(!isConnected)
                    
                    Button(action: {
                        showCSVUploadSheet = true
                    }) {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                                .font(.title2)
                            Text("Upload CSV File")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(12)
                    }
                    .disabled(!isConnected)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Resources")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAddBookSheet) {
                AddBookView()
            }
            .sheet(isPresented: $showCSVUploadSheet) {
                CSVUploadView()
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Notification"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
            .task {
                await checkConnection()
            }
        }
    }
    
    private func checkConnection() async {
        isLoading = true
        
        do {
            isConnected = try await SupabaseConfig.testConnection()
            if !isConnected {
                retryCount += 1
                if retryCount >= maxRetries {
                    alertMessage = "Unable to connect to the database after multiple attempts. Please check your internet connection and try again later."
                    showAlert = true
                }
            } else {
                retryCount = 0
            }
        } catch {
            retryCount += 1
            isConnected = false
            if retryCount >= maxRetries {
                alertMessage = "Connection error: \(error.localizedDescription)"
                showAlert = true
            }
        }
        
        isLoading = false
    }
}

// Add Book View
struct AddBookView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var author = ""
    @State private var genre = ""
    @State private var isbn = ""
    @State private var publicationYear = ""
    @State private var totalCopies = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    
    private var isValid: Bool {
        !title.isEmpty && 
        !author.isEmpty && 
        !genre.isEmpty && 
        !isbn.isEmpty && isbn.count >= 10 &&
        !publicationYear.isEmpty && 
        !totalCopies.isEmpty &&
        Int(publicationYear) != nil &&
        Int(totalCopies) != nil &&
        Int(totalCopies)! > 0
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Book Details")) {
                    TextField("Title", text: $title)
                    TextField("Author", text: $author)
                    TextField("Genre", text: $genre)
                    TextField("ISBN", text: $isbn)
                        .keyboardType(.numberPad)
                    TextField("Publication Year", text: $publicationYear)
                        .keyboardType(.numberPad)
                    TextField("Total Copies", text: $totalCopies)
                        .keyboardType(.numberPad)
                }
                
                Section {
                    Button("Add Book") {
                        addBook()
                    }
                    .disabled(!isValid)
                }
            }
            .navigationTitle("Add New Book")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
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
    }
    
    private func addBook() {
        Task {
            do {
                // Now we pass a single ISBN instead of an array
                try await BookService.shared.addBook(
                    title: title,
                    author: author,
                    genre: genre,
                    ISBN: isbn,
                    publicationYear: Int(publicationYear) ?? 0,
                    totalCopies: Int(totalCopies) ?? 0
                )
                isSuccess = true
                alertMessage = "Book added successfully!"
                showAlert = true
            } catch {
                isSuccess = false
                alertMessage = "Failed to add book: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}

// CSV Upload View
struct CSVUploadView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showFileImporter = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Upload a CSV file with the following columns:")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("• title")
                    Text("• author")
                    Text("• genre")
                    Text("• ISBN (semicolon-separated for multiple)")
                    Text("• publicationYear")
                    Text("• totalCopies")
                }
                .font(.subheadline)
                .padding()
                
                Spacer()
                
                Button(action: {
                    showFileImporter = true
                }) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Select CSV File")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(12)
                    }
                }
                .disabled(isLoading)
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
            .navigationTitle("Upload CSV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                Task {
                    await handleFileSelection(result)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Notification"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if alertMessage.contains("successfully") {
                            dismiss()
                        }
                    }
                )
            }
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) async {
        isLoading = true
        
        do {
            let urls = try result.get()
            guard let url = urls.first else {
                throw BookError.invalidCSVFormat
            }
            
            let books = try BookService.shared.parseCSVFile(url: url)
            try await BookService.shared.addBooksFromCSV(books: books)
            
            alertMessage = "Successfully imported \(books.count) books!"
        } catch {
            alertMessage = "Error importing books: \(error.localizedDescription)"
        }
        
        isLoading = false
        showAlert = true
    }
}

#Preview {
    ResourcesView()
} 