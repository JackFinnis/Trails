//
//  MKCoordinateRegion.swift
//  Trails
//
//  Created by Jack Finnis on 19/03/2023.
//

import Foundation
import MapKit

extension MKCoordinateRegion {
    var rect: MKMapRect {
        let latDelta = span.latitudeDelta / 2
        let longDelta = span.longitudeDelta / 2
        let topLeft = CLLocationCoordinate2DMake(center.latitude + latDelta, center.longitude - longDelta)
        let bottomRight = CLLocationCoordinate2DMake(center.latitude - latDelta, center.longitude + longDelta)
        return MKMapRect(origin: MKMapPoint(topLeft), size: .init()).union(MKMapRect(origin: MKMapPoint(bottomRight), size: .init()))
    }
}

extension CLRegion {
    var rect: MKMapRect? {
        guard let region = self as? CLCircularRegion else { return nil }
        return MKCoordinateRegion(center: region.center, latitudinalMeters: region.radius, longitudinalMeters: region.radius).rect
    }
}
