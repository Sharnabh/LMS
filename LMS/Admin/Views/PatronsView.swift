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
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @StateObject private var supabaseController = SupabaseDataController()
    @State private var showingAddLibrarian = false
    
    var filteredLibrarians: [LibrarianModel] {
        if searchText.isEmpty {
            return librarians
        }
        return librarians.filter { librarian in
            librarian.username.localizedCaseInsensitiveContains(searchText) ||
            librarian.email.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("Patron Type", selection: $selectedSegment) {
                    Text("Librarians").tag(0)
                    Text("Members").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Search Bar using native implementation
                SearchBar(text: $searchText, placeholder: "Search patrons...")
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                
                // Content based on selection
                if selectedSegment == 0 {
                    LibrariansList(librarians: filteredLibrarians, isLoading: isLoading, errorMessage: errorMessage)
                } else {
                    MembersList(searchText: searchText)
                }
                
                Spacer(minLength: 0)
            }
            .navigationTitle("Patrons")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if selectedSegment == 0 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingAddLibrarian = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 20))
                                .foregroundColor(.purple)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddLibrarian) {
                AddLibrarianView()
            }
            .task {
                await fetchLibrarians()
            }
        }
    }
    
    private func fetchLibrarians() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let query = supabaseController.client.database
                .from("Librarian")
                .select()
            
            let librarians: [LibrarianModel] = try await query.execute().value
            self.librarians = librarians
        } catch {
            errorMessage = "Failed to fetch librarians: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct LibrariansList: View {
    let librarians: [LibrarianModel]
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else if librarians.isEmpty {
                Text("No librarians found")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(librarians, id: \.id) { librarian in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.purple)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 4) {
                                            Text(librarian.username)
                                                .font(.headline)
                                            if !librarian.isFirstLogin {
                                                Image(systemName: "checkmark.seal.fill")
                                                    .foregroundColor(.blue)
                                                    .font(.system(size: 14))
                                            }
                                        }
                                        Text(librarian.email)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
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
}

struct MembersList: View {
    var searchText: String
    
    var filteredMembers: [(Int, String, String)] {
        let members = (0..<10).map { index in
            (index, "Member \(index + 1)", "member\(index + 1)@email.com")
        }
        
        if searchText.isEmpty {
            return members
        }
        
        return members.filter { member in
            member.1.localizedCaseInsensitiveContains(searchText) ||
            member.2.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if filteredMembers.isEmpty {
                    Text("No members found")
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .frame(minHeight: 200)
                } else {
                    ForEach(filteredMembers, id: \.0) { index, name, email in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(name)
                                        .font(.headline)
                                    Text(email)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("ID: MEM\(String(format: "%03d", index + 1))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
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

// Custom SearchBar component that uses UIKit's UISearchBar
struct SearchBar: View {
    @Binding var text: String
    var placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    PatronsView()
}
