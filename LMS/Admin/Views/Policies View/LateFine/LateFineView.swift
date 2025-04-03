//
//  LateFineView.swift
//  LMS
//
//  Created by Sharnabh on 27/03/25.
//

import SwiftUI

struct LateFinesView: View {
    @State private var isEditing = false
    @StateObject private var viewModel = LibraryPoliciesViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    // Policy Cards
                    VStack(spacing: 16) {
                        // Fine Amount Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Fine Amount")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Daily fine amount:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("₹\(viewModel.fineAmount)")
                                        .font(.subheadline)
                                        .foregroundColor(.accentColor)
                                }
                                
                                Text("Fine of ₹\(viewModel.fineAmount) per day for late returns")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        // Maximum Fine Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Lost Book Fine")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Maximum fine amount:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("₹\(viewModel.lostBookFine)")
                                        .font(.subheadline)
                                        .foregroundColor(.accentColor)
                                }
                                
                                Text("Maximum fine capped at ₹\(viewModel.lostBookFine) per book")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top)
        }
        .navigationTitle("Late Fines")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
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
            EditLateFinesView(
                fineAmount: $viewModel.fineAmount,
                maxFine: $viewModel.lostBookFine,
                isPresented: $isEditing,
                onSave: {
                    Task {
                        await viewModel.updatePolicies()
                    }
                }
            )
        }
        .onAppear {
            Task {
                await viewModel.fetchPolicies()
            }
        }
    }
}
