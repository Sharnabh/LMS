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
    @StateObject private var supabaseController = SupabaseDataController()
    @State private var showingAddLibrarian = false
    
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
                
                // Content based on selection
                if selectedSegment == 0 {
                    LibrariansList(librarians: librarians, isLoading: isLoading, errorMessage: errorMessage)
                } else {
                    MembersList()
                }
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
                                .font(.system(size: 22))
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
            let query = supabaseController.client.from("Librarian")
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
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

struct MembersList: View {
    var body: some View {
        List {
            ForEach(0..<10) { index in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Member \(index + 1)")
                                .font(.headline)
                            Text("member\(index + 1)@email.com")
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
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    PatronsView()
}
