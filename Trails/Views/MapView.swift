//
//  MapView.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI
import MapKit

class _MKMapView: MKMapView {
    override func layoutSubviews() {
        super.layoutSubviews()
        if let compass = subviews.first(where: { type(of: $0).id == "MKCompassView" }) {
            compass.center = compass.center.applying(.init(translationX: -5, y: Constants.size*2 + 15))
            if (compass.gestureRecognizers?.count ?? 0) < 2 {
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
        vm.refreshTrailOverlays()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            vm.zoomToFilteredTrails(animated: false)
        }
        
        mapView.showsUserLocation = true
        mapView.showsScale = true
        mapView.showsCompass = true
        mapView.isPitchEnabled = false
        mapView.layoutMargins.bottom = 40
        
        mapView.register(MKPinAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKPinAnnotationView.id)
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMarkerAnnotationView.id)
        mapView.register(MKUserLocationView.self, forAnnotationViewWithReuseIdentifier: MKUserLocationView.id)
        
        let tapRecognizer = UITapGestureRecognizer(target: vm, action: #selector(ViewModel.handleTap))
        let pressRecognizer = UILongPressGestureRecognizer(target: vm, action: #selector(ViewModel.handlePress))
        mapView.addGestureRecognizer(tapRecognizer)
        mapView.addGestureRecognizer(pressRecognizer)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {}
}
