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
    let id: Int
    let name: String
    let headline: String
    let url: URL
    let photoUrl: URL
    let km: Int
    let miles: Int
    let metres: Int
    let days: Int
    let lines: [[[Double]]]
    let colour: Int
    
    var color: Color {
        switch colour {
        case 1: return Color(.link)
        case 2: return .purple
        case 3: return .indigo
        default: return .pink
        }
    }
    
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
        km = metadata.km
        miles = metadata.miles
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
    let id: Int
    let name: String
    let description: String
    let url: URL
    let photoUrl: URL
    let km: Int
    let miles: Int
    let metres: Int
    let days: Int
    let colour: Int
}
