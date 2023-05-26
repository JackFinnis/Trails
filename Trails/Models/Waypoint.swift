//
//  Waypoint.swift
//  Trails
//
//  Created by Jack Finnis on 25/05/2023.
//

import Foundation
import MapKit

class Waypoint: NSObject {
    let coordinate: CLLocationCoordinate2D
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}

extension Waypoint: MKAnnotation {
    var title: String? { "Waypoint" }
}

class WaypointView: MKAnnotationView {
    weak var vm: ViewModel?
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    }
    
    override func prepareForDisplay() {
        super.prepareForDisplay()
        
        let size = 10.0
        frame = CGRect(origin: .zero, size: CGSize(width: size * 2, height: size * 2))
        let config = UIImage.SymbolConfiguration(font: .systemFont(ofSize: size))
        let image = UIImage(systemName: "circle.fill", withConfiguration: config)
        let imageView = UIImageView(image: image)
        imageView.tintColor = vm?.trailOverlayColor ?? .link
        imageView.center = center
        
        addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}
