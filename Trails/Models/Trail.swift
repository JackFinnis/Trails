//
//  Trail.swift
//  Trails
//
//  Created by Jack Finnis on 16/02/2023.
//

import Foundation
import MapKit
import CoreData

class Trail: NSObject, MKOverlay, Codable {
    let id: Int
    let name: String
    let start: String
    let end: String
    let metres: Double
    let lines: [[[Double]]]
    
    var formattedDistance: String { Measurement(value: metres, unit: UnitLength.meters).formatted() }
    
    lazy var linesCoords: [[CLLocationCoordinate2D]] = {
        lines.map { $0.map { CLLocationCoordinate2DMake($0[0], $0[1]) }}
    }()
    lazy var linesLocations: [[CLLocation]] = {
        linesCoords.map { $0.map { $0.location } }
    }()
    lazy var multiPolyline: MKMultiPolyline = {
        MKMultiPolyline(linesCoords.map { MKPolyline(coordinates: $0, count: $0.count) })
    }()
    
    var coordinate: CLLocationCoordinate2D { multiPolyline.coordinate }
    var boundingMapRect: MKMapRect { multiPolyline.boundingMapRect }
}

@objc(Trip)
class Trip: NSManagedObject, MKOverlay {
    @NSManaged var line: [[Double]]
    @NSManaged var id: Int
    
    lazy var lineCoords: [CLLocationCoordinate2D] = {
        line.map { CLLocationCoordinate2DMake($0[0], $0[1]) }
    }()
    lazy var polyline: MKPolyline = {
        MKPolyline(coordinates: lineCoords, count: lineCoords.count)
    }()
    
    var coordinate: CLLocationCoordinate2D { polyline.coordinate }
    var boundingMapRect: MKMapRect { polyline.boundingMapRect }
}
