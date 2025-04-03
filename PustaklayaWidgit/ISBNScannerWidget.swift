//
//  ISBNScannerWidget.swift
//  PustaklayaWidgit
//
//  Created by Assistant on 02/04/25.
//

import WidgetKit
import SwiftUI
import AppIntents

// Define the intent directly to avoid import issues
struct ISBNScannerWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "ISBN Scanner Widget" }
    static var description: IntentDescription { "Scan ISBN to add new books." }
    
    @Parameter(title: "ISBN", default: "")
    var isbn: String
}

struct ISBNScannerProvider: AppIntentTimelineProvider {
    typealias Intent = ISBNScannerWidgetIntent
    typealias Entry = ISBNScannerEntry
    
    func placeholder(in context: Context) -> ISBNScannerEntry {
        ISBNScannerEntry(date: Date())
    }

    func snapshot(for configuration: ISBNScannerWidgetIntent, in context: Context) async -> ISBNScannerEntry {
        ISBNScannerEntry(date: Date(), configuration: configuration)
    }
    
    func timeline(for configuration: ISBNScannerWidgetIntent, in context: Context) async -> Timeline<ISBNScannerEntry> {
        let entries = [ISBNScannerEntry(date: Date(), configuration: configuration)]
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
        .widgetURL(constructURL(isbn: entry.configuration?.isbn))
    }
    
    private func constructURL(isbn: String?) -> URL? {
        // Hardcode the URL for scanner
        let baseURLString = "pustkalaya://isbn-scanner"
        guard let baseURL = URL(string: baseURLString) else {
            return nil
        }
        
        // If we have an ISBN, add it as a query parameter
        // This allows the app to directly process a specific ISBN when the widget is tapped
        // without needing to open the scanner first
        if let isbn = isbn, !isbn.isEmpty {
            var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
            components?.queryItems = [URLQueryItem(name: "isbn", value: isbn)]
            return components?.url
        }
        
        return baseURL
    }
}

struct ISBNScannerWidget: Widget {
    let kind: String = WidgetRegistry.isbnScannerKind

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ISBNScannerWidgetIntent.self, provider: ISBNScannerProvider()) { entry in
            ISBNScannerWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(.systemBackground).opacity(0.5)
                }
        }
        .contentMarginsDisabled()
        .supportedFamilies([.systemSmall, .systemMedium])
        .configurationDisplayName("ISBN Scanner")
        .description("Scan ISBN barcodes to add books. Requires librarian login.")
    }
}

#Preview(as: .systemSmall) {
    ISBNScannerWidget()
} timeline: {
    ISBNScannerEntry(date: Date())
}

#Preview(as: .systemMedium) {
    ISBNScannerWidget()
} timeline: {
    ISBNScannerEntry(date: Date())
}