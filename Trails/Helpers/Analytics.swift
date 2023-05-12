//
//  Analytics.swift
//  Geojson
//
//  Created by Jack Finnis on 12/05/2023.
//

import Foundation
import FirebaseAnalytics

enum AnalyticsEvent: String {
    case selectTrail
}

struct Analytics {
    static func log(_ event: AnalyticsEvent) {
        FirebaseAnalytics.Analytics.logEvent(event.rawValue, parameters: [:])
    }
}
