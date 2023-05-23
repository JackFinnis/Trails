//
//  Annotation.swift
//  Paddle
//
//  Created by Jack Finnis on 16/09/2022.
//

import Foundation
import MapKit

enum AnnotationType {
    case select
    case search
    case drop
}

class Annotation: NSObject {
    let type: AnnotationType
    let mapItem: MKMapItem
    
    init(type: AnnotationType, mapItem: MKMapItem) {
        self.type = type
        self.mapItem = mapItem
    }
    
    init(type: AnnotationType, placemark: CLPlacemark) {
        self.type = type
        self.mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
    }
}

extension Annotation: MKAnnotation {
    var title: String? { mapItem.placemark.name }
    var subtitle: String?  { mapItem.placemark.subLocality ?? mapItem.placemark.locality }
    var coordinate: CLLocationCoordinate2D { mapItem.placemark.coordinate }
}
