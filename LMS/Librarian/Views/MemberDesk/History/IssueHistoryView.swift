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
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
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
                    } else {
                        List {
                            ForEach(members, id: \.id) { member in
                                MemberHistoryRow(member: member, supabaseController: supabaseController, isEditing: isEditing)
                            }
                        }
                        .listStyle(.plain)
                    }
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
                QRScanner()
                    .navigationBarItems(trailing: Button("Close") {
                        showingQRScanner = false
                    })
            }
        }
    }
    
    private func fetchMembers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Join Member and BookIssue tables to get only members who have issued books
            let query = supabaseController.client.from("Member")
                .select("""
                    id,
                    firstName,
                    lastName,
                    email,
                    enrollmentNumber,
                    BookIssue!inner (
                        id,
                        bookId,
                        issueDate,
                        dueDate,
                        returnDate,
                        fine,
                        status
                    )
                """)
            
            let response = try await query.execute()
            if let jsonString = String(data: response.data, encoding: .utf8) {
                print("Raw Member data: \(jsonString)")
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            do {
                self.members = try decoder.decode([MemberModel].self, from: response.data)
                print("Successfully decoded \(self.members.count) members with issued books")
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
}

// Combined row component that handles both display and edit modes
struct MemberHistoryRow: View {
    let member: MemberModel
    let supabaseController: SupabaseDataController
    let isEditing: Bool
    @State private var fine: Double = 0.0
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isEnabled: Bool
    @State private var isUpdating = false
    @State private var statusErrorMessage: String?
    
    init(member: MemberModel, supabaseController: SupabaseDataController, isEditing: Bool) {
        self.member = member
        self.supabaseController = supabaseController
        self.isEditing = isEditing
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
                                    updateMemberStatus(enabled: newValue)
                                }
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.vertical, 4)
        }
        .task {
            await fetchMemberFine()
        }
    }
    
    private func fetchMemberFine() async {
        guard let memberId = member.id else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch all book issues for this member
            let query = supabaseController.client.from("BookIssue")
                .select()
                .eq("memberId", value: memberId)
            
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
            
            // Calculate total fine
            fine = bookIssues.reduce(0) { $0 + $1.fine }
            
        } catch {
            errorMessage = "Failed to fetch fine: \(error.localizedDescription)"
            print("Fine fetch error: \(error)")
        }
        
        isLoading = false
    }
    
    private func updateMemberStatus(enabled: Bool) {
        guard let memberId = member.id else { return }
        
        isUpdating = true
        statusErrorMessage = nil
        
        Task {
            do {
                // Update member status in database
                // Using is_disabled field as per your model's CodingKeys
                let query = try supabaseController.client.from("Member")  // Add 'try' here
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
