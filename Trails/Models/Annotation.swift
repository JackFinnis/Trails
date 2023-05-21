//
//  Annotation.swift
//  Paddle
//
//  Created by Jack Finnis on 16/09/2022.
//

import Foundation
import MapKit

class Annotation: NSObject {
    let type: AnnotationType
    let coord: CLLocationCoordinate2D
    let placemark: CLPlacemark
    
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

extension Annotation: MKAnnotation {
    var title: String? { placemark.name }
    var subtitle: String?  { placemark.subLocality }
    var coordinate: CLLocationCoordinate2D { coord }
}

enum AnnotationType {
    case select
    case search
    case drop
}
