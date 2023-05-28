//
//  Speed.swift
//  Trails
//
//  Created by Jack Finnis on 28/05/2023.
//

import Foundation

enum DistanceUnit: String, Codable, CaseIterable {
    case metric
    case imperial
    
    var name: String {
        switch self {
        case .metric:
            return "Kilometres"
        case .imperial:
            return "Miles"
        }
    }
    
    var speedUnit: String {
        switch self {
        case .metric:
            return "kmh"
        case .imperial:
            return "mph"
        }
    }
    
    var distanceUnit: String {
        switch self {
        case .metric:
            return "km"
        case .imperial:
            return "mi"
        }
    }
    
    var speeds: [Double] {
        switch self {
        case .metric:
            return [3.0, 3.5, 4.0, 4.5, 5.0]
        case .imperial:
            return [1.9, 2.2, 2.5, 2.8, 3.1]
        }
    }
    
    var conversion: Double {
        switch self {
        case .metric:
            return 1000
        case .imperial:
            return 1609.34
        }
    }
    
    func formatSpeed(_ speed: Double, places: Int = 1) -> String {
        String(format: "%.\(places)f", speed) + " " + speedUnit
    }
    
    var formatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.zeroSymbol = ""
        return formatter
    }
}
