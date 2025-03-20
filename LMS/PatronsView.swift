//
//  PatronsView.swift
//  LMS
//
//  Created by Utkarsh Raj Saxena on 19/03/25.
//

import Foundation
import SwiftUI

struct PatronsView: View {
    @State private var selectedSegment = 0
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
                    LibrariansList()
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
        }
    }
}

struct LibrariansList: View {
    var body: some View {
        List {
            ForEach(0..<5) { index in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.purple)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Librarian \(index + 1)")
                                .font(.headline)
                            Text("librarian\(index + 1)@library.com")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("ID: LIB\(String(format: "%03d", index + 1))")
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
