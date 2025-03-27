//
//  EditLateFineView.swift
//  LMS
//
//  Created by Sharnabh on 27/03/25.
//

import SwiftUI

struct EditLateFinesView: View {
    @Binding var fineAmount: Int
//    @Binding var gracePeriod: Int
    @Binding var maxFine: Int
    @Binding var isPresented: Bool
    var onSave: (() -> Void)? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Fine Amount Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Fine Amount")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        
                        HStack {
                            Text("Daily fine amount:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("₹")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            
                            TextField("", value: $fineAmount, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 50)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    // Grace Period Card
//                    VStack(alignment: .leading, spacing: 16) {
//                        HStack {
//                            Text("Grace Period")
//                                .font(.headline)
//                                .foregroundColor(.primary)
//
//                            Spacer()
//                        }
//
//                        HStack {
//                            Text("Grace period:")
//                                .font(.subheadline)
//                                .foregroundColor(.secondary)
//
//                            Spacer()
//
                
//                            Stepper("\(gracePeriod) days", value: $gracePeriod, in: 0...7)
//                                .font(.subheadline)
//                                .foregroundColor(.blue)
//                        }
//                        .padding()
//                        .background(Color(.tertiarySystemBackground))
//                        .cornerRadius(8)
//                    }
//                    .padding()
//                    .background(Color(.systemBackground))
//                    .cornerRadius(16)
//                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    //Maximum Fine Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Lost Book Fine")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        
                        HStack {
                            Text("Maximum fine amount:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("₹")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            
                            TextField("", value: $maxFine, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
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
            .navigationTitle("Edit Late Fines")
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
