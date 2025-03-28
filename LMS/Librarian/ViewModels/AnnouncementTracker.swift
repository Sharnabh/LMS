//
//  AnnouncementTracker.swift
//  LMS
//
//  Created by Sharnabh on 28/03/25.
//

import Foundation
import SwiftUI

class AnnouncementTracker: ObservableObject {
    static let shared = AnnouncementTracker()
    
    private let seenAnnouncementsKey = "seen_announcements"
    @Published private(set) var seenAnnouncementIds: Set<String> = []
    
    private init() {
        // Load saved seen announcement IDs from UserDefaults
        if let savedIdsData = UserDefaults.standard.data(forKey: seenAnnouncementsKey),
           let savedIds = try? JSONDecoder().decode([String].self, from: savedIdsData) {
            seenAnnouncementIds = Set(savedIds)
        }
    }
    
    func markAsSeen(_ announcement: AnnouncementModel) {
        seenAnnouncementIds.insert(announcement.id.uuidString)
        saveSeenAnnouncements()
    }
    
    func markAllAsSeen(_ announcements: [AnnouncementModel]) {
        for announcement in announcements {
            seenAnnouncementIds.insert(announcement.id.uuidString)
        }
        saveSeenAnnouncements()
    }
    
    func hasSeenAnnouncement(_ announcement: AnnouncementModel) -> Bool {
        return seenAnnouncementIds.contains(announcement.id.uuidString)
    }
    
    func getUnseenCount(from announcements: [AnnouncementModel]) -> Int {
        return announcements.filter { !hasSeenAnnouncement($0) }.count
    }
    
    private func saveSeenAnnouncements() {
        if let encodedData = try? JSONEncoder().encode(Array(seenAnnouncementIds)) {
            UserDefaults.standard.set(encodedData, forKey: seenAnnouncementsKey)
        }
    }
}
