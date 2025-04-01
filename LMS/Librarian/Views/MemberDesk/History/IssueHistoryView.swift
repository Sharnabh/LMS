//
//  IssueHistoryView.swift
//  LMS
//
//  Created by Sharnabh on 25/03/25.
//

import SwiftUI

struct IssueHistoryView: View {
    @State private var members: [MemberModel] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @StateObject private var supabaseController = SupabaseDataController()
    @State private var showingQRScanner = false
    @State private var isEditing = false
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    @State private var memberFines: [String: Double] = [:] // Add this to store member fines
    
    // Filtered members based on search text with prioritized exact matches
    private var filteredMembers: [MemberModel] {
        // First filter by the selected filter option
        let filteredByOption: [MemberModel]
        if selectedFilter == "All" {
            filteredByOption = members
        } else if selectedFilter == "Fines" {
            // Filter members who have fines greater than 0
            filteredByOption = members.filter { member in
                if let memberId = member.id {
                    return (memberFines[memberId] ?? 0) > 0
                }
                return false
            }
        } else {
            filteredByOption = members
        }
        
        // Then filter by search text
        if searchText.isEmpty {
            return filteredByOption
        } else {
            let searchQuery = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            // First filter to get all matching members
            let matchingMembers = filteredByOption.filter { member in
                let firstName = member.firstName?.lowercased() ?? ""
                let lastName = member.lastName?.lowercased() ?? ""
                let fullName = "\(firstName) \(lastName)"
                let email = member.email?.lowercased() ?? ""
                let enrollmentNumber = member.enrollmentNumber?.lowercased() ?? ""
                
                return fullName.contains(searchQuery) ||
                       email.contains(searchQuery) ||
                       enrollmentNumber.contains(searchQuery) ||
                       firstName.contains(searchQuery) ||
                       lastName.contains(searchQuery)
            }
            
            // Sort the matching members to prioritize exact matches
            return matchingMembers.sorted { member1, member2 in
                let firstName1 = member1.firstName?.lowercased() ?? ""
                let lastName1 = member1.lastName?.lowercased() ?? ""
                let fullName1 = "\(firstName1) \(lastName1)"
                
                let firstName2 = member2.firstName?.lowercased() ?? ""
                let lastName2 = member2.lastName?.lowercased() ?? ""
                let fullName2 = "\(firstName2) \(lastName2)"
                
                // Check for exact matches in first name, last name, or full name
                let isExactMatch1 = firstName1 == searchQuery || lastName1 == searchQuery || fullName1 == searchQuery
                let isExactMatch2 = firstName2 == searchQuery || lastName2 == searchQuery || fullName2 == searchQuery
                
                // Prioritize exact matches
                if isExactMatch1 && !isExactMatch2 {
                    return true
                } else if !isExactMatch1 && isExactMatch2 {
                    return false
                }
                
                // If both are exact matches or both are partial matches, sort alphabetically
                return fullName1 < fullName2
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search and filter section
                    HStack {
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                                .padding(.leading, 8)
                            
                            TextField("Search members", text: $searchText)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .font(.system(size: 16))
                                .padding(.vertical, 10)
                        }
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        
                        // Filter button - separate from search bar
                        Menu {
                            Button(action: {
                                selectedFilter = "All"
                            }) {
                                HStack {
                                    Text("All")
                                    if selectedFilter == "All" {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            
                            Button(action: {
                                selectedFilter = "Fines"
                            }) {
                                HStack {
                                    Text("Fines")
                                    if selectedFilter == "Fines" {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        } label: {
                            // Replace text and chevron with filter icon
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 22))
                                .foregroundColor(selectedFilter == "All" ? .primary : .blue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .frame(width: 50) // Adjust width for the icon
                        
                        // REMOVE THIS ENTIRE BLOCK - it's duplicating the filter functionality
                        /* HStack(spacing: 4) {
                                Text(selectedFilter)
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .frame(width: 80) */
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .zIndex(1)
                    
                    // Remove this entire block that uses showFilterOptions
                    /* if showFilterOptions {
                        VStack {
                            HStack {
                                Spacer()
                                VStack(alignment: .leading, spacing: 0) {
                                    Button(action: {
                                        selectedFilter = "All"
                                        showFilterOptions = false
                                    }) {
                                        Text("All")
                                            .font(.system(size: 16))
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 16)
                                            .frame(width: 150, alignment: .leading)
                                            .background(selectedFilter == "All" ? Color.blue.opacity(0.1) : Color.white)
                                    }
                                    .foregroundColor(.primary)
                                    
                                    Divider()
                                    
                                    Button(action: {
                                        selectedFilter = "Overdue Fines"
                                        showFilterOptions = false
                                    }) {
                                        Text("Overdue Fines")
                                            .font(.system(size: 16))
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 16)
                                            .frame(width: 150, alignment: .leading)
                                            .background(selectedFilter == "Overdue Fines" ? Color.blue.opacity(0.1) : Color.white)
                                    }
                                    .foregroundColor(.primary)
                                }
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                                .padding(.trailing, 16)
                                .padding(.top, 4)
                            }
                            Spacer()
                        }
                        .background(Color.black.opacity(0.001))
                        .onTapGesture {
                            showFilterOptions = false
                        }
                        .zIndex(2)
                    } */
                    
                    // Content area with fixed layout
                    ZStack {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .padding()
                        } else if members.isEmpty {
                            Text("No members found")
                                .foregroundColor(.secondary)
                                .padding()
                        } else if filteredMembers.isEmpty {
                            Text("No matching members found")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            List {
                                ForEach(filteredMembers, id: \.id) { member in
                                    MemberCard(
                                        member: member,
                                        supabaseController: supabaseController,
                                        isEditing: isEditing,
                                        fine: memberFines[member.id ?? ""] ?? 0.0
                                    )
                                    .listRowBackground(Color.appBackground)
                                    .listRowSeparator(.hidden)
                                }
                            }
                            .listStyle(.plain)
                            .background(Color.appBackground)
                            .scrollContentBackground(.hidden)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .task {
                    await fetchMembers()
                }
                
                // Floating QR Scan Button - hide when editing
                if !isEditing {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                showingQRScanner = true
                            } label: {
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Member Desk")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Done" : "Edit") {
                        isEditing.toggle()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingQRScanner) {
            NavigationView {
                QRScanner(isPresentedAsFullScreen: true)
                    .navigationBarItems(trailing: Button("Close") {
                        showingQRScanner = false
                    })
            }
        }
    }
    
    // Rest of the code remains unchanged
    // Modified fetchMembers function to get all members and their fines
    private func fetchMembers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Query all members from the Member table without the inner join
            let query = supabaseController.client.from("Member")
                .select("""
                    id,
                    firstName,
                    lastName,
                    email,
                    enrollmentNumber,
                    is_disabled,
                    created_at,
                    favourites,
                    myBag,
                    shelves
                """)
            
            let response = try await query.execute()
            if let jsonString = String(data: response.data, encoding: .utf8) {
                print("Raw Member data: \(jsonString)")
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            do {
                self.members = try decoder.decode([MemberModel].self, from: response.data)
                print("Successfully decoded \(self.members.count) members")
                
                // After fetching members, fetch all fines
                await fetchAllMemberFines()
            } catch {
                errorMessage = "Failed to decode member data: \(error.localizedDescription)"
            }
        } catch {
            errorMessage = "Failed to fetch members: \(error.localizedDescription)"
            print("Fetch error: \(error)")
        }
        
        isLoading = false
    }
    
    // Add a new function to fetch fines for all members at once
    private func fetchAllMemberFines() async {
        do {
            // Fetch all book issues
            let query = supabaseController.client.from("BookIssue")
                .select()
            
            let response = try await query.execute()
            
            struct BookIssue: Codable {
                let id: String
                let memberId: String
                let bookId: String
                let issueDate: String
                let dueDate: String
                let returnDate: String?
                let fine: Double
                let status: String
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let bookIssues = try decoder.decode([BookIssue].self, from: response.data)
            
            // Calculate total fine for each member
            var fines: [String: Double] = [:]
            for issue in bookIssues {
                let currentFine = fines[issue.memberId] ?? 0
                fines[issue.memberId] = currentFine + issue.fine
            }
            
            // Update the memberFines dictionary
            self.memberFines = fines
            
            print("Fetched fines for \(fines.count) members")
            
        } catch {
            print("Failed to fetch all fines: \(error)")
        }
    }
}

// MemberCard struct to replace MemberHistoryRow
struct MemberCard: View {
    let member: MemberModel
    let supabaseController: SupabaseDataController
    let isEditing: Bool
    let fine: Double // Change this to a let property
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isEnabled: Bool
    @State private var isUpdating = false
    @State private var statusErrorMessage: String?
    @State private var showingDisableAlert = false
    
    init(member: MemberModel, supabaseController: SupabaseDataController, isEditing: Bool, fine: Double = 0.0) {
        self.member = member
        self.supabaseController = supabaseController
        self.isEditing = isEditing
        self.fine = fine // Set the fine from the parameter
        // Initialize isEnabled based on member's isDisabled property
        _isEnabled = State(initialValue: !(member.isDisabled == true))
    }
    
    var body: some View {
        NavigationLink(destination: MemberDetailView(member: member)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(member.firstName ?? "Unknown") \(member.lastName ?? "")")
                            .font(.headline)
                        if let email = member.email {
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Add status label below email
                        Text(isEnabled ? "Active" : "Disabled")
                            .font(.caption)
                            .foregroundColor(isEnabled ? .green : .red)
                            .padding(.vertical, 2)
                        
                        if let enrollmentNumber = member.enrollmentNumber {
                            Text("Enrollment: \(enrollmentNumber)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        if isLoading {
                            ProgressView()
                                .frame(width: 60, height: 20)
                        } else if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        } else {
                            Text("₹\(String(format: "%.2f", fine))")
                                .font(.headline)
                                .foregroundColor(fine > 0 ? .red : .green)
                            Text(fine > 0 ? "Fine Due" : "No Fine")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Show toggle switch below fine amount when in edit mode
                if isEditing {
                    HStack {
                        Spacer()
                        if isUpdating {
                            ProgressView()
                        } else if statusErrorMessage != nil {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.red)
                        } else {
                            Toggle("Account Status", isOn: $isEnabled)
                                .onChange(of: isEnabled) { oldValue, newValue in
                                    if !newValue {
                                        // Show confirmation alert before disabling
                                        showingDisableAlert = true
                                        // Revert toggle until confirmed
                                        isEnabled = true
                                    } else {
                                        // No confirmation needed when enabling
                                        updateMemberStatus(enabled: true)
                                    }
                                }
                        }
                    }
                    .padding(.top, 4)
                    .alert("Disable Account", isPresented: $showingDisableAlert) {
                        Button("Cancel", role: .cancel) { }
                        Button("Disable", role: .destructive) {
                            isEnabled = false
                            updateMemberStatus(enabled: false)
                        }
                    } message: {
                        Text("Are you sure you want to disable this user account?")
                    }
                }
            }
            .padding()
            .frame(height: 125)  // Increased from 100 to 120 for more space
            .frame(maxWidth: .infinity, alignment: .leading)  // Ensure cards take full width
            .background(Color.white)  // Add white background to the card
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        // Remove the .task modifier that calls fetchMemberFine
    }
    
    // Remove the fetchMemberFine function
    
    private func updateMemberStatus(enabled: Bool) {
        guard let memberId = member.id else { return }
        
        isUpdating = true
        statusErrorMessage = nil
        
        Task {
            do {
                // Update member status in database
                let query = try supabaseController.client.from("Member")
                    .update(["is_disabled": !enabled])
                    .eq("id", value: memberId)

                let _ = try await query.execute()

                await MainActor.run {
                    isUpdating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isUpdating = false
                    // Revert toggle if update failed
                    isEnabled = !enabled
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        IssueHistoryView()
    }
}
