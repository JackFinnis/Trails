//
//  CLLocation.swift
//  Trails
//
//  Created by Jack Finnis on 20/03/2023.
//

import Foundation
import CoreLocation

extension Array where Element == CLLocation {
    func metres() -> Double {
        guard count >= 2 else { return 0 }
        var distance = Double.zero
        
        for i in 1..<count {
            distance += self[i].distance(from: self[i - 1])
        }
        return distance
    }
}
