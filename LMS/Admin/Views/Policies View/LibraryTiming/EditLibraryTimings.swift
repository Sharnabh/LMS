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
    @State private var isSaving = false
    
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
                                // Reset to default weekday timings using calendar
                                let calendar = Calendar.current
                                let defaultDate = calendar.startOfDay(for: Date())
                                
                                timings.weekdayOpeningTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: defaultDate)!
                                timings.weekdayClosingTime = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: defaultDate)!
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
                                // Reset to default sunday timings using calendar
                                let calendar = Calendar.current
                                let defaultDate = calendar.startOfDay(for: Date())
                                
                                timings.sundayOpeningTime = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: defaultDate)!
                                timings.sundayClosingTime = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: defaultDate)!
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
                        isSaving = true
                        Task {
                            await viewModel.updateLibraryTimings(timings)
                            await MainActor.run {
                                isSaving = false
                                isPresented = false
                            }
                        }
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .disabled(isSaving)
                    .opacity(isSaving ? 0.5 : 1.0)
                }
            }
            .overlay {
                if isSaving {
                    ProgressView("Saving...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 4)
                }
            }
        }
    }
}

struct TimingEditRow: View {
    let title: String
    @Binding var time: Date
    let isEditing: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 17))
                .foregroundColor(.primary)
            
            Spacer()
            
            if isEditing {
                DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .transition(.opacity)
            } else {
                Text(time, style: .time)
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .animation(.easeInOut, value: isEditing)
    }
}
