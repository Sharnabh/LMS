//
//  VoiceCommandButton.swift
//  LMS
//
//  Created by Assistant on 01/04/25.
//

import SwiftUI

struct VoiceCommandButton: View {
    @EnvironmentObject var accessibilityManager: AccessibilityManager
    @State private var showingHelpSheet = false
    
    var body: some View {
        Button(action: {
            // Provide haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            accessibilityManager.toggleListening()
        }) {
            HStack(spacing: 8) {
                Image(systemName: accessibilityManager.isListening ? "waveform.circle.fill" : "mic.circle")
                    .font(.system(size: 22))
                    .foregroundColor(accessibilityManager.isListening ? .red : .accentColor)
                    .symbolEffect(.pulse, options: .repeating, isActive: accessibilityManager.isListening)
                
                if accessibilityManager.isListening {
                    Text("Listening...")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.8))
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
            )
        }
        .accessibilityLabel(accessibilityManager.isListening ? "Stop voice commands" : "Start voice commands")
        .accessibilityHint("Double tap to \(accessibilityManager.isListening ? "stop" : "start") listening for voice commands")
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 1.0)
                .onEnded { _ in
                    showingHelpSheet = true
                }
        )
        .sheet(isPresented: $showingHelpSheet) {
            VoiceCommandHelpView()
        }
        .overlay(
            Group {
                if !accessibilityManager.commandDetected.isEmpty {
                    Text(accessibilityManager.commandDetected)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(4)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(4)
                        .offset(y: 30)
                        .transition(.opacity)
                }
            }
        )
    }
}

struct VoiceCommandHelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("ISBN Scanner Commands")) {
                    CommandRow(command: "Scan ISBN", description: "Opens the barcode scanner for scanning book ISBN")
                    CommandRow(command: "Scan book", description: "Alternative command for ISBN scanner")
                    CommandRow(command: "Scan barcode", description: "Alternative command for ISBN scanner")
                }
                
                Section(header: Text("Book Issue Commands")) {
                    CommandRow(command: "Issue book", description: "Starts the book issue process")
                    CommandRow(command: "Borrow book", description: "Alternative command for issuing books")
                    CommandRow(command: "Check out book", description: "Alternative command for issuing books")
                }
            }
            .navigationTitle("Voice Commands")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Voice commands help")
    }
}

struct CommandRow: View {
    let command: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(command)
                .font(.headline)
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(command): \(description)")
    }
}

#Preview {
    VoiceCommandButton()
        .environmentObject(AccessibilityManager())
        .padding()
} 