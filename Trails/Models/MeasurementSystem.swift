//
//  Speed.swift
//  Trails
//
//  Created by Jack Finnis on 28/05/2023.
//

import SwiftUI

enum MeasurementSystem: String, Codable, CaseIterable {
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
    
    var metres: Double {
        switch self {
        case .metric:
            return 1000
        case .imperial:
            return 1609.34
        }
    }
    
    func formatSpeed(_ speed: Double, decimalPlaces: Int = 1) -> String {
        String(format: "%.\(decimalPlaces)f", speed) + " " + speedUnit
    }
}

struct MeasurementSystemPicker: View {
    @EnvironmentObject var vm: ViewModel
    
    let speed: Bool
    
    var body: some View {
        Picker("", selection: $vm.measurementSystem) {
            ForEach(MeasurementSystem.allCases, id: \.self) { system in
                Text(system.name + (speed ? " per hour" : ""))
            }
        }
    }
}
