//
//  MapView.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI
import MapKit

class _MKMapView: MKMapView {
    var compass: UIView? {
        subviews.first(where: { type(of: $0).id == "MKCompassView" })
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let compass {
            compass.center = compass.center.applying(.init(translationX: -5, y: Constants.size*2 + 15))
            if compass.gestureRecognizers?.count == 1 {
                let tap = UITapGestureRecognizer(target: ViewModel.shared, action: #selector(ViewModel.tappedCompass))
                tap.delegate = ViewModel.shared
                compass.addGestureRecognizer(tap)
            }
        }
    }
}

struct MapView: UIViewRepresentable {
    @EnvironmentObject var vm: ViewModel
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = _MKMapView()
        mapView.delegate = vm
        vm.mapView = mapView
        vm.refreshOverlays()
        if let trail = vm.selectedTrail {
            vm.selectTrail(trail, animated: false)
        } else {
            vm.zoomToFilteredTrails(animated: false)
        }
        
        mapView.showsUserLocation = true
        mapView.showsScale = true
        mapView.showsCompass = true
        mapView.isPitchEnabled = false
        
        mapView.register(MKPinAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKPinAnnotationView.id)
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMarkerAnnotationView.id)
        mapView.register(WaypointView.self, forAnnotationViewWithReuseIdentifier: WaypointView.id)
        
        let tapRecognizer = UITapGestureRecognizer(target: vm, action: #selector(ViewModel.handleTap))
        let pressRecognizer = UILongPressGestureRecognizer(target: vm, action: #selector(ViewModel.handlePress))
        mapView.addGestureRecognizer(tapRecognizer)
        mapView.addGestureRecognizer(pressRecognizer)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {}
}
