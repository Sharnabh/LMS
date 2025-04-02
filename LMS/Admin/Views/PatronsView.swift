//
//  PatronsView.swift
//  LMS
//
//  Created by Utkarsh Raj Saxena on 19/03/25.
//

import Foundation
import SwiftUI
import Supabase
import PDFKit
import UniformTypeIdentifiers

struct PatronsView: View {
    @State private var selectedSegment = 0
    @State private var librarians: [LibrarianModel] = []
    @State private var members: [MemberModel] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @StateObject private var supabaseController = SupabaseDataController()
    @State private var showingAddLibrarian = false
    @State private var isEditMode = false
    @State private var librarianToToggle: LibrarianModel?
    @State private var showingDisableConfirmation = false
    @State private var showingEnableConfirmation = false
    @State private var showingExportSuccess = false
    @State private var exportError: String?
    @State private var searchText = ""
    @State private var isShowingShareSheet = false
    
    private var membersData: String {
        var data = "First Name,Last Name,Email,Enrollment Number\n"
        for member in members {
            data += "\(member.firstName ?? ""),\(member.lastName ?? ""),\(member.email ?? ""),\(member.enrollmentNumber ?? "")\n"
        }
        return data
    }
    
    private func generatePDF() -> Data {
        // Create a PDF document
        let pdfMetaData = [
            kCGPDFContextCreator: "LMS App",
            kCGPDFContextAuthor: "Admin",
            kCGPDFContextTitle: "Members List"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            // Add title
            let titleFont = UIFont.boldSystemFont(ofSize: 24.0)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont
            ]
            let titleString = "Members List"
            let titleStringSize = titleString.size(withAttributes: titleAttributes)
            let titleStringRect = CGRect(x: (pageWidth - titleStringSize.width) / 2.0,
                                       y: 50,
                                       width: titleStringSize.width,
                                       height: titleStringSize.height)
            titleString.draw(in: titleStringRect, withAttributes: titleAttributes)
            
            // Add date
            let dateFont = UIFont.systemFont(ofSize: 12.0)
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            let dateString = "Generated on: \(dateFormatter.string(from: Date()))"
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: dateFont
            ]
            let dateStringSize = dateString.size(withAttributes: dateAttributes)
            let dateStringRect = CGRect(x: (pageWidth - dateStringSize.width) / 2.0,
                                      y: titleStringRect.maxY + 10,
                                      width: dateStringSize.width,
                                      height: dateStringSize.height)
            dateString.draw(in: dateStringRect, withAttributes: dateAttributes)
            
            // Table headers
            let headerFont = UIFont.boldSystemFont(ofSize: 14.0)
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: headerFont
            ]
            let columnHeaders = ["Name", "Email", "Enrollment Number"]
            var currentX: CGFloat = 50
            let headerY: CGFloat = dateStringRect.maxY + 40
            let columnWidth: CGFloat = (pageWidth - 100) / CGFloat(columnHeaders.count)
            
            for header in columnHeaders {
                let headerRect = CGRect(x: currentX, y: headerY,
                                      width: columnWidth, height: 20)
                header.draw(in: headerRect, withAttributes: headerAttributes)
                currentX += columnWidth
            }
            
            // Draw horizontal line under headers
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 50, y: headerY + 25))
            path.addLine(to: CGPoint(x: pageWidth - 50, y: headerY + 25))
            path.lineWidth = 1.0
            UIColor.black.setStroke()
            path.stroke()
            
            // Table content
            let contentFont = UIFont.systemFont(ofSize: 12.0)
            let contentAttributes: [NSAttributedString.Key: Any] = [
                .font: contentFont
            ]
            var currentY = headerY + 40
            
            for member in members {
                if currentY > pageHeight - 100 {
                    context.beginPage()
                    currentY = 50
                }
                
                let name = "\(member.firstName ?? "") \(member.lastName ?? "")"
                let email = member.email ?? ""
                let enrollment = member.enrollmentNumber ?? ""
                
                currentX = 50
                let contentData = [name, email, enrollment]
                
                for content in contentData {
                    let contentRect = CGRect(x: currentX, y: currentY,
                                           width: columnWidth, height: 20)
                    content.draw(in: contentRect, withAttributes: contentAttributes)
                    currentX += columnWidth
                }
                
                currentY += 25
                
                // Draw light horizontal line
                let rowPath = UIBezierPath()
                rowPath.move(to: CGPoint(x: 50, y: currentY - 5))
                rowPath.addLine(to: CGPoint(x: pageWidth - 50, y: currentY - 5))
                rowPath.lineWidth = 0.5
                UIColor.lightGray.setStroke()
                rowPath.stroke()
            }
        }
        
        return data
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Segmented Control
                    Picker("Patron Type", selection: $selectedSegment) {
                        Text("Librarians").tag(0)
                        Text("Members").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    // Search Bar
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    
                    // Content based on selection in a ScrollView
                    ScrollView {
                        if selectedSegment == 0 {
                            LibrariansList(
                                librarians: filteredLibrarians,
                                isLoading: isLoading,
                                errorMessage: errorMessage,
                                isEditMode: isEditMode,
                                onToggleDisabled: confirmToggleLibrarian
                            )
                        } else {
                            MembersList(members: filteredMembers, isLoading: isLoading, errorMessage: errorMessage)
                        }
                    }
                }
                
                // Floating add button at bottom - only show for librarians tab and not in edit mode
                if selectedSegment == 0 && !isEditMode {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                showingAddLibrarian = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Color.accentColor)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Patrons")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if selectedSegment == 0 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(isEditMode ? "Done" : "Edit") {
                            withAnimation {
                                isEditMode.toggle()
                            }
                        }
                    }
                } else {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            let pdfData = generatePDF()
                            isShowingShareSheet = true
                        } label: {
                            Image(systemName: "arrow.down.doc")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddLibrarian) {
                AddLibrarianView()
            }
            .sheet(isPresented: $isShowingShareSheet) {
                ShareSheet(activityItems: [generatePDF()])
            }
            .alert("Disable Librarian", isPresented: $showingDisableConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Disable", role: .destructive) {
                    if let librarian = librarianToToggle {
                        Task {
                            await toggleLibrarianDisabled(librarian: librarian, newStatus: true)
                        }
                    }
                }
            } message: {
                if let librarian = librarianToToggle {
                    Text("Are you sure you want to disable \(librarian.username)'s account? They will no longer be able to access the system.")
                }
            }
            .alert("Enable Librarian", isPresented: $showingEnableConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Enable") {
                    if let librarian = librarianToToggle {
                        Task {
                            await toggleLibrarianDisabled(librarian: librarian, newStatus: false)
                        }
                    }
                }
            } message: {
                if let librarian = librarianToToggle {
                    Text("Are you sure you want to enable \(librarian.username)'s account? They will regain access to the system.")
                }
            }
            .alert("Export Successful", isPresented: $showingExportSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Members list has been exported successfully.")
            }
            .alert("Export Failed", isPresented: Binding(
                get: { exportError != nil },
                set: { if !$0 { exportError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                if let error = exportError {
                    Text(error)
                }
            }
            .task {
                if selectedSegment == 0 {
                    await fetchLibrarians()
                } else {
                    await fetchMembers()
                }
            }
            .onChange(of: selectedSegment) { _, newValue in
                // Exit edit mode when switching tabs
                if isEditMode {
                    isEditMode = false
                }
                
                if newValue == 0 {
                    Task {
                        await fetchLibrarians()
                    }
                } else {
                    Task {
                        await fetchMembers()
                    }
                }
            }
        }
    }
    
    // Sort librarians with active accounts first, then disabled accounts
    private var sortedLibrarians: [LibrarianModel] {
        return librarians.sorted { first, second in
            let firstDisabled = first.isDisabled ?? false
            let secondDisabled = second.isDisabled ?? false
            
            if firstDisabled == secondDisabled {
                return first.username.lowercased() < second.username.lowercased()
            }
            return !firstDisabled && secondDisabled
        }
    }
    
    // Filter librarians based on search text with prioritized matches
    private var filteredLibrarians: [LibrarianModel] {
        if searchText.isEmpty {
            return sortedLibrarians
        }
        
        let searchTermLower = searchText.lowercased()
        
        // First, find exact matches
        let exactMatches = sortedLibrarians.filter { librarian in
            librarian.username.lowercased() == searchTermLower ||
            librarian.email.lowercased() == searchTermLower
        }
        
        // Second, find matches that start with the search term
        let startsWithMatches = sortedLibrarians.filter { librarian in
            (librarian.username.lowercased().starts(with: searchTermLower) ||
             librarian.email.lowercased().starts(with: searchTermLower)) &&
            !exactMatches.contains { $0.id == librarian.id }
        }
        
        // Finally, find other partial matches
        let partialMatches = sortedLibrarians.filter { librarian in
            (librarian.username.lowercased().contains(searchTermLower) ||
             librarian.email.lowercased().contains(searchTermLower)) &&
            !exactMatches.contains { $0.id == librarian.id } &&
            !startsWithMatches.contains { $0.id == librarian.id }
        }
        
        // Combine all matches in priority order
        return exactMatches + startsWithMatches + partialMatches
    }
    
    private func confirmToggleLibrarian(librarian: LibrarianModel) {
        librarianToToggle = librarian
        if librarian.isDisabled ?? false {
            showingEnableConfirmation = true
        } else {
            showingDisableConfirmation = true
        }
    }
    
    private func toggleLibrarianDisabled(librarian: LibrarianModel, newStatus: Bool) async {
        guard let id = librarian.id else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Update in Supabase
            try await supabaseController.client.from("Librarian")
                .update(["librarian_is_disabled": newStatus])
                .eq("id", value: id)
                .execute()
            
            // Refresh the librarians list
            await fetchLibrarians()
        } catch {
            errorMessage = "Failed to update librarian status: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    private func fetchLibrarians() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let query = supabaseController.client.from("Librarian")
                .select()
            
            let librarians: [LibrarianModel] = try await query.execute().value
            self.librarians = librarians
        } catch {
            errorMessage = "Failed to fetch librarians: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func fetchMembers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let query = supabaseController.client.from("Member")
                .select()
            
            // Debug: Print raw response data
            let response = try await query.execute()
            if let jsonString = String(data: response.data, encoding: .utf8) {
                print("Raw Member data: \(jsonString)")
            }
            
            // Use JSONDecoder with appropriate settings
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            do {
                self.members = try decoder.decode([MemberModel].self, from: response.data)
                print("Successfully decoded \(self.members.count) members")
            } catch {
                print("Decoder error: \(error)")
                errorMessage = "Failed to decode member data: \(error.localizedDescription)"
            }
        } catch {
            errorMessage = "Failed to fetch members: \(error.localizedDescription)"
            print("Fetch error: \(error)")
        }
        
        isLoading = false
    }
    
    // Filter members based on search text with prioritized matches
    private var filteredMembers: [MemberModel] {
        if searchText.isEmpty {
            return members
        }
        
        let searchTermLower = searchText.lowercased()
        
        // First, find exact matches
        let exactMatches = members.filter { member in
            let fullName = "\(member.firstName ?? "") \(member.lastName ?? "")".lowercased()
            let email = member.email?.lowercased() ?? ""
            let enrollment = member.enrollmentNumber?.lowercased() ?? ""
            
            return fullName == searchTermLower ||
                   email == searchTermLower ||
                   enrollment == searchTermLower
        }
        
        // Second, find matches that start with the search term
        let startsWithMatches = members.filter { member in
            let fullName = "\(member.firstName ?? "") \(member.lastName ?? "")".lowercased()
            let firstName = (member.firstName ?? "").lowercased()
            let lastName = (member.lastName ?? "").lowercased()
            let email = member.email?.lowercased() ?? ""
            let enrollment = member.enrollmentNumber?.lowercased() ?? ""
            
            return (firstName.starts(with: searchTermLower) ||
                   lastName.starts(with: searchTermLower) ||
                   fullName.starts(with: searchTermLower) ||
                   email.starts(with: searchTermLower) ||
                   enrollment.starts(with: searchTermLower)) &&
                   !exactMatches.contains { $0.id == member.id }
        }
        
        // Finally, find other partial matches
        let partialMatches = members.filter { member in
            let fullName = "\(member.firstName ?? "") \(member.lastName ?? "")".lowercased()
            let email = member.email?.lowercased() ?? ""
            let enrollment = member.enrollmentNumber?.lowercased() ?? ""
            
            let isPartialMatch = fullName.contains(searchTermLower) ||
                                email.contains(searchTermLower) ||
                                enrollment.contains(searchTermLower)
            
            return isPartialMatch &&
                   !exactMatches.contains { $0.id == member.id } &&
                   !startsWithMatches.contains { $0.id == member.id }
        }
        
        // Combine all matches in priority order
        return exactMatches + startsWithMatches + partialMatches
    }
    
    private func exportMembersList() {
        let csvHeader = "First Name,Last Name,Email,Enrollment Number\n"
        var csvContent = csvHeader
        
        for member in members {
            let firstName = member.firstName?.replacingOccurrences(of: ",", with: ";") ?? ""
            let lastName = member.lastName?.replacingOccurrences(of: ",", with: ";") ?? ""
            let email = member.email?.replacingOccurrences(of: ",", with: ";") ?? ""
            let enrollment = member.enrollmentNumber ?? ""
            
            let row = "\(firstName),\(lastName),\(email),\(enrollment)\n"
            csvContent += row
        }
        
        // Get the documents directory
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            exportError = "Could not access documents directory"
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let fileName = "members_list_\(timestamp).csv"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            showingExportSuccess = true
        } catch {
            exportError = "Failed to save file: \(error.localizedDescription)"
        }
    }
    
    private func shareMembers() {
        isShowingShareSheet = true
    }
}

struct LibrariansList: View {
    let librarians: [LibrarianModel]
    let isLoading: Bool
    let errorMessage: String?
    let isEditMode: Bool
    let onToggleDisabled: (LibrarianModel) -> Void
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
            } else if librarians.isEmpty {
                Text("No librarians found")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(librarians, id: \.id) { librarian in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(librarian.isDisabled ?? false ? .gray : .accentColor)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 4) {
                                        Text(librarian.username)
                                            .font(.headline)
                                            .foregroundColor(librarian.isDisabled ?? false ? .gray : .primary)
                                        if !librarian.isFirstLogin {
                                            Image(systemName: "checkmark.seal.fill")
                                                .foregroundColor(.blue)
                                                .font(.system(size: 14))
                                        }
                                    }
                                    Text(librarian.email)
                                        .font(.subheadline)
                                        .foregroundColor(librarian.isDisabled ?? false ? .gray : .secondary)
                                    
                                    Text(librarian.isDisabled ?? false ? "Disabled" : "Active")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(librarian.isDisabled ?? false ? Color.red.opacity(0.2) : Color.green.opacity(0.2))
                                        .foregroundColor(librarian.isDisabled ?? false ? .red : .green)
                                        .cornerRadius(4)
                                }
                                
                                Spacer()
                                
                                if isEditMode {
                                    Toggle("", isOn: Binding(
                                        get: { !(librarian.isDisabled ?? false) },
                                        set: { _ in onToggleDisabled(librarian) }
                                    ))
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: .green))
                                }
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        Divider()
                    }
                }
            }
        }
    }
}

struct MembersList: View {
    let members: [MemberModel]
    let isLoading: Bool
    let errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
            } else if members.isEmpty {
                Text("No members found")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(members, id: \.id) { member in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.accentColor)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(member.firstName ?? "Unknown") \(member.lastName ?? "")")
                                        .font(.headline)
                                    if let email = member.email {
                                        Text(email)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    if let enrollmentNumber = member.enrollmentNumber {
                                        Text("Enrollment: \(enrollmentNumber)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        Divider()
                    }
                }
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search", text: $text)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// ShareSheet UIViewControllerRepresentable
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    PatronsView()
}
