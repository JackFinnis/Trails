//
//  TrailTrips.swift
//  Trails
//
//  Created by Jack Finnis on 21/05/2023.
//

import Foundation
import CoreData
import MapKit

@objc(TrailTrips)
class TrailTrips: NSManagedObject {
    @NSManaged var id: Int16
    @NSManaged var lines: [[[Double]]]
    
    var linesCoords = [[CLLocationCoordinate2D]]()
    var coordsSet = Set<CLLocationCoordinate2D>()
    var multiPolyline = MKMultiPolyline()
    var metres = 0.0
    
    func reload() {
        linesCoords = lines.map { $0.map { CLLocationCoordinate2DMake($0[0], $0[1]) } }
        coordsSet = Set(linesCoords.concat())
        multiPolyline = MKMultiPolyline(linesCoords.map { MKPolyline(coordinates: $0, count: $0.count) })
        metres = linesCoords.map { $0.metres() }.sum()
    }
}

extension TrailTrips: MKOverlay {
    var coordinate: CLLocationCoordinate2D { multiPolyline.coordinate }
    var boundingMapRect: MKMapRect { multiPolyline.boundingMapRect }
}
