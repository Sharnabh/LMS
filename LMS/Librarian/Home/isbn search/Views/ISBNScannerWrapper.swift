//
//  ISBNScannerWrapper.swift
//  LMS
//
//  Created by Assistant on 01/04/25.
//

import SwiftUI

struct ISBNScannerWrapper: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var accessibilityManager: AccessibilityManager
    @State private var scannedCode = ""
    @State private var isShowingScanner = false
    
    var onCodeScanned: (String) -> Void
    
    var body: some View {
        VStack {
            // Scanner view or placeholder when not scanning
            ZStack {
                if isShowingScanner {
                    BarcodeScannerView(scannedCode: $scannedCode)
                        .ignoresSafeArea()
                        .accessibilityLabel("ISBN barcode scanner")
                        .accessibilityHint("Center the book's barcode in the scanner area")
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 80))
                            .foregroundColor(.blue.opacity(0.7))
                        
                        Text("Say \"Scan ISBN\" to start scanning")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        Button("Tap to Start Scanning") {
                            isShowingScanner = true
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        .accessibilityLabel("Start ISBN scanner")
                    }
                    .padding()
                }
                
                // Voice command button overlay
                VStack {
                    HStack {
                        Spacer()
                        VoiceCommandButton()
                            .padding(.top, 50)
                            .padding(.trailing, 20)
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            // Set up accessibility and check for voice commands
            UIAccessibility.post(notification: .announcement, argument: "ISBN Scanner ready. Say scan ISBN to scan a book.")
        }
        .onChange(of: accessibilityManager.shouldScanISBN) { oldValue, newValue in
            if newValue {
                isShowingScanner = true
                accessibilityManager.resetCommands()
            }
        }
        .onChange(of: scannedCode) { oldValue, newValue in
            if !newValue.isEmpty {
                // Provide audio feedback when code is scanned
                UIAccessibility.post(notification: .announcement, argument: "ISBN code scanned")
                
                // Pass the scanned code back
                onCodeScanned(newValue)
                
                // Dismiss this view
                dismiss()
            }
        }
        .navigationTitle("ISBN Scanner")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
}

// Extension for UIAccessibility for easier announcements
extension UIAccessibility {
    static func announce(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}

#Preview {
    NavigationView {
        ISBNScannerWrapper { code in
            print("Scanned: \(code)")
        }
        .environmentObject(AccessibilityManager())
    }
} 
