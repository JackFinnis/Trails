//
//  CLLocationCoordinate2D.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import Foundation
import MapKit

fileprivate let accuracy = 5

extension CLLocationCoordinate2D: Equatable, Hashable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude.equalTo(rhs.latitude, to: accuracy) && lhs.longitude.equalTo(rhs.longitude, to: accuracy)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude.rounded(to: accuracy))
        hasher.combine(longitude.rounded(to: accuracy))
    }
    
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    var rounded: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude.rounded(to: accuracy), longitude: longitude.rounded(to: accuracy))
    }
}
