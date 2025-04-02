//
//  LMSApp.swift
//  LMS
//
//  Created by Sharnabh on 17/03/25.
//

import SwiftUI
import Speech
import AVFoundation
import Intents
import IntentsUI

// Accessibility Manager to handle voice commands
class AccessibilityManager: NSObject, ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @Published var isListening = false
    @Published var commandDetected = ""
    @Published var shouldScanISBN = false
    @Published var shouldIssueBook = false
    
    // Siri integration properties
    private var hasDonatedSiriShortcuts = false
    @Published var isSiriAvailable = false
    
    override init() {
        super.init()
        requestPermissions()
        checkSiriAvailability()
    }
    
    // MARK: - Permissions and Setup
    
    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                var message = ""
                
                switch status {
                case .authorized:
                    message = "Speech recognition authorized"
                case .denied:
                    message = "Speech recognition permission denied"
                case .restricted:
                    message = "Speech recognition is restricted"
                case .notDetermined:
                    message = "Speech recognition not determined"
                @unknown default:
                    message = "Unknown authorization status"
                }
                
                print(message)
            }
        }
    }
    
    // MARK: - Siri Integration
    
    private func checkSiriAvailability() {
        // Only try to use Siri if the capability is available
        if Bundle.main.object(forInfoDictionaryKey: "NSSiriUsageDescription") != nil {
            do {
                // This will throw an exception if Siri capability is not enabled
                try INPreferences.requestSiriAuthorization { status in
                    DispatchQueue.main.async {
                        if status == .authorized {
                            print("Siri is authorized")
                            self.isSiriAvailable = true
                            self.setupSiriIntents()
                        } else {
                            print("Siri authorization status: \(status.rawValue)")
                            self.isSiriAvailable = false
                        }
                    }
                }
            } catch {
                print("Siri capability is not enabled in this app: \(error.localizedDescription)")
                isSiriAvailable = false
            }
        } else {
            print("NSSiriUsageDescription not found in Info.plist")
            isSiriAvailable = false
        }
    }
    
    func setupSiriIntents() {
        guard isSiriAvailable else {
            print("Skipping Siri setup as it's not available")
            return
        }
        
        // We'll donate these intents to Siri when appropriate
        if !hasDonatedSiriShortcuts {
            donateSiriShortcuts()
        }
        
        // Listen for Siri intent notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.handleSiriIntent(_:)),
            name: NSNotification.Name("SiriIntentReceived"),
            object: nil
        )
    }
    
    func donateSiriShortcuts() {
        guard isSiriAvailable else { return }
        
        do {
            // Try to create valid shortcuts for the simulator debugging
            if let scanIntent = INShortcut.shortcutAvailable ? ScanISBNIntent() : nil {
                scanIntent.suggestedInvocationPhrase = "Scan ISBN"
                
                let scanInteraction = INInteraction(intent: scanIntent, response: nil)
                scanInteraction.donate { error in
                    if let error = error {
                        print("Donation error: \(error.localizedDescription)")
                    } else {
                        print("Successfully donated Scan ISBN intent")
                    }
                }
            }
            
            if let issueIntent = INShortcut.shortcutAvailable ? IssueBookIntent() : nil {
                issueIntent.suggestedInvocationPhrase = "Issue books"
                
                let issueInteraction = INInteraction(intent: issueIntent, response: nil)
                issueInteraction.donate { error in
                    if let error = error {
                        print("Donation error: \(error.localizedDescription)")
                    } else {
                        print("Successfully donated Issue Book intent")
                    }
                }
            }
            
            hasDonatedSiriShortcuts = true
        } catch {
            print("Error donating Siri shortcuts: \(error.localizedDescription)")
        }
    }
    
    @objc func handleSiriIntent(_ notification: Notification) {
        guard let intentResponse = notification.object as? INIntentResponse else { return }
        
        if intentResponse is ScanISBNIntentResponse {
            print("Received Scan ISBN intent from Siri")
            DispatchQueue.main.async {
                self.shouldScanISBN = true
                UIAccessibility.post(notification: .announcement, argument: "Opening ISBN scanner from Siri")
            }
        } else if intentResponse is IssueBookIntentResponse {
            print("Received Issue Book intent from Siri")
            DispatchQueue.main.async {
                self.shouldIssueBook = true
                UIAccessibility.post(notification: .announcement, argument: "Opening book issue from Siri")
            }
        }
    }
    
    // MARK: - Manual Voice Command Recognition (existing functionality)
    
    func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }
    
    func startListening() {
        // Reset any previous tasks
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest,
              let speechRecognizer = speechRecognizer,
              speechRecognizer.isAvailable else {
            print("Speech recognizer unavailable")
            return
        }
        
        // Configure the microphone input
        let inputNode = audioEngine.inputNode
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                // Process the speech result
                self.processCommand(result.bestTranscription.formattedString)
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                DispatchQueue.main.async {
                    self.isListening = false
                }
            }
        }
        
        // Start recording
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isListening = true
                // Provide feedback that listening has started
                UIAccessibility.post(notification: .announcement, argument: "Listening for voice commands")
            }
        } catch {
            print("Audio engine couldn't start: \(error)")
        }
    }
    
    func stopListening() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        
        DispatchQueue.main.async {
            self.isListening = false
            // Provide feedback that listening has stopped
            UIAccessibility.post(notification: .announcement, argument: "Voice commands disabled")
        }
    }
    
    private func processCommand(_ text: String) {
        let lowercaseText = text.lowercased()
        DispatchQueue.main.async {
            self.commandDetected = text
            
            // Process ISBN scanning command
            if lowercaseText.contains("scan isbn") || lowercaseText.contains("scan book") || 
               lowercaseText.contains("scan barcode") {
                self.shouldScanISBN = true
                self.stopListening()
                UIAccessibility.post(notification: .announcement, argument: "Opening ISBN scanner")
            }
            
            // Process book issue command
            if lowercaseText.contains("issue book") || lowercaseText.contains("borrow book") ||
               lowercaseText.contains("check out book") {
                self.shouldIssueBook = true
                self.stopListening()
                UIAccessibility.post(notification: .announcement, argument: "Starting book issue process")
            }
        }
    }
    
    func resetCommands() {
        shouldScanISBN = false
        shouldIssueBook = false
        commandDetected = ""
    }
    
    // MARK: - Add new support for Siri commands
    
    func handleSiriCommand(_ command: String) {
        // Process the command from Siri
        processCommand(command)
    }
    
    // MARK: - Handle Siri Intent Responses
    
    // This method would be called from the app's IntentHandler in the extension
    func handleIntentResponse(for intent: INIntent) {
        if intent is ScanISBNIntent {
            DispatchQueue.main.async {
                self.shouldScanISBN = true
            }
        } else if intent is IssueBookIntent {
            DispatchQueue.main.async {
                self.shouldIssueBook = true
            }
        }
    }
}

// MARK: - Siri Intent Definitions
// These would normally be generated from the Intents.intentdefinition file

class ScanISBNIntent: INIntent {
    // Simple intent for ISBN scanning
}

class ScanISBNIntentResponse: INIntentResponse {
    // Response for the intent
}

class IssueBookIntent: INIntent {
    // Simple intent for book issuing
}

class IssueBookIntentResponse: INIntentResponse {
    // Response for the intent
}

// MARK: - Helper extension for Siri availability
extension INShortcut {
    static var shortcutAvailable: Bool {
        if #available(iOS 12.0, *) {
            return true
        }
        return false
    }
}

// MARK: - App Integration
// In a real app, you would implement an IntentHandler in a separate Intent Extension

/*
 Example of how to handle intents in an extension:
 
 class IntentHandler: INExtension {
     override func handler(for intent: INIntent) -> Any {
         if intent is ScanISBNIntent {
             return ScanISBNIntentHandler()
         } else if intent is IssueBookIntent {
             return IssueBookIntentHandler()
         }
         
         return self
     }
 }
 
 class ScanISBNIntentHandler: NSObject, ScanISBNIntentHandling {
     func handle(intent: ScanISBNIntent, completion: @escaping (ScanISBNIntentResponse) -> Void) {
         // Notify the main app to open the scanner
         NotificationCenter.default.post(name: NSNotification.Name("SiriIntentReceived"), 
                                        object: ScanISBNIntentResponse())
         
         let response = ScanISBNIntentResponse()
         completion(response)
     }
 }
 */

@main
struct LMSApp: App {
    @StateObject private var accessibilityManager = AccessibilityManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(accessibilityManager)
                .onAppear {
                    configureAccessibility()
                }
        }
    }
    
    private func configureAccessibility() {
        // Enable voice command button in accessibility options
        UIAccessibility.post(notification: .announcement, argument: "Voice commands available. Activate through accessibility menu.")
    }
}
