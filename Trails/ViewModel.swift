//
//  ViewModel.swift
//  Trails
//
//  Created by Jack Finnis on 16/02/2023.
//

import Foundation
import MapKit

@MainActor
class ViewModel: NSObject, ObservableObject {
    var trails = [Trail]()
    var mapView: MKMapView?
    
    func loadTrails() {
        let url = Bundle.main.url(forResource: "Trails", withExtension: "json")!
        do {
            let data = try Data(contentsOf: url)
            trails = try JSONDecoder().decode([TrailCodable].self, from: data).map(Trail.init)
            mapView?.addOverlays(trails, level: .aboveRoads)
        } catch {
            debugPrint(error)
        }
    }
}

extension ViewModel: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let trail = overlay as? Trail {
            let renderer = MKMultiPolylineRenderer(multiPolyline: trail.multiPolyline)
            renderer.lineWidth = 2
            renderer.strokeColor = UIColor(.accentColor)
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}
