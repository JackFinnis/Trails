//
//  Trip.swift
//  Trails
//
//  Created by Jack Finnis on 15/03/2023.
//

import Foundation
import CoreData
import MapKit

@objc(Trip)
class Trip: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var trailID: Int16
    @NSManaged var line: [[Double]]
    
    lazy var lineCoords: [CLLocationCoordinate2D] = {
        line.map { CLLocationCoordinate2DMake($0[0], $0[1]) }
    }()
    lazy var polyline: MKPolyline = {
        MKPolyline(coordinates: lineCoords, count: lineCoords.count)
    }()
}

extension Trip: MKOverlay {
    var coordinate: CLLocationCoordinate2D { polyline.coordinate }
    var boundingMapRect: MKMapRect { polyline.boundingMapRect }
}
