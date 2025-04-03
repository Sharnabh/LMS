//
//  EditBorrowingRules.swift
//  LMS
//
//  Created by Utkarsh Raj Saxena on 26/03/25.
//

import Foundation
import SwiftUI

struct EditIssuingRulesView: View {
    @Binding var borrowingLimit: Int
    @Binding var returnPeriod: Int
//    @Binding var reissuePeriod: Int
    @Binding var isPresented: Bool
    var onSave: (() -> Void)? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Borrowing Limit Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Issue Limit")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        
                        HStack {
                            Text("Number of books allowed:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            TextField("", value: $borrowingLimit, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 50)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Text("books")
                                .font(.subheadline)
                                .foregroundColor(.accentColor)
                        }
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(8)
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
                        
                        HStack {
                            Text("Return period:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            TextField("", value: $returnPeriod, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 50)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Text("days")
                                .font(.subheadline)
                                .foregroundColor(.accentColor)
                        }
                        .padding()
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
            .navigationTitle("Edit Rules")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave?()
                        isPresented = false
                    }
                }
            }
        }
    }
}
