//
//  SiriButton.swift
//  LMS
//
//  Created by Assistant on 01/04/25.
//

import SwiftUI
import IntentsUI

struct SiriButton: View {
    @EnvironmentObject private var accessibilityManager: AccessibilityManager
    @State private var showingSiriUI = false
    @State private var selectedIntent: AnyObject?
    @State private var showShortcutOptions = false
    @State private var showingSiriNotAvailableAlert = false
    
    var body: some View {
        Button(action: {
            if accessibilityManager.isSiriAvailable {
                showShortcutOptions = true
            } else {
                showingSiriNotAvailableAlert = true
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "waveform.circle")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                
                Text("Enable Siri")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(accessibilityManager.isSiriAvailable ? Color.blue : Color.gray)
                    .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
            )
        }
        .accessibilityLabel("Setup Siri shortcuts")
        .accessibilityHint("Double tap to set up hands-free voice commands with Siri")
        .sheet(isPresented: $showingSiriUI) {
            if let intent = selectedIntent as? INIntent {
                SiriShortcutSetupView(intent: intent)
            }
        }
        .actionSheet(isPresented: $showShortcutOptions) {
            ActionSheet(
                title: Text("Set Up Siri Shortcuts"),
                message: Text("Choose which Siri command you want to set up"),
                buttons: [
                    .default(Text("Scan ISBN")) {
                        selectedIntent = ScanISBNIntent()
                        showingSiriUI = true
                    },
                    .default(Text("Issue Book")) {
                        selectedIntent = IssueBookIntent()
                        showingSiriUI = true
                    },
                    .cancel()
                ]
            )
        }
        .alert(isPresented: $showingSiriNotAvailableAlert) {
            Alert(
                title: Text("Siri Not Available"),
                message: Text("Siri integration is not available on this device or the required entitlements are missing. Please use the manual voice commands instead."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// Updated to a safer implementation that doesn't try to force-unwrap optionals
struct SiriShortcutSetupView: View {
    let intent: INIntent
    @Environment(\.presentationMode) private var presentationMode
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            // Only show the INUIAddVoiceShortcutViewController if possible
            if INPreferences.siriAuthorizationStatus() == .authorized {
                SiriShortcutViewControllerWrapper(intent: intent)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("Siri Access Required")
                        .font(.title)
                        .bold()
                    
                    Text("Please enable Siri in your device settings to use this feature.")
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
            }
        }
    }
}

// Safer UIViewControllerRepresentable implementation
struct SiriShortcutViewControllerWrapper: UIViewControllerRepresentable {
    let intent: INIntent
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIViewController {
        // Create a container view controller to handle potential errors
        let containerViewController = UIViewController()
        
        // Try to create the shortcut safely
        if let shortcut = createShortcut() {
            let viewController = INUIAddVoiceShortcutViewController(shortcut: shortcut)
            viewController.delegate = context.coordinator
            containerViewController.addChild(viewController)
            containerViewController.view.addSubview(viewController.view)
            viewController.view.frame = containerViewController.view.bounds
            viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            viewController.didMove(toParent: containerViewController)
            return containerViewController
        } else {
            // If shortcut creation fails, show an error view controller
            let errorViewController = UIHostingController(
                rootView: Text("Unable to create Siri shortcut")
                    .foregroundColor(.red)
                    .padding()
            )
            containerViewController.addChild(errorViewController)
            containerViewController.view.addSubview(errorViewController.view)
            errorViewController.view.frame = containerViewController.view.bounds
            errorViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            errorViewController.didMove(toParent: containerViewController)
            return containerViewController
        }
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Nothing to update
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func createShortcut() -> INShortcut? {
        return INShortcut(intent: intent)
    }
    
    class Coordinator: NSObject, INUIAddVoiceShortcutViewControllerDelegate {
        var parent: SiriShortcutViewControllerWrapper
        
        init(_ parent: SiriShortcutViewControllerWrapper) {
            self.parent = parent
        }
        
        func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
            if let error = error {
                print("Error adding shortcut: \(error.localizedDescription)")
            } else if let shortcut = voiceShortcut {
                print("Added voice shortcut: \(shortcut.invocationPhrase)")
                // Post success notification
                NotificationCenter.default.post(name: NSNotification.Name("SiriShortcutAdded"), object: nil)
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// Helper to show available Siri shortcuts
struct SiriShortcutsInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Available Siri Commands")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\"Hey Siri, scan ISBN\"")
                            .font(.headline)
                        Text("Opens the ISBN scanner for adding books")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\"Hey Siri, issue books\"")
                            .font(.headline)
                        Text("Opens the QR scanner for issuing books to members")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("How to Use")) {
                    Text("You can use these commands anytime without opening the app. Just say \"Hey Siri\" followed by the command.")
                        .font(.body)
                        .padding(.vertical, 8)
                }
            }
            .navigationTitle("Siri Voice Commands")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SiriButton()
        .environmentObject(AccessibilityManager())
        .padding()
} 