//
//  BorrowingRules.swift
//  LMS
//
//  Created by Utkarsh Raj Saxena on 26/03/25.
//

import Foundation
import SwiftUI
struct BorrowingRulesView: View {
    @State private var isEditing = false
    @Binding var borrowingLimit: Int
    @Binding var returnPeriod: Int
    @Binding var reissuePeriod: Int
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Policy Cards
                VStack(spacing: 16) {
                    // Borrowing Limit Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Borrowing Limit")
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
                                
                                Text("\(borrowingLimit) books")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            
                            Text("Graduate and Post graduate students are entitled to borrow \(borrowingLimit) books at a time")
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
                            
                              .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Return period:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(returnPeriod) days")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            
                            Text("Returning period not exceeds \(returnPeriod) days")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    // Reissue Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Reissue")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                              .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Reissue period:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(reissuePeriod) days")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            
                            Text("Reissue can be extended for a period of \(reissuePeriod) days provided the said books are not reserved by others")
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
            .padding(.top)
        }
        .navigationTitle("Borrowing Rules")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isEditing = true
                }) {
                    Text("Edit")
                        .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditBorrowingRulesView(
                borrowingLimit: $borrowingLimit,
                returnPeriod: $returnPeriod,
                reissuePeriod: $reissuePeriod,
                isPresented: $isEditing
            )
        }
    }
}
