//
//  QRScannerWidget.swift
//  PustaklayaWidgit
//
//  Created by Assistant on 02/04/25.
//

import WidgetKit
import SwiftUI
import AppIntents

struct QRScannerProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> QRScannerEntry {
        QRScannerEntry(date: Date())
    }

    func snapshot(for configuration: QRScannerWidgetIntent, in context: Context) async -> QRScannerEntry {
        QRScannerEntry(date: Date())
    }
    
    func timeline(for configuration: QRScannerWidgetIntent, in context: Context) async -> Timeline<QRScannerEntry> {
        let entries = [QRScannerEntry(date: Date())]
        return Timeline(entries: entries, policy: .never)
    }
}

struct QRScannerEntry: TimelineEntry {
    let date: Date
    var configuration: QRScannerWidgetIntent? = nil
}

struct QRScannerWidgetEntryView : View {
    var entry: QRScannerProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        ZStack {
            Color.green.opacity(0.1)
            
            VStack(spacing: 8) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: family == .systemSmall ? 32 : 48))
                    .foregroundColor(.green)
                
                Text("Check-In/Out")
                    .font(family == .systemSmall ? .caption : .headline)
                    .bold()
                    .foregroundColor(.primary)
                
                if family != .systemSmall {
                    Text("Tap to scan member QR codes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Login requirement indicator
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                        Text("Librarian login required")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
                }
            }
            .padding()
        }
        .widgetURL(URL(string: WidgetConfig.URLSchemes.qrScannerURL))
    }
}

struct QRScannerWidget: Widget {
    let kind: String = WidgetRegistry.qrScannerKind

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: QRScannerWidgetIntent.self, provider: QRScannerProvider()) { entry in
            QRScannerWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .contentMarginsDisabled()
        .supportedFamilies([.systemSmall, .systemMedium])
        .configurationDisplayName(WidgetRegistry.qrScannerDisplayName)
        .description("Scan QR codes to check-in or check-out books. Requires librarian login.")
    }
}

#Preview(as: .systemSmall) {
    QRScannerWidget()
} timeline: {
    QRScannerEntry(date: .now)
}

#Preview(as: .systemMedium) {
    QRScannerWidget()
} timeline: {
    QRScannerEntry(date: .now)
} 