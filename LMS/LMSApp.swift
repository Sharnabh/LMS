//
//  LMSApp.swift
//  LMS
//
//  Created by Sharnabh on 17/03/25.
//

import SwiftUI
import Speech
import AVFoundation
import WidgetKit

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
    @StateObject private var appState = AppState()
    @State private var showIsbnScanner = false
    @State private var showQRScanner = false
    @AppStorage("librarianIsLoggedIn") private var librarianIsLoggedIn = false
    @AppStorage("librarianEmail") private var librarianEmail = ""
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(accessibilityManager)
                .environmentObject(appState)
                .onAppear {
                    configureAccessibility()
                    
                    // Debug librarian login state
                    if librarianIsLoggedIn {
                        print("Librarian logged in: \(librarianEmail)")
                    } else {
                        print("No librarian logged in")
                    }
                }
                .onOpenURL { url in
                    handleURL(url)
                }
                .sheet(isPresented: $showIsbnScanner) {
                    ISBNScannerWrapper { code in
                        print("Scanned ISBN: \(code)")
                        // Handle the scanned code - fetch and add book to Supabase
                        Task {
                            await handleScannedISBN(code)
                        }
                    }
                    .environmentObject(accessibilityManager)
                }
                .sheet(isPresented: $showQRScanner) {
                    QRScanner(isPresentedAsFullScreen: false)
                    .environmentObject(accessibilityManager)
                }
        }
    }
    
    private func configureAccessibility() {
        // Enable voice command button in accessibility options
        UIAccessibility.post(notification: .announcement, argument: "Voice commands available. Activate through accessibility menu.")
    }
    
    private func handleURL(_ url: URL) {
        // Handle the pustkalaya:// URL scheme (as defined in WidgetConfig)
        guard let scheme = url.scheme?.lowercased(),
              scheme == "pustkalaya" else {
            print("Unknown URL scheme: \(url)")
            return
        }
        
        // Check if a librarian is logged in for widget actions
        if !librarianIsLoggedIn || librarianEmail.isEmpty {
            print("Widget action attempted, but no librarian is logged in")
            
            // Set app state to reset to first screen and show role selection
            appState.resetToFirstScreen()
            
            // Delay to ensure the app is fully loaded before showing the announcement
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UIAccessibility.post(notification: .announcement, argument: "Please log in as a librarian to use this feature")
            }
            return
        }
        
        let host = url.host?.lowercased() ?? ""
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []
        
        // Extract ISBN from query parameters if available
        let isbnParam = queryItems.first(where: { $0.name == "isbn" })?.value
        
        // Check for ISBN scanner paths
        if host.contains("isbn") || host.contains("barcode") {
            if let isbn = isbnParam, !isbn.isEmpty {
                // If ISBN is provided in URL, process it directly
                print("Processing ISBN from URL: \(isbn)")
                
                // Announce that we're processing the ISBN
                UIAccessibility.post(notification: .announcement, argument: "Processing ISBN code from widget")
                
                Task {
                    await handleScannedISBN(isbn)
                }
            } else {
                // Otherwise open the scanner
                showIsbnScanner = true
                print("Opening ISBN scanner from widget via URL: \(url)")
                
                // Announce that we're opening the scanner
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    UIAccessibility.post(notification: .announcement, argument: "Opening ISBN scanner. Please position barcode in view.")
                }
            }
        }
        // Check for QR scanner paths
        else if host.contains("qr") || host.contains("check") {
            showQRScanner = true
            print("Opening QR scanner from widget via URL: \(url)")
            
            // Announce that we're opening the QR scanner
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                UIAccessibility.post(notification: .announcement, argument: "Opening QR scanner for check-in or check-out.")
            }
        }
        else {
            print("Unknown URL path: \(url)")
            
            // Announce error for unknown URL
            UIAccessibility.post(notification: .announcement, argument: "Unknown action requested.")
        }
    }
    
    @MainActor
    private func handleScannedISBN(_ isbn: String) async {
        print("Processing scanned ISBN: \(isbn)")
        
        // Check if a librarian is logged in
        guard librarianIsLoggedIn, !librarianEmail.isEmpty else {
            print("Error: No librarian is logged in")
            UIAccessibility.post(notification: .announcement, argument: "Error: Please log in as a librarian to add books")
            
            // Reset to the initial role selection screen
            appState.resetToFirstScreen()
            
            // Delay to ensure view changes before announcement
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UIAccessibility.post(notification: .announcement, argument: "Please select the librarian role and log in to add books")
            }
            return
        }
        
        // Set ISBN to process immediately - this will be used if the book fetch fails
        appState.isbnToProcess = isbn
        
        // Create a temporary BookStore to handle the book addition
        let bookStore = BookStore()
        
        do {
            // First, fetch the book details from Google Books API
            let fetchedBook = try await GoogleBooksService.fetchBookByISBN(isbn: isbn)
            print("Book fetched successfully: \(fetchedBook.title) with ISBN: \(fetchedBook.ISBN)")
            
            // Store the book in app state for AddView to display
            appState.scannedBook = fetchedBook
            
            // After we have the book data, set the navigation flag
            // This ensures we have data ready when the AddView appears
            appState.shouldNavigateToAddBooks = true
            
            // Show success feedback to user
            UIAccessibility.post(notification: .announcement, argument: "Book found: \(fetchedBook.title)")
        } catch {
            print("Error fetching book with ISBN \(isbn): \(error)")
            
            // Even if we fail to fetch the book, still navigate to the AddView
            // where the user can manually enter the ISBN
            appState.shouldNavigateToAddBooks = true
            
            UIAccessibility.post(notification: .announcement, argument: "Error: Could not find book with ISBN \(isbn)")
        }
    }
}
