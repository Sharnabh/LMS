//
//  PustaklayaWidgitBundle.swift
//  PustaklayaWidgit
//
//  Created by Sharnabh on 02/04/25.
//

import WidgetKit
import SwiftUI

@main
struct PustaklayaWidgitBundle: WidgetBundle {
    var body: some Widget {
        // Original widgets
        PustaklayaWidgit()
        PustaklayaWidgitControl()
        
        // New scanner widgets
        ISBNScannerWidget()
        QRScannerWidget()
    }
}
