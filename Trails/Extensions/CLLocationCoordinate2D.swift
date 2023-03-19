//
//  CLLocationCoordinate2D.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import Foundation
import MapKit

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
    
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}

extension Array where Element == CLLocationCoordinate2D {
    func getDistance() -> Double {
        guard count >= 2 else { return 0 }
        let locations = map(\.location)
        var distance = Double.zero
        
        for i in 0..<locations.count-1 {
            distance += locations[i+1].distance(from: locations[i])
        }
        return distance
    }
}
