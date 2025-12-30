//
//  AccessibilityAnnouncements.swift
//  OffshoreBudgeting
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum AccessibilityAnnouncements {
    private static var lastMessage: String?
    private static var lastTimestamp: TimeInterval = 0

    static func announceStatusChangeIfNeeded(message: String) {
        #if canImport(UIKit)
        let now = Date().timeIntervalSince1970
        let isDuplicate = lastMessage == message && (now - lastTimestamp) < 1.0
        guard !isDuplicate else { return }
        lastMessage = message
        lastTimestamp = now
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
        #endif
    }
}
