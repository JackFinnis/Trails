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
    let colour: Int
    let cycleStatus: CycleStatus
    let ascent: Double?
    let country: Country
    
    let coords: [CLLocationCoordinate2D]
    let locations: [CLLocation]
    let polyline: MKPolyline
    
    init(metadata: TrailMetadata, polyline: MKPolyline) {
        self.polyline = polyline
        coords = polyline.coordinates
        locations = coords.map { $0.location }
        
        id = metadata.id
        name = metadata.name
        headline = metadata.description
        url = metadata.url
        photoUrl = metadata.photoUrl
        metres = metadata.metres
        days = metadata.days
        colour = metadata.colour
        cycleStatus = metadata.cycleStatus
        ascent = metadata.ascent
        country = metadata.country
    }
    
    static let example = Trail(metadata: .init(id: 0, name: "Cleveland Way", description: "Experience the varied landscape of the North York Moors National Park on a journey across breathtaking heather moorland and dramatic coastline.", url: URL(string: "https://www.nationaltrail.co.uk/trails/cleveland-way/")!, photoUrl: URL(string: "https://nationaltrails.s3.eu-west-2.amazonaws.com/uploads/Cleveland-Way-Home-2000x600.jpg")!, metres: 170813, days: 9, colour: 1, cycleStatus: .no, ascent: 5031, country: .england), polyline: MKPolyline())
}

extension Trail: MKOverlay {
    var coordinate: CLLocationCoordinate2D { polyline.coordinate }
    var boundingMapRect: MKMapRect { polyline.boundingMapRect }
}

struct TrailMetadata: Codable {
    let id: Int16
    let name: String
    let description: String
    let url: URL
    let photoUrl: URL
    let metres: Double
    let days: Int
    let colour: Int
    let cycleStatus: CycleStatus
    let ascent: Double?
    let country: Country
}

@objc(TrailTrips)
class TrailTrips: NSManagedObject {
    @NSManaged var id: Int16
    @NSManaged var lines: [[[Double]]]
    
    var coordsSet = Set<CLLocationCoordinate2D>()
    var multiPolyline = MKMultiPolyline()
    var metres = 0.0
    
    func reload() {
        let linesCoords = lines.map { $0.map { CLLocationCoordinate2DMake($0[0], $0[1]) } }
        coordsSet = Set(linesCoords.concat())
        multiPolyline = MKMultiPolyline(linesCoords.map { MKPolyline(coordinates: $0, count: $0.count) })
        metres = linesCoords.map { $0.metres() }.sum()
    }
}

extension TrailTrips: MKOverlay {
    var coordinate: CLLocationCoordinate2D { multiPolyline.coordinate }
    var boundingMapRect: MKMapRect { multiPolyline.boundingMapRect }
}

enum Country: String, Codable, CaseIterable {
    case england = "England"
    case scotland = "Scotland"
    case wales = "Wales"
    case ni = "Northern Ireland"
}

enum TrailSort: String, CaseIterable, Codable {
    case name = "Name"
    case distance = "Length"
    case ascent = "Total Ascent"
    case completed = "Percentage Completed"
}

enum CycleStatus: String, Codable {
    case no
    case yes
    case sections
}
