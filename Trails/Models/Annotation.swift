//
//  Annotation.swift
//  Paddle
//
//  Created by Jack Finnis on 16/09/2022.
//

import Foundation
import MapKit

class Annotation: NSObject, MKAnnotation {
    let type: AnnotationType
    let coord: CLLocationCoordinate2D
    let placemark: CLPlacemark
    
    var title: String? { placemark.name }
    var subtitle: String?  { placemark.locality }
    var coordinate: CLLocationCoordinate2D { coord }
    
    init(type: AnnotationType, placemark: CLPlacemark, coord: CLLocationCoordinate2D) {
        self.type = type
        self.coord = coord
        self.placemark = placemark
    }
    
    func openInMaps() {
        let item = MKMapItem(placemark: MKPlacemark(placemark: placemark))
        item.name = placemark.name
        item.openInMaps()
    }
}

enum AnnotationType {
    case select
    case search
    case drop
}
