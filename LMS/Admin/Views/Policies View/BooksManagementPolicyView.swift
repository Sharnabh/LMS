//
//  BooksManagementPolicyView.swift
//  LMS
//
//  Created by Utkarsh Raj Saxena on 26/03/25.
//

import Foundation
import SwiftUI
import Supabase

struct BooksManagementPolicyView: View {
    @State private var isEditing = false
    @State private var bookManagementText = "You can add, update or remove books from the system"
    @State private var bookStatusText = "You can mark books as damaged and lost"
    @State private var borrowingRules = "Graduate and Post graduate students are entitled to borrow 4 books at a time"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Policy Cards
                VStack(spacing: 16) {
                    // Book Management Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Book Management")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                         
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(bookManagementText.components(separatedBy: "\n"), id: \.self) { line in
                                HStack(alignment: .top, spacing: 12) {
                                    Circle()
                                        .fill(Color.blue.opacity(0.5))
                                        .frame(width: 8, height: 8)
                                        .padding(.top, 8)
                                    
                                    Text(line)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(Color.orange.opacity(0.5))
                                    .frame(width: 8, height: 8)
                                    .padding(.top, 8)
                                
                                Text("Note: Removal of books can happen only with admin approval")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    // Book Status Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Book Status")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                              .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(bookStatusText.components(separatedBy: "\n"), id: \.self) { line in
                                HStack(alignment: .top, spacing: 12) {
                                    Circle()
                                        .fill(Color.blue.opacity(0.5))
                                        .frame(width: 8, height: 8)
                                        .padding(.top, 8)
                                    
                                    Text(line)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    // Borrowing Rules Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Borrowing Rules")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                    
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(borrowingRules.components(separatedBy: "\n"), id: \.self) { line in
                                HStack(alignment: .top, spacing: 12) {
                                    Circle()
                                        .fill(Color.blue.opacity(0.5))
                                        .frame(width: 8, height: 8)
                                        .padding(.top, 8)
                                    
                                    Text(line)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal)
            }
            .padding(.top)
        }
        .navigationTitle("Books Management")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isEditing = true
                }) {
                    Text("Edit")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditBooksManagementPolicyView(
                bookManagementText: $bookManagementText,
                bookStatusText: $bookStatusText,
                borrowingRules: $borrowingRules,
                isPresented: $isEditing
            )
        }
    }
}


