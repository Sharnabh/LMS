import SwiftUI

struct BookInfoView: View {
    let bookInfo: BookInfo
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Library QR Code")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 15) {
                    BookRow(label: "Book ID", value: bookInfo.bookId)
                    BookRow(label: "Member ID", value: bookInfo.memberId)
                    BookRow(label: "Status", value: bookInfo.issueStatus)
                    BookRow(label: "Issue Date", value: bookInfo.issueDate)
                    BookRow(label: "Return Date", value: bookInfo.returnDate)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Text("Scan Another Code")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding()
            .navigationBarTitle("Book Details", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") {
                dismiss()
            })
            .onDisappear {
                // Ensure any cleanup happens when view disappears
            }
        }
    }
}

struct BookRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.body)
        }
    }
}

#Preview {
    BookInfoView(bookInfo: BookInfo(
        bookId: "2506db6b-b427-4733-b8e7-b993dd3c5300",
        memberId: "1f7cb028-b331-4050-8d46-40944e60ca09",
        issueStatus: "Issued",
        issueDate: "21-03-2025",
        returnDate: "30-03-2025"
    ))
} 
