//
//  EditLibraryTimings.swift
//  LMS
//
//  Created by Utkarsh Raj Saxena on 26/03/25.
//

import Foundation
import SwiftUI

struct EditLibraryTimingsView: View {
    @State private var timings: LibraryTiming
    let viewModel: LibraryTimingsViewModel
    @Binding var isPresented: Bool
    
    init(timings: LibraryTiming, viewModel: LibraryTimingsViewModel, isPresented: Binding<Bool>) {
        _timings = State(initialValue: timings)
        self.viewModel = viewModel
        _isPresented = isPresented
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Regular Working Days (Monday - Saturday)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Monday - Saturday")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button(action: {
                                // Reset to default weekday timings
                                timings = LibraryTiming(
                                    id: timings.id,
                                    weekdayOpeningTime: Date(timeIntervalSince1970: 9 * 3600),
                                    weekdayClosingTime: Date(timeIntervalSince1970: 20 * 3600),
                                    sundayOpeningTime: timings.sundayOpeningTime,
                                    sundayClosingTime: timings.sundayClosingTime,
                                    lastUpdated: Date()
                                )
                            }) {
                                Text("Reset")
                                    .font(.system(size: 17))
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        VStack(spacing: 4) {
                            TimingEditRow(
                                title: "Opening Time",
                                time: $timings.weekdayOpeningTime,
                                isEditing: true
                            )
                            
                            TimingEditRow(
                                title: "Closing Time",
                                time: $timings.weekdayClosingTime,
                                isEditing: true
                            )
                        }
                    }
                    
                    // Sunday Timings
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Sunday")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button(action: {
                                // Reset to default sunday timings
                                timings = LibraryTiming(
                                    id: timings.id,
                                    weekdayOpeningTime: timings.weekdayOpeningTime,
                                    weekdayClosingTime: timings.weekdayClosingTime,
                                    sundayOpeningTime: Date(timeIntervalSince1970: 10 * 3600),
                                    sundayClosingTime: Date(timeIntervalSince1970: 16 * 3600),
                                    lastUpdated: Date()
                                )
                            }) {
                                Text("Reset")
                                    .font(.system(size: 17))
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        VStack(spacing: 4) {
                            TimingEditRow(
                                title: "Opening Time",
                                time: $timings.sundayOpeningTime,
                                isEditing: true
                            )
                            
                            TimingEditRow(
                                title: "Closing Time",
                                time: $timings.sundayClosingTime,
                                isEditing: true
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Edit Timings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(.system(size: 17))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await viewModel.updateLibraryTimings(timings)
                            isPresented = false
                        }
                    }
                    .font(.system(size: 17, weight: .semibold))
                }
            }
        }
    }
}

