//
//  DistanceLabel.swift
//  Trails
//
//  Created by Jack Finnis on 19/02/2023.
//

import SwiftUI

struct DistanceLabel: View {
    let metres: Double
    
    var body: some View {
        Text(Measurement(value: metres, unit: UnitLength.meters).formatted())
    }
}
