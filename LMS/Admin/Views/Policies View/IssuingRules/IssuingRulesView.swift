//
//  BorrowingRules.swift
//  LMS
//
//  Created by Utkarsh Raj Saxena on 26/03/25.
//

import Foundation
import SwiftUI

struct IssuingRulesView: View {
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
                        // Borrowing Limit Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Issue Limit")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Number of books allowed:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("\(viewModel.borrowingLimit) books")
                                        .font(.subheadline)
                                        .foregroundColor(.accentColor)
                                }
                                
                                Text("Graduate and Post graduate students are entitled to borrow \(viewModel.borrowingLimit) books at a time")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        // Return Period Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Return Period")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Return period:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("\(viewModel.returnPeriod) days")
                                        .font(.subheadline)
                                        .foregroundColor(.accentColor)
                                }
                                
                                Text("Returning period not exceeds \(viewModel.returnPeriod) days")
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
        .navigationTitle("Borrowing Rules")
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
            EditIssuingRulesView(
                borrowingLimit: $viewModel.borrowingLimit,
                returnPeriod: $viewModel.returnPeriod,
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
