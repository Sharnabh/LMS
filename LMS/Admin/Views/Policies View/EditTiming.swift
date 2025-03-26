//
//  EditTiming.swift
//  LMS
//
//  Created by Utkarsh Raj Saxena on 26/03/25.
//

import Foundation
import SwiftUI

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
