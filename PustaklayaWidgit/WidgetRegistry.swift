//
//  WidgetRegistry.swift
//  PustaklayaWidgit
//
//  Created by Assistant on 02/04/25.
//

import WidgetKit
import SwiftUI

struct WidgetRegistry {
    // Bundle ID
    static let bundleID = "com.infosys04.pustakalaya.PustaklayaWidgit"
    
    // Widget Display Names
    static let mainWidgetDisplayName = "Pustakalaya"
    static let isbnScannerDisplayName = "ISBN Scanner"
    static let qrScannerDisplayName = "Check-In/Out"
    
    // Widget Kinds - must be consistent across the app
    static let mainWidgetKind = "PustaklayaWidget"
    static let controlWidgetKind = "PustaklayaWidgetControl"
    static let isbnScannerKind = "ISBNScannerWidget"
    static let qrScannerKind = "QRScannerWidget"
    
    // Widget Descriptions
    static let isbnScannerDescription = "Scan ISBN barcodes to add new books. Requires librarian login."
    static let qrScannerDescription = "Scan QR codes to check-in or check-out books. Requires librarian login."
    
    // Reload all widgets
    static func reloadAll() {
        WidgetCenter.shared.reloadAllTimelines()
    }
} 