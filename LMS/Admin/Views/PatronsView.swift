//
//  PatronsView.swift
//  LMS
//
//  Created by Utkarsh Raj Saxena on 19/03/25.
//

import Foundation
import SwiftUI
import Supabase

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
                    
                    // Content based on selection
                    if selectedSegment == 0 {
                        LibrariansList(
                            librarians: sortedLibrarians,
                            isLoading: isLoading,
                            errorMessage: errorMessage,
                            isEditMode: isEditMode,
                            onToggleDisabled: confirmToggleLibrarian
                        )
                    } else {
                        MembersList(members: members, isLoading: isLoading, errorMessage: errorMessage)
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
                                    .background(Color.blue)
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
                }
            }
            .sheet(isPresented: $showingAddLibrarian) {
                AddLibrarianView()
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
            } else if librarians.isEmpty {
                Text("No librarians found")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List {
                    ForEach(librarians, id: \.id) { librarian in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(librarian.isDisabled ?? false ? .gray : .purple)
                                
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
                                    
                                    // Status label
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
                        .animation(.easeInOut, value: librarian.isDisabled)
                        .transition(.opacity)
                    }
                }
                .listStyle(.plain)
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
            } else if members.isEmpty {
                Text("No members found")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List {
                    ForEach(members, id: \.id) { member in
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
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

#Preview {
    PatronsView()
}
