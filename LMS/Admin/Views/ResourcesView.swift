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
    @State private var isLoading = false
    
    let genres = ["Science", "Humanities", "Business", "Medicine", "Law", "Education", "Arts", "Religion", "Mathematics", "Technology", "Reference"]
    
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
            ScrollView {
                VStack(spacing: 30) {
                    // Header Image
                    VStack(spacing: 16) {
                        Image(systemName: "book.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)
                        
                        Text("Add New Book")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Fill in the details to add a new book to your library")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Form Fields
                    VStack(spacing: 25) {
                        // Title Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "book.fill")
                                    .foregroundColor(.purple)
                                Text("Book Title")
                                    .font(.headline)
                            }
                            .foregroundColor(.secondary)
                            
                            TextField("Enter book title", text: $title)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        // Author Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.purple)
                                Text("Author")
                                    .font(.headline)
                            }
                            .foregroundColor(.secondary)
                            
                            TextField("Enter author name", text: $author)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        // Genre Field with Dropdown
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "textformat")
                                    .foregroundColor(.purple)
                                Text("Genre")
                                    .font(.headline)
                            }
                            .foregroundColor(.secondary)
                            
                            Menu {
                                ForEach(genres, id: \.self) { genre in
                                    Button(action: {
                                        self.genre = genre
                                    }) {
                                        Text(genre)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(genre.isEmpty ? "Select Genre" : genre)
                                        .foregroundColor(genre.isEmpty ? .secondary : .primary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.purple)
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                        
                        // ISBN Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "number")
                                    .foregroundColor(.purple)
                                Text("ISBN")
                                    .font(.headline)
                            }
                            .foregroundColor(.secondary)
                            
                            TextField("Enter ISBN number", text: $isbn)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .keyboardType(.numberPad)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        // Publication Year Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.purple)
                                Text("Publication Year")
                                    .font(.headline)
                            }
                            .foregroundColor(.secondary)
                            
                            TextField("Enter publication year", text: $publicationYear)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .keyboardType(.numberPad)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        // Total Copies Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "books.vertical.fill")
                                    .foregroundColor(.purple)
                                Text("Total Copies")
                                    .font(.headline)
                            }
                            .foregroundColor(.secondary)
                            
                            TextField("Enter total copies", text: $totalCopies)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .keyboardType(.numberPad)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Add Book Button
                    Button(action: {
                        addBook()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Add Book")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .disabled(!isValid || isLoading)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.purple)
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
    }
    
    private func addBook() {
        isLoading = true
        Task {
            do {
                let result = try await BookService.shared.addBook(
                    title: title,
                    author: author,
                    genre: genre,
                    ISBN: isbn,
                    publicationYear: Int(publicationYear) ?? 0,
                    totalCopies: Int(totalCopies) ?? 0
                )
                
                isSuccess = true
                if result.isNewBook {
                    alertMessage = "New book added successfully!"
                } else {
                    alertMessage = "Book already exists! Updated total copies from \(result.book.totalCopies - Int(totalCopies)!) to \(result.book.totalCopies)"
                }
                showAlert = true
            } catch {
                isSuccess = false
                alertMessage = "Failed to add book: \(error.localizedDescription)"
                showAlert = true
            }
            isLoading = false
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
                    Text("Required CSV Format:")
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    Text("• title")
                    Text("• author")
                    Text("• genre")
                    Text("• ISBN")
                    Text("• publicationYear")
                    Text("• totalCopies")
                }
                .font(.subheadline)
                .padding()
                
                Spacer()
                
                Button(action: {
                    showFileImporter = true
                }) {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                            .font(.title2)
                        Text("Select CSV File")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isLoading ? Color.gray : Color.purple)
                    .cornerRadius(12)
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
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
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
            let importResult = try await BookService.shared.addBooksFromCSV(books: books)
            
            alertMessage = """
                Import completed successfully!
                New books added: \(importResult.newBooks)
                Existing books updated: \(importResult.updatedBooks)
                """
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
