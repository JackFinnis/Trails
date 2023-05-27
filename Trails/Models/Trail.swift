//
//  Trail.swift
//  Trails
//
//  Created by Jack Finnis on 16/02/2023.
//

import Foundation
import MapKit
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
    let cycleStatus: TrailCycleStatus
    let ascent: Double
    let descent: Double
    let country: TrailCountry
    
    var cycleway: Bool { cycleStatus != .no }
    
    let coords: [CLLocationCoordinate2D]
    let locations: [CLLocation]
    let polyline: MKPolyline
    var elevationProfile: ElevationProfile?
    
    init(metadata: TrailMetadata, polyline: MKPolyline) {
        self.polyline = polyline
        coords = polyline.coordinates.map(\.rounded)
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
        descent = metadata.descent
        country = metadata.country
    }
    
    static let example = Trail(metadata: .init(id: 0, name: "Cleveland Way", description: "Experience the varied landscape of the North York Moors National Park on a journey across breathtaking heather moorland and dramatic coastline.", url: URL(string: "https://www.nationaltrail.co.uk/trails/cleveland-way/")!, photoUrl: URL(string: "https://nationaltrails.s3.eu-west-2.amazonaws.com/uploads/Cleveland-Way-Home-2000x600.jpg")!, metres: 170813, days: 9, colour: 1, cycleStatus: .sections, ascent: 5031, descent: 4032, country: .england), polyline: MKPolyline())
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
    let cycleStatus: TrailCycleStatus
    let ascent: Double
    let descent: Double
    let country: TrailCountry
}

enum TrailCountry: String, Codable, CaseIterable {
    case england = "England"
    case scotland = "Scotland"
    case wales = "Wales"
    case ni = "Northern Ireland"
}

enum TrailCycleStatus: String, Codable {
    case no
    case yes
    case sections
    
    var name: String {
        switch self {
        case .no:
            return "None"
        case .yes:
            return "All"
        case .sections:
            return "Parts"
        }
    }
}
