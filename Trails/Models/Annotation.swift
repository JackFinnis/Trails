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
    
    init(type: AnnotationType, mapItem: MKMapItem) {
        self.type = type
        self.mapItem = mapItem
        super.init()
        mapItem.name = title ?? ""
    }
    
    convenience init(type: AnnotationType, placemark: CLPlacemark) {
        self.init(type: type, mapItem: MKMapItem(placemark: MKPlacemark(placemark: placemark)))
    }
}

extension Annotation: MKAnnotation {
    var placemark: CLPlacemark { mapItem.placemark }
    var title: String? { placemark.thoroughfare ?? placemark.name }
    var subtitle: String? { [placemark.subLocality, placemark.locality, placemark.subAdministrativeArea].compactMap { $0 }.joined(separator: ", ") }
    var coordinate: CLLocationCoordinate2D { mapItem.placemark.coordinate }
}

//    print("name", placemark.name)
//    print("thoroughfare", placemark.thoroughfare)
//    print("subThoroughfare", placemark.subThoroughfare)
//    print("locality", placemark.locality)
//    print("subLocality", placemark.subLocality)
//    print("administrativeArea", placemark.administrativeArea)
//    print("subAdministrativeArea", placemark.subAdministrativeArea)
//
//    name Optional("Northumberland National Park")
//    thoroughfare Optional("Old Church")
//    subThoroughfare nil
//    locality Optional("Morpeth")
//    subLocality Optional("Harbottle CP")
//    administrativeArea Optional("England")
//    subAdministrativeArea Optional("Northumberland")
