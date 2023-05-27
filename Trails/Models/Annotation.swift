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
    var name: String { placemark.subLocality ?? placemark.locality ?? placemark.name ?? "" }
    
    init(type: AnnotationType, mapItem: MKMapItem) {
        self.type = type
        self.mapItem = mapItem
    }
    
    convenience init(type: AnnotationType, placemark: CLPlacemark) {
        self.init(type: type, mapItem: MKMapItem(placemark: MKPlacemark(placemark: placemark)))
    }
}

extension Annotation: MKAnnotation {
    var titles: [String] { [placemark.thoroughfare, placemark.subLocality, placemark.locality, placemark.name].compactMap { $0 } }
    var title: String? { titles.first }
    var subtitle: String? { titles.dropFirst().first }
    var coordinate: CLLocationCoordinate2D { mapItem.placemark.coordinate }
}
