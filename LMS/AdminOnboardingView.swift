import SwiftUI

struct AdminOnboardingView: View {
    @State private var librarianName = ""
    @State private var librarianEmail = ""
    @State private var librarianID = ""
    @State private var bookTitle = ""
    @State private var bookAuthor = ""
    @State private var bookISBN = ""
    @State private var bookCategory = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showLibrarianForm = false
    @State private var showBookForm = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.purple)
                    
                    Text("Library Management")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Manage your library resources")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 30)
                
                // Librarian Card
                VStack {
                    if !showLibrarianForm {
                        // Clickable card
                        Button(action: {
                            withAnimation {
                                showLibrarianForm = true
                                showBookForm = false
                            }
                        }) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(.purple)
                                
                                VStack(alignment: .leading) {
                                    Text("Add Librarian")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    
                                    Text("Create accounts for library staff members")
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
                    } else {
                        // Expanded form
                        VStack(spacing: 20) {
                            // Card Header with back button
                            HStack {
                                Button(action: {
                                    withAnimation {
                                        showLibrarianForm = false
                                    }
                                }) {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(.purple)
                                }
                                
                                Image(systemName: "person.badge.plus")
                                    .font(.title2)
                                    .foregroundColor(.purple)
                                
                                Text("Add Librarian")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            // Librarian Form
                            VStack(spacing: 15) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Full Name")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Enter librarian's full name", text: $librarianName)
                                        .padding()
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(10)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Email")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Enter librarian's email", text: $librarianEmail)
                                        .padding()
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(10)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Librarian ID")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Enter unique librarian ID", text: $librarianID)
                                        .padding()
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal)
                            
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
                                    
                                    // Return to card view
                                    withAnimation {
                                        showLibrarianForm = false
                                    }
                                }
                            }) {
                                Text("Add Librarian")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.purple)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Books Card
                VStack {
                    if !showBookForm {
                        // Clickable card
                        Button(action: {
                            withAnimation {
                                showBookForm = true
                                showLibrarianForm = false
                            }
                        }) {
                            HStack {
                                Image(systemName: "book.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.purple)
                                
                                VStack(alignment: .leading) {
                                    Text("Add Books")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    
                                    Text("Add books to your library collection")
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
                    } else {
                        // Expanded form
                        VStack(spacing: 20) {
                            // Card Header with back button
                            HStack {
                                Button(action: {
                                    withAnimation {
                                        showBookForm = false
                                    }
                                }) {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(.purple)
                                }
                                
                                Image(systemName: "book.fill")
                                    .font(.title2)
                                    .foregroundColor(.purple)
                                
                                Text("Add Books")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            // Book Form
                            VStack(spacing: 15) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Book Title")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Enter book title", text: $bookTitle)
                                        .padding()
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(10)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Author")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Enter author name", text: $bookAuthor)
                                        .padding()
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(10)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("ISBN")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Enter ISBN number", text: $bookISBN)
                                        .padding()
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(10)
                                        .keyboardType(.numberPad)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Category")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Enter book category", text: $bookCategory)
                                        .padding()
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Add Book Button
                            Button(action: {
                                // In a real app, you would save the book data
                                if bookTitle.isEmpty || bookAuthor.isEmpty || bookISBN.isEmpty || bookCategory.isEmpty {
                                    alertMessage = "Please fill in all book details."
                                    showAlert = true
                                } else {
                                    alertMessage = "Book added successfully!"
                                    showAlert = true
                                    // Clear fields after successful addition
                                    bookTitle = ""
                                    bookAuthor = ""
                                    bookISBN = ""
                                    bookCategory = ""
                                    
                                    // Return to card view
                                    withAnimation {
                                        showBookForm = false
                                    }
                                }
                            }) {
                                Text("Add Book")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.purple)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Finish Button
                Button(action: {
                    dismiss()
                }) {
                    Text("Finish Setup")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
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
    }
}

struct AdminOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        AdminOnboardingView()
    }
}