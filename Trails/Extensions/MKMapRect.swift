//
//  MKMapRect.swift
//  Trails
//
//  Created by Jack Finnis on 27/05/2023.
//

import MapKit

extension MKMapRect {
    var padded: MKMapRect {
        insetBy(dx: -10000, dy: -10000)
    }
}
