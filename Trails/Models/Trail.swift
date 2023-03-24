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
    let cycle: Bool
    let ascent: Double?
    let country: Country
    
    let linesCoords: [[CLLocationCoordinate2D]]
    let linesLocations: [[CLLocation]]
    let multiPolyline: MKMultiPolyline
    
    init(lines: TrailLines, metadata: TrailMetadata) {
        multiPolyline = lines.multiPolyline
        linesCoords = multiPolyline.polylines.map(\.coordinates)
        linesLocations = linesCoords.map { $0.map { $0.location } }
        
        id = metadata.id
        name = metadata.name
        headline = metadata.description
        url = metadata.url
        photoUrl = metadata.photoUrl
        metres = metadata.metres
        days = metadata.days
        colour = metadata.colour
        cycle = metadata.cycle
        ascent = metadata.ascent
        country = metadata.country
    }
    
    static let example = Trail(lines: .init(id: 0, multiPolyline: .init()), metadata: .init(id: 0, name: "Cleveland Way", description: "Experience the varied landscape of the North York Moors National Park on a journey across breathtaking heather moorland and dramatic coastline.", url: URL(string: "https://www.nationaltrail.co.uk/trails/cleveland-way/")!, photoUrl: URL(string: "https://nationaltrails.s3.eu-west-2.amazonaws.com/uploads/Cleveland-Way-Home-2000x600.jpg")!, metres: 170813, days: 9, colour: 1, cycle: true, ascent: 5031, country: .england))
    
//    func color(darkMode: Bool) -> Color {
//        if darkMode {
//            switch colour {
//            case 1: return Color(.link)
//            case 2: return .cyan
//            case 3: return .mint
//            default: return .pink
//            }
//        } else {
//            switch colour {
//            case 1: return Color(.link)
//            case 2: return .purple
//            case 3: return .indigo
//            default: return .pink
//            }
//        }
//    }
}

extension Trail: MKOverlay {
    var coordinate: CLLocationCoordinate2D { multiPolyline.coordinate }
    var boundingMapRect: MKMapRect { multiPolyline.boundingMapRect }
}

struct TrailLines {
    let id: Int
    let multiPolyline: MKMultiPolyline
}

struct TrailProperties: Codable {
    let id: Int
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
    let cycle: Bool
    let ascent: Double?
    let country: Country
}

@objc(TrailTrips)
class TrailTrips: NSManagedObject {
    @NSManaged var id: Int16
    @NSManaged var lines: [[[Double]]]
    
    var linesCoords = [[CLLocationCoordinate2D]]()
    var coords = [CLLocationCoordinate2D]()
    var multiPolyline = MKMultiPolyline()
    var metres = 0.0
    
    func reload() {
        linesCoords = lines.map { $0.map { CLLocationCoordinate2DMake($0[0], $0[1]) } }
        coords = linesCoords.concat()
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

enum TrailSort: String, CaseIterable {
    case name = "Name"
    case distance = "Length"
    case ascent = "Total Ascent"
    case completed = "Percentage Completed"
    
    var image: String {
        switch self {
        case .name:
            return "character"
        case .distance:
            return "ruler"
        case .ascent:
            return "arrow.up"
        case .completed:
            return "percent"
        }
    }
}
