//
//  CLLocationCoordinate2D.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import Foundation
import MapKit

extension CLLocationCoordinate2D: Equatable, Hashable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude.equalTo(rhs.latitude, to: 4) && lhs.longitude.equalTo(rhs.longitude, to: 4)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude.rounded(to: 4))
        hasher.combine(longitude.rounded(to: 4))
    }
    
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}
