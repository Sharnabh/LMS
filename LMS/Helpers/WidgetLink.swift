//
//  WidgetLink.swift
//  LMS
//
//  Created by Assistant on 02/04/25.
//

import Foundation
import SwiftUI

struct WidgetLink {
    // Widget URL schemes for deep linking
    struct URLSchemes {
        // The URL scheme prefix for all deep links
        static let scheme = "pustkalaya"
        
        // Scanner URL paths
        static let isbnScanner = "isbn-scanner"
        static let qrScanner = "qr-scanner"
        
        // Full URLs for deep linking
        static let isbnScannerURL = "\(scheme)://\(isbnScanner)"
        static let qrScannerURL = "\(scheme)://\(qrScanner)"
    }
    
    // Open URL helpers
    static func openISBNScanner() {
        if let url = URL(string: URLSchemes.isbnScannerURL) {
            UIApplication.shared.open(url)
        }
    }
    
    static func openQRScanner() {
        if let url = URL(string: URLSchemes.qrScannerURL) {
            UIApplication.shared.open(url)
        }
    }
} 