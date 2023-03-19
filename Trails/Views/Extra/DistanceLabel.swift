//
//  DistanceLabel.swift
//  Trails
//
//  Created by Jack Finnis on 19/02/2023.
//

import SwiftUI

struct DistanceLabel: View {
    @AppStorage("metric") var metric = true
    
    let metres: Double
    
    var formattedDistance: String {
        let value = metres / (metric ? 1000 : 1609.34)
        return String(format: "%.1f", value) + (metric ? " km" : " miles")
    }
    
    var body: some View {
        Text(formattedDistance)
    }
}
