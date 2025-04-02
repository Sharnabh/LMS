//
//  WidgetHelper.swift
//  LMS
//
//  Created by Assistant on 02/04/25.
//

import Foundation
import WidgetKit

struct WidgetHelper {
    // App Group identifier for sharing data between app and widget
    static let appGroupID = "group.com.infosys04.pustakalaya"
    
    // URL schemes for deep linking
    struct URLSchemes {
        static let isbnScanner = "pustkalaya://isbn-scanner"
        static let qrScanner = "pustkalaya://qr-scanner"
    }
    
    // Reload all widgets to refresh their content
    static func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // Check if the app was launched from a widget
    static func isAppLaunchedFromWidget(url: URL) -> Bool {
        return url.scheme == "pustkalaya"
    }
    
    // Determine which widget launched the app
    static func getWidgetType(from url: URL) -> WidgetType? {
        guard url.scheme == "pustkalaya" else { return nil }
        
        switch url.host {
        case "isbn-scanner":
            return .isbnScanner
        case "qr-scanner":
            return .qrScanner
        default:
            return nil
        }
    }
    
    // Widget types
    enum WidgetType {
        case isbnScanner
        case qrScanner
    }
} 