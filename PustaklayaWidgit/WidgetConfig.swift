//
//  WidgetConfig.swift
//  PustaklayaWidgit
//
//  Created by Assistant on 02/04/25.
//

import Foundation
import WidgetKit

struct WidgetConfig {
    // App Group identifier for sharing data between app and widget
    static let appGroupID = "group.com.infosys04.pustakalaya"
    
    // URL schemes for deep linking
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
    
    // Widget kind identifiers
    struct WidgetKinds {
        static let isbnScanner = "ISBNScannerWidget"
        static let qrScanner = "QRScannerWidget"
        static let mainWidget = "PustaklayaWidgit"
        static let controlWidget = "PustaklayaWidgitControl"
    }
} 