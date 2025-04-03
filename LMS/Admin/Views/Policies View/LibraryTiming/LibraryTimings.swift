//
//  LibraryTimings.swift
//  LMS
//
//  Created by Utkarsh Raj Saxena on 26/03/25.
//

import Foundation
import SwiftUI

struct LibraryTimingsView: View {
    @StateObject private var viewModel = LibraryTimingsViewModel()
    @State private var isEditing = false
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            } else if let error = viewModel.error {
                VStack {
                    Text("Error loading timings")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Retry") {
                        Task {
                            await viewModel.fetchLibraryTimings()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else if let timings = viewModel.libraryTimings {
                VStack(alignment: .leading, spacing: 24) {
                    // Regular Working Days (Monday - Saturday)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Monday - Saturday")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 4) {
                            TimingRow(
                                title: "Opening Time",
                                time: timings.weekdayOpeningTime
                            )
                            
                            TimingRow(
                                title: "Closing Time",
                                time: timings.weekdayClosingTime
                            )
                        }
                    }
                    
                    // Sunday Timings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Sunday")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 4) {
                            TimingRow(
                                title: "Opening Time",
                                time: timings.sundayOpeningTime
                            )
                            
                            TimingRow(
                                title: "Closing Time",
                                time: timings.sundayClosingTime
                            )
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Library Timings")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isEditing = true
                }) {
                    Text("Edit")
                        .font(.system(size: 17))
                        .foregroundColor(.accentColor)
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            if let timings = viewModel.libraryTimings {
                EditLibraryTimingsView(
                    timings: timings,
                    viewModel: viewModel,
                    isPresented: $isEditing
                )
            }
        }
        .task {
            await viewModel.fetchLibraryTimings()
        }
    }
}

struct TimingRow: View {
    let title: String
    let time: Date
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 17))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(time, style: .time)
                .font(.system(size: 17))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
