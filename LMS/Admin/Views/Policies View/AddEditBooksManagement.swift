//
//  AddEditBooksManagement.swift
//  LMS
//
//  Created by Utkarsh Raj Saxena on 26/03/25.
//

import SwiftUI
struct EditBooksManagementPolicyView: View {
    @Binding var bookManagementText: String
    @Binding var bookStatusText: String
    @Binding var borrowingRules: String
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Book Management Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Book Management")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            TextEditor(text: $bookManagementText)
                                .frame(height: 100)
                                .padding(8)
                                .background(Color(.tertiarySystemBackground))
                                .cornerRadius(8)
                            
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
                        }
                        
                        TextEditor(text: $bookStatusText)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(8)
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
                        
                        TextEditor(text: $borrowingRules)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
                .padding()
            }
            .navigationTitle("Edit Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
