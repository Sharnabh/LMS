import SwiftUI
import MessageUI

struct LibrarianFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var librarianName = ""
    @State private var librarianEmail = ""
    @State private var librarianID = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header Image
                    VStack(spacing: 16) {
                        Image(systemName: "person.badge.plus.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Add New Librarian")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("Fill in the details to create a new librarian account")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Form Fields
                    VStack(spacing: 25) {
                        // Full Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(
                                        .linearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                Text("Full Name")
                                    .font(.headline)
                            }
                            .foregroundColor(.secondary)
                            
                            TextField("Enter librarian's full name", text: $librarianName)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            LinearGradient(
                                                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        }
                        
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundStyle(
                                        .linearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                Text("Email Address")
                                    .font(.headline)
                            }
                            .foregroundColor(.secondary)
                            
                            TextField("Enter librarian's email", text: $librarianEmail)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            LinearGradient(
                                                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        }
                        
                        // Librarian ID Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "id.badge.fill")
                                    .foregroundStyle(
                                        .linearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                Text("Librarian ID")
                                    .font(.headline)
                            }
                            .foregroundColor(.secondary)
                            
                            TextField("Enter unique librarian ID", text: $librarianID)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            LinearGradient(
                                                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Add Librarian Button
                    Button(action: {
                        // In a real app, you would save the librarian data
                        if librarianName.isEmpty || librarianEmail.isEmpty || librarianID.isEmpty {
                            alertMessage = "Please fill in all librarian details."
                            showAlert = true
                        } else {
                            alertMessage = "Librarian added successfully!"
                            showAlert = true
                            // Clear fields after successful addition
                            librarianName = ""
                            librarianEmail = ""
                            librarianID = ""
                            
                            // Dismiss the sheet
                            dismiss()
                        }
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Add Librarian")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(
                            color: .blue.opacity(0.3),
                            radius: 15,
                            x: 0,
                            y: 8
                        )
                    }
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
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Notification"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

struct BookFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var bookTitle = ""
    @State private var bookAuthor = ""
    @State private var bookISBN = ""
    @State private var bookGenre = ""
    @State private var publicationYear = ""
    @State private var totalCopies = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    
    let genres = ["Science", "Humanities", "Business", "Medicine", "Law", "Education", "Arts", "Religion", "Mathematics", "Technology", "Reference"]
    
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
                        
                        Text("Fill in the details to add a new book")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Book Cover Image
                    VStack(spacing: 12) {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(12)
                        } else {
                            Button(action: {
                                showImagePicker = true
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 40))
                                        .foregroundColor(.purple)
                                    
                                    Text("Add Book Cover")
                                        .font(.headline)
                                        .foregroundColor(.purple)
                                    
                                    Text("Tap to select an image")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Form Fields
                    VStack(spacing: 25) {
                        // Book Title Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "book.fill")
                                    .foregroundColor(.purple)
                                Text("Book Title")
                                    .font(.headline)
                            }
                            .foregroundColor(.secondary)
                            
                            TextField("Enter book title", text: $bookTitle)
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
                            
                            TextField("Enter author name", text: $bookAuthor)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                                )
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
                            
                            TextField("Enter ISBN number", text: $bookISBN)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .keyboardType(.numberPad)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        // Genre Field
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
                                        bookGenre = genre
                                    }) {
                                        Text(genre)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(bookGenre.isEmpty ? "Select Genre" : bookGenre)
                                        .foregroundColor(bookGenre.isEmpty ? .secondary : .primary)
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
                        if bookTitle.isEmpty || bookAuthor.isEmpty || bookISBN.isEmpty || bookGenre.isEmpty || publicationYear.isEmpty || totalCopies.isEmpty {
                            alertMessage = "Please fill in all book details."
                            showAlert = true
                        } else {
                            alertMessage = "Book added successfully!"
                            showAlert = true
                            // Clear fields after successful addition
                            bookTitle = ""
                            bookAuthor = ""
                            bookISBN = ""
                            bookGenre = ""
                            publicationYear = ""
                            totalCopies = ""
                            selectedImage = nil
                            
                            // Dismiss the sheet
                            dismiss()
                        }
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Add Book")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(
                            color: .blue.opacity(0.3),
                            radius: 15,
                            x: 0,
                            y: 8
                        )
                    }
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
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Notification"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct AddBooksSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showManualForm = false
    @State private var showCSVImport = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "book.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)
                        
                        Text("Add Books")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Choose how you want to add books")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Manual Entry Card
                    VStack {
                        Button(action: {
                            showManualForm = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 40))
                                    .foregroundStyle(
                                        .linearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                VStack(alignment: .leading) {
                                    Text("Add Manually")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    
                                    Text("Add books one by one with details")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(
                                        .linearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.blue.opacity(0.5), .purple.opacity(0.5)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                    }
                    .padding(.vertical)
                    
                    // CSV Import Card
                    VStack {
                        Button(action: {
                            showCSVImport = true
                        }) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.purple)
                                
                                VStack(alignment: .leading) {
                                    Text("Add CSV")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    
                                    Text("Import books from a CSV file")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.purple)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
            }
            .sheet(isPresented: $showManualForm) {
                BookFormView()
            }
            .sheet(isPresented: $showCSVImport) {
                CSVImportView()
            }
        }
    }
}

struct CSVImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)
                        
                        Text("Import Books")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Upload a CSV file to import books")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // CSV Upload Section
                    VStack(spacing: 20) {
                        Button(action: {
                            // Handle CSV file selection
                            alertMessage = "CSV file selected successfully!"
                            showAlert = true
                        }) {
                            VStack(spacing: 12) {
                                Image(systemName: "doc.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundStyle(
                                        .linearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                Text("Select CSV File")
                                    .font(.headline)
                                    .foregroundStyle(
                                        .linearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                
                                Text("Choose a CSV file with book details")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Import Button
                        Button(action: {
                            alertMessage = "Books imported successfully!"
                            showAlert = true
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Import Books")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(
                                color: .blue.opacity(0.3),
                                radius: 15,
                                x: 0,
                                y: 8
                            )
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Notification"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

struct AdminOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataController = SupabaseDataController()
    @State private var showLibrarianForm = false
    @State private var showBookForm = false
    @State private var showMainApp = false
    @State private var showManualForm = false
    @State private var showCSVImport = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var showMailComposer = false
    @State private var mailData: (recipient: String, subject: String, body: String)?
    @State private var librarianName = ""
    @State private var librarianEmail = ""
    @State private var hasAddedBooks = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Library Management")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("Manage your library resources")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 30)
                    
                    // Librarian Card
                    VStack {
                        Button(action: {
                            withAnimation(.spring()) {
                                showLibrarianForm.toggle()
                            }
                        }) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundStyle(
                                        .linearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Add Librarian")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    Text("Add a new librarian to your library")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: showLibrarianForm ? "chevron.up" : "chevron.down")
                                    .foregroundStyle(
                                        .linearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                            .padding(.vertical, 20)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.blue.opacity(0.5), .purple.opacity(0.5)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                        
                        if showLibrarianForm {
                            VStack(spacing: 16) {
                                // Librarian form fields
                                TextField("Librarian Name", text: $librarianName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.horizontal)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                                
                                TextField("Librarian Email", text: $librarianEmail)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .padding(.horizontal)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                                
                                Button(action: {
                                    Task {
                                        await addLibrarian()
                                    }
                                }) {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Add Librarian")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(
                                                LinearGradient(
                                                    colors: [.blue, .purple.opacity(0.8)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .cornerRadius(16)
                                            .shadow(
                                                color: .blue.opacity(0.3),
                                                radius: 15,
                                                x: 0,
                                                y: 8
                                            )
                                    }
                                }
                                .disabled(isLoading)
                                .padding(.horizontal)
                                .padding(.bottom, 20)
                            }
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Books Card
                    VStack {
                        Button(action: {
                            withAnimation(.spring()) {
                                showBookForm.toggle()
                            }
                        }) {
                            HStack {
                                Image(systemName: "books.vertical")
                                    .font(.system(size: 40))
                                    .foregroundStyle(
                                        .linearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Add Books")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    Text("Start building your library collection")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: showBookForm ? "chevron.up" : "chevron.down")
                                    .foregroundStyle(
                                        .linearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                            .padding(.vertical, 20)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity)
                        }
                        
                        if showBookForm {
                            VStack(spacing: 16) {
                                Button(action: {
                                    showManualForm = true
                                }) {
                                    HStack {
                                        Image(systemName: "square.and.pencil")
                                            .font(.system(size: 40))
                                            .foregroundStyle(
                                                .linearGradient(
                                                    colors: [.blue, .purple],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                        
                                        Text("Add Manually")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(
                                                .linearGradient(
                                                    colors: [.blue, .purple],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(
                                                        LinearGradient(
                                                            colors: [.blue.opacity(0.5), .purple.opacity(0.5)],
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        ),
                                                        lineWidth: 1
                                                    )
                                            )
                                    )
                                }
                                .padding(.horizontal)
                                
                                Button(action: {
                                    showCSVImport = true
                                }) {
                                    HStack {
                                        Image(systemName: "doc.text.fill")
                                            .font(.system(size: 30))
                                            .foregroundStyle(
                                                .linearGradient(
                                                    colors: [.blue, .purple],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                        
                                        Text("Import from CSV")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(
                                                .linearGradient(
                                                    colors: [.blue, .purple],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(
                                                        LinearGradient(
                                                            colors: [.blue.opacity(0.5), .purple.opacity(0.5)],
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        ),
                                                        lineWidth: 1
                                                    )
                                            )
                                    )
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 20)
                            }
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Finish Button
                    Button(action: {
                        if !hasAddedBooks {
                            alertMessage = "Are you sure you want to continue without adding any books? You can add them later from the Resources tab."
                            showAlert = true
                        } else {
                            showMainApp = true
                        }
                    }) {
                        Text("Finish Setup")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(
                                color: .blue.opacity(0.3),
                                radius: 15,
                                x: 0,
                                y: 8
                            )
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Notification"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showMailComposer) {
                if let mailData = mailData {
                    MailComposeView(
                        recipient: mailData.recipient,
                        subject: mailData.subject,
                        body: mailData.body,
                        isShowing: $showMailComposer,
                        result: { result in
                            switch result {
                            case .sent:
                                alertMessage = "Welcome email sent successfully!"
                            case .saved:
                                alertMessage = "Email saved as draft"
                            case .failed:
                                alertMessage = "Failed to send email"
                            case .cancelled:
                                alertMessage = "Email cancelled"
                            @unknown default:
                                alertMessage = "Unknown email result"
                            }
                            showAlert = true
                        }
                    )
                }
            }
            .sheet(isPresented: $showManualForm) {
                AddBookView()
                    .onDisappear {
                        hasAddedBooks = true
                    }
            }
            .sheet(isPresented: $showCSVImport) {
                CSVUploadView()
                    .onDisappear {
                        hasAddedBooks = true
                    }
            }
            .fullScreenCover(isPresented: $showMainApp) {
                MainAppView(userRole: .admin, initialTab: 0)
                    .ignoresSafeArea()
            }
        }
    }
    
    private func addLibrarian() async {
        if librarianName.isEmpty || librarianEmail.isEmpty {
            alertMessage = "Please fill in all librarian details."
            showAlert = true
            return
        }
        
        isLoading = true
        
        do {
            _ = try await dataController.createLibrarian(
                name: librarianName,
                email: librarianEmail
            )
            
            DispatchQueue.main.async {
                isLoading = false
                alertMessage = "Librarian added successfully! A welcome email has been sent with login credentials."
                showAlert = true
                
                // Clear fields after successful addition
                librarianName = ""
                librarianEmail = ""
                
                // Return to card view
                withAnimation {
                    showLibrarianForm = false
                }
            }
        } catch {
            DispatchQueue.main.async {
                isLoading = false
                alertMessage = "Error adding librarian: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}

struct MailComposeView: UIViewControllerRepresentable {
    let recipient: String
    let subject: String
    let body: String
    @Binding var isShowing: Bool
    let result: (MFMailComposeResult) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients([recipient])
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailComposeView
        
        init(_ parent: MailComposeView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.isShowing = false
            parent.result(result)
        }
    }
}

struct AdminOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        AdminOnboardingView()
    }
}
