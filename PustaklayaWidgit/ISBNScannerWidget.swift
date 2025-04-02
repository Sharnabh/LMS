//
//  ISBNScannerWidget.swift
//  PustaklayaWidgit
//
//  Created by Assistant on 02/04/25.
//

import WidgetKit
import SwiftUI
import AppIntents

struct ISBNScannerProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ISBNScannerEntry {
        ISBNScannerEntry(date: Date())
    }

    func snapshot(for configuration: ISBNScannerWidgetIntent, in context: Context) async -> ISBNScannerEntry {
        ISBNScannerEntry(date: Date())
    }
    
    func timeline(for configuration: ISBNScannerWidgetIntent, in context: Context) async -> Timeline<ISBNScannerEntry> {
        let entries = [ISBNScannerEntry(date: Date())]
        return Timeline(entries: entries, policy: .never)
    }
}

struct ISBNScannerEntry: TimelineEntry {
    let date: Date
    var configuration: ISBNScannerWidgetIntent? = nil
}

struct ISBNScannerWidgetEntryView : View {
    var entry: ISBNScannerProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        ZStack {
            Color.blue.opacity(0.1)
            
            VStack(spacing: 8) {
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: family == .systemSmall ? 32 : 48))
                    .foregroundColor(.blue)
                
                Text("ISBN Scanner")
                    .font(family == .systemSmall ? .caption : .headline)
                    .bold()
                    .foregroundColor(.primary)
                
                if family != .systemSmall {
                    Text("Tap to scan book barcodes")
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
        .widgetURL(URL(string: WidgetConfig.URLSchemes.isbnScannerURL))
    }
}

struct ISBNScannerWidget: Widget {
    let kind: String = WidgetRegistry.isbnScannerKind

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ISBNScannerWidgetIntent.self, provider: ISBNScannerProvider()) { entry in
            ISBNScannerWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .contentMarginsDisabled()
        .supportedFamilies([.systemSmall, .systemMedium])
        .configurationDisplayName(WidgetRegistry.isbnScannerDisplayName)
        .description("Scan ISBN barcodes to add books. Requires librarian login.")
    }
}

#Preview(as: .systemSmall) {
    ISBNScannerWidget()
} timeline: {
    ISBNScannerEntry(date: .now)
}

#Preview(as: .systemMedium) {
    ISBNScannerWidget()
} timeline: {
    ISBNScannerEntry(date: .now)
}