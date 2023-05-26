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
    case drop
}

class Annotation: NSObject {
    let type: AnnotationType
    let mapItem: MKMapItem
    
    var placemark: CLPlacemark { mapItem.placemark }
    var name: String { placemark.thoroughfare ?? placemark.subLocality ?? placemark.name ?? "" }
    
    init(type: AnnotationType, mapItem: MKMapItem) {
        self.type = type
        self.mapItem = mapItem
        super.init()
        mapItem.name = name
    }
    
    convenience init(type: AnnotationType, placemark: CLPlacemark) {
        self.init(type: type, mapItem: MKMapItem(placemark: MKPlacemark(placemark: placemark)))
    }
}

extension Annotation: MKAnnotation {
    var title: String? { name }
    var subtitle: String? { placemark.thoroughfare == nil ? placemark.locality : placemark.subLocality }
    var coordinate: CLLocationCoordinate2D { mapItem.placemark.coordinate }
}
