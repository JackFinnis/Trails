//
//  Waypoint.swift
//  Trails
//
//  Created by Jack Finnis on 25/05/2023.
//

import SwiftUI
import MapKit

enum WaypointType: String {
    case start = "Start"
    case end = "End"
    case middle = "Waypoint"
}

class Waypoint: NSObject {
    let type: WaypointType
    let name: String?
    let coordinate: CLLocationCoordinate2D
    
    init(type: WaypointType, name: String? = nil, coordinate: CLLocationCoordinate2D) {
        self.type = type
        self.name = name
        self.coordinate = coordinate
    }
}

extension Waypoint: MKAnnotation {
    var title: String? { type.rawValue }
    var subtitle: String? { name }
}

class WaypointView: MKAnnotationView {
    weak var vm: ViewModel?
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    }
    
    override func prepareForDisplay() {
        super.prepareForDisplay()
        guard let annotation else { return }
        
        let size = 10.0
        canShowCallout = true
        zPriority = .min
        rightCalloutAccessoryView = vm?.getShareMenu(mapItem: nil, coord: annotation.coordinate, allowsDirections: true)
        frame = CGRect(origin: .zero, size: CGSize(width: size * 2, height: size * 2))
        
        let font = UIImage.SymbolConfiguration(font: .systemFont(ofSize: size))
        let image = UIImage(systemName: "circle.fill", withConfiguration: font)
        let imageView = UIImageView(image: image)
        imageView.tintColor = vm?.trailOverlayColor ?? .link
        imageView.center = center
        addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}
