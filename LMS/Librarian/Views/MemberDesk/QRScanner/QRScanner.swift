//
//  ContentView.swift
//  QRScanner
//
//  Created by Sharnabh on 21/03/25.
//

import SwiftUI

struct QRScanner: View {
    @State private var scannedCode = ""
    @State private var alertItem: AlertItem?
    @State private var bookInfo: BookInfo?
    @State private var isShowingBookInfo = false
    @State private var isProcessing = false
    @State private var lastProcessedCode = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                ScannerView(scannedCode: $scannedCode, alertItem: $alertItem)
                    .onAppear {
                        // Reset the scanned code when scanner appears
                        scannedCode = ""
                        lastProcessedCode = ""
                    }
                
                VStack {
                    Spacer()
                    Text("Scanning for Library QR Code...")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                    Spacer().frame(height: 100)
                }
            }
            .edgesIgnoringSafeArea(.all)
            .onChange(of: scannedCode) { newValue in
                // Only process if we have a non-empty code, we're not already processing,
                // and this isn't the same code we just processed
                if !newValue.isEmpty && !isProcessing && newValue != lastProcessedCode {
                    lastProcessedCode = newValue
                    isProcessing = true
                    processQRCode(newValue)
                }
            }
            .alert(item: $alertItem) { alertItem in
                Alert(
                    title: Text(alertItem.title),
                    message: Text(alertItem.message),
                    dismissButton: .default(Text("OK")) {
                        // After dismissing an alert, allow processing again
                        isProcessing = false
                    }
                )
            }
            .sheet(isPresented: $isShowingBookInfo, onDismiss: {
                // After showing book info, prepare for a new scan
                prepareForNewScan()
            }) {
                if let bookInfo = bookInfo {
                    BookInfoView(bookInfo: bookInfo)
                }
            }
        }
    }
    
    private func prepareForNewScan() {
        // Reset all scanner-related state
        isProcessing = false
        scannedCode = ""
        lastProcessedCode = ""
    }
    
    private func processQRCode(_ code: String) {
        guard !code.isEmpty else { 
            isProcessing = false
            return 
        }
        
        let result = QRCodeParser.parseBookInfo(from: code)
        
        switch result {
        case .success(let parsedInfo):
            bookInfo = parsedInfo
            isShowingBookInfo = true
            // Keep isProcessing true until book info is displayed
        case .failure(let error):
            switch error {
            case .invalidFormat:
                alertItem = AlertContext.invalidQRCode
            case .invalidJSON:
                alertItem = AlertContext.invalidJSONFormat
            case .missingFields:
                alertItem = AlertContext.missingRequiredFields
            }
            // Keep isProcessing true until alert is dismissed
        }
    }
}

#Preview {
    ContentView()
}
