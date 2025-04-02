//
//  ExportAnalyticsView.swift
//  LMS
//
//  Created by Utkarsh Raj Saxena on 01/04/25.
//
import SwiftUI
import UniformTypeIdentifiers

struct ExportAnalyticsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var error: String? = nil
    @State private var showingExporter = false
    @State private var csvData: String = ""
    
    // Analytics data
    @State private var totalBooks: Int = 0
    @State private var issuedBooks: Int = 0
    @State private var overdueBooks: Int = 0
    @State private var booksDueToday: Int = 0
    @State private var totalRevenue: Double = 0
    @State private var membersWithOverdueBooks: Int = 0
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    AnalyticsRow(title: "Total Books", value: "\(totalBooks)")
                    AnalyticsRow(title: "Issued Books", value: "\(issuedBooks)")
                    AnalyticsRow(title: "Overdue Books", value: "\(overdueBooks)")
                    AnalyticsRow(title: "Books Due Today", value: "\(booksDueToday)")
                    AnalyticsRow(title: "Total Revenue", value: "₹\(String(format: "%.2f", totalRevenue))")
                    AnalyticsRow(title: "Members with Overdue Books", value: "\(membersWithOverdueBooks)")
                } header: {
                    Text("Library Statistics")
                }
                
                Section {
                    Button(action: {
                        generateCSV()
                    }) {
                        HStack {
                            Image(systemName: "arrow.down.doc.fill")
                            Text("Download CSV")
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .navigationTitle("Export Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .fileExporter(
                isPresented: $showingExporter,
                document: CSVFile(initialText: csvData),
                contentType: .commaSeparatedText,
                defaultFilename: "library_analytics.csv"
            ) { result in
                if case .success = result {
                    print("CSV file saved successfully")
                } else if case .failure(let error) = result {
                    self.error = error.localizedDescription
                }
            }
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK") {
                    error = nil
                }
            } message: {
                if let error = error {
                    Text(error)
                }
            }
            .task {
                await loadAnalytics()
            }
        }
    }
    
    private func loadAnalytics() async {
        isLoading = true
        error = nil
        
        do {
            async let totalBooksCount = BookService.shared.getTotalBooksCount()
            async let issuedBooksCount = AnalyticsService.shared.getIssuedBooksCount()
            async let overdueBooksCount = AnalyticsService.shared.getOverdueBooksCount()
            async let booksDueTodayCount = AnalyticsService.shared.getBooksDueToday()
            async let totalRevenueAmount = AnalyticsService.shared.getTotalRevenue()
            async let membersOverdueCount = AnalyticsService.shared.getMembersWithOverdueBooks()
            
            let (total, issued, overdue, due, revenue, members) = try await (
                totalBooksCount,
                issuedBooksCount,
                overdueBooksCount,
                booksDueTodayCount,
                totalRevenueAmount,
                membersOverdueCount
            )
            
            await MainActor.run {
                self.totalBooks = total
                self.issuedBooks = issued
                self.overdueBooks = overdue
                self.booksDueToday = due
                self.totalRevenue = revenue
                self.membersWithOverdueBooks = members
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func generateCSV() {
        let headers = "Metric,Value\n"
        let rows = [
            "Total Books,\(totalBooks)",
            "Issued Books,\(issuedBooks)",
            "Overdue Books,\(overdueBooks)",
            "Books Due Today,\(booksDueToday)",
            "Total Revenue,₹\(String(format: "%.2f", totalRevenue))",
            "Members with Overdue Books,\(membersWithOverdueBooks)"
        ].joined(separator: "\n")
        
        csvData = headers + rows
        showingExporter = true
    }
}

struct AnalyticsRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct CSVFile: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    
    var text: String
    
    init(initialText: String = "") {
        text = initialText
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return .init(regularFileWithContents: data)
    }
}

struct ExportAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        ExportAnalyticsView()
    }
}


#Preview {
    ExportAnalyticsView()
}
