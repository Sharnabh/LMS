import SwiftUI

struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let dismissButton: Alert.Button
}

struct AlertContext {
    static let invalidDeviceInput = AlertItem(
        title: "Invalid Device Input",
        message: "Something is wrong with the camera. We are unable to capture the input.",
        dismissButton: .default(Text("OK"))
    )
    
    static let invalidScanType = AlertItem(
        title: "Invalid Scan Type",
        message: "The value scanned is not valid. This app scans Library QR codes only.",
        dismissButton: .default(Text("OK"))
    )
    
    static let invalidQRCode = AlertItem(
        title: "Invalid QR Code",
        message: "The QR code does not contain valid library book information. Please scan a QR code with either JSON or labeled text format.",
        dismissButton: .default(Text("OK"))
    )
    
    static let invalidJSONFormat = AlertItem(
        title: "Invalid JSON Format",
        message: "The QR code contains JSON data but not in the expected format. Please ensure it has bookIds, memberId, issueStatus, issueDate, and returnDate fields.",
        dismissButton: .default(Text("OK"))
    )
    
    static let missingRequiredFields = AlertItem(
        title: "Missing Information",
        message: "The QR code is missing required book information fields. Please scan a valid library QR code.",
        dismissButton: .default(Text("OK"))
    )
    
    static let expiredQRCode = AlertItem(
        title: "Expired QR Code",
        message: "This QR code has expired and is no longer valid. Please generate a new QR code.",
        dismissButton: .default(Text("OK"))
    )
} 