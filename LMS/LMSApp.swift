//
//  LMSApp.swift
//  LMS
//
//  Created by Sharnabh on 17/03/25.
//

import SwiftUI
import Speech
import AVFoundation

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
    
    override init() {
        super.init()
        requestPermissions()
    }
    
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
}

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
