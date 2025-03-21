import SwiftUI
import UniformTypeIdentifiers

struct CSVUploadView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showFilePicker = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    @State private var isLoading = false
    
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
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .padding()
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
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        isLoading = true
        
        Task {
            do {
                let urls = try result.get()
                guard let url = urls.first else {
                    throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "No file selected"])
                }
                
                let books = try BookService.shared.parseCSVFile(url: url)
                let result = try await BookService.shared.addBooksFromCSV(books: books)
                
                await MainActor.run {
                    isSuccess = true
                    alertMessage = "Successfully added \(result.newBooks) new books and updated \(result.updatedBooks) existing books"
                    showAlert = true
                    isLoading = false
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
} 