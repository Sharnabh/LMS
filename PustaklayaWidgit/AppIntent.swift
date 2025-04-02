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

// Note: The ISBNScannerWidgetIntent and QRScannerWidgetIntent are now
// defined directly in their respective widget files to avoid compilation issues.
