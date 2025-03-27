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
    @Environment(\.dismiss) private var dismiss
    
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
                    Text("Scan Library QR Code")
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
            .navigationBarItems(trailing: Button("Close") {
                dismiss()
            })
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
            // Check if the QR code is expired
            let expirationDate = Date(timeIntervalSince1970: parsedInfo.expirationDate)
            if Date() > expirationDate {
                alertItem = AlertContext.expiredQRCode
                isProcessing = false
                return
            }
            
            // Check if the issue status is valid
            if parsedInfo.issueStatus != "Pending" {
                alertItem = AlertItem(
                    title: "Invalid Issue Status",
                    message: "This QR code has already been processed or is invalid.",
                    dismissButton: .default(Text("OK"))
                )
                isProcessing = false
                return
            }
            
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
            case .expired:
                alertItem = AlertContext.expiredQRCode
            }
            // Keep isProcessing true until alert is dismissed
        }
    }
}

#Preview {
    QRScanner()
}
