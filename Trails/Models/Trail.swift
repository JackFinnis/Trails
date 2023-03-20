//
//  Trail.swift
//  Trails
//
//  Created by Jack Finnis on 16/02/2023.
//

import Foundation
import MapKit
import CoreData
import SwiftUI

class Trail: NSObject, Identifiable {
    let id: Int16
    let name: String
    let headline: String
    let url: URL
    let photoUrl: URL
    let metres: Double
    let days: Int
    let lines: [[[Double]]]
    let colour: Int
    
    let linesCoords: [[CLLocationCoordinate2D]]
    let linesLocations: [[CLLocation]]
    let multiPolyline: MKMultiPolyline
    
    init(lines: TrailLines, metadata: TrailMetadata) {
        self.lines = lines.lines
        id = metadata.id
        name = metadata.name
        headline = metadata.description
        url = metadata.url
        photoUrl = metadata.photoUrl
        metres = metadata.metres
        days = metadata.days
        colour = metadata.colour
        
        linesCoords = lines.lines.map { $0.map { CLLocationCoordinate2DMake($0[0], $0[1]) }}
        linesLocations = linesCoords.map { $0.map { $0.location } }
        multiPolyline = MKMultiPolyline(linesCoords.map { MKPolyline(coordinates: $0, count: $0.count) })
    }
}

extension Trail: MKOverlay {
    var coordinate: CLLocationCoordinate2D { multiPolyline.coordinate }
    var boundingMapRect: MKMapRect { multiPolyline.boundingMapRect }
}

struct TrailLines: Codable {
    let id: Int
    let lines: [[[Double]]]
}

struct TrailMetadata: Codable {
    let id: Int16
    let name: String
    let description: String
    let url: URL
    let photoUrl: URL
    let km: Int
    let miles: Int
    let metres: Double
    let days: Int
    let colour: Int
}

@objc(TrailTrips)
class TrailTrips: NSManagedObject {
    @NSManaged var id: Int16
    @NSManaged var lines: [[[Double]]]
    
    var linesCoords: [[CLLocationCoordinate2D]] {
        lines.map { $0.map { CLLocationCoordinate2DMake($0[0], $0[1]) } }
    }
    var linesLocations: [[CLLocation]] {
        linesCoords.map { $0.map { $0.location } }
    }
    var multiPolyline: MKMultiPolyline {
        MKMultiPolyline(linesCoords.map { MKPolyline(coordinates: $0, count: $0.count) })
    }
    var metres: Double {
        linesCoords.map(\.metres).sum
    }
}

extension TrailTrips: MKOverlay {
    var coordinate: CLLocationCoordinate2D { multiPolyline.coordinate }
    var boundingMapRect: MKMapRect { multiPolyline.boundingMapRect }
}
