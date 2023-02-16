//
//  Trail.swift
//  Trails
//
//  Created by Jack Finnis on 16/02/2023.
//

import Foundation
import MapKit

class Trail: NSObject {
    let name: String
    let start: String
    let end: String
    let metres: Int
    let multiPolyline: MKMultiPolyline
    
    init(trail: TrailCodable) {
        self.name = trail.name
        self.start = trail.start
        self.end = trail.end
        self.metres = trail.metres
        self.multiPolyline = MKMultiPolyline(trail.coords.map { coords in
            let coords = coords.map { CLLocationCoordinate2DMake($0[0], $0[1]) }
            return MKPolyline(coordinates: coords, count: coords.count)
        })
    }
}

extension Trail: MKOverlay {
    var coordinate: CLLocationCoordinate2D { multiPolyline.coordinate }
    var boundingMapRect: MKMapRect { multiPolyline.boundingMapRect }
}

struct TrailCodable: Codable {
    let coords: [[[Double]]]
    let name: String
    let start: String
    let end: String
    let metres: Int
}
