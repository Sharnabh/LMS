//
//  AppIntent.swift
//  PustaklayaWidgit
//
//  Created by Sharnabh on 02/04/25.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "Pustakalaya library management widget." }

    // An example configurable parameter.
    @Parameter(title: "Favorite Emoji", default: "📚")
    var favoriteEmoji: String
}

struct ISBNScannerWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "ISBN Scanner Widget" }
    static var description: IntentDescription { "Scan ISBN to add new books." }
}

struct QRScannerWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Check-In/Out Widget" }
    static var description: IntentDescription { "Scan QR codes to check-in or check-out books." }
}
