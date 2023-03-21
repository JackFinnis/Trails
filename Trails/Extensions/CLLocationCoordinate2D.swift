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
        lhs.latitude.equalTo(rhs.latitude, to: 5) && lhs.longitude.equalTo(rhs.longitude, to: 5)
    }
    
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}

extension Array where Element == CLLocationCoordinate2D {
    func metres() -> Double {
        map(\.location).metres()
    }
}
