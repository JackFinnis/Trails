//
//  MapView.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @EnvironmentObject var vm: ViewModel
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = vm
        vm.mapView = mapView
        mapView.addOverlays(vm.trails, level: .aboveRoads)
        vm.updateLayoutMargins()
        vm.zoomTo(MKMultiPolyline(vm.trails.flatMap(\.multiPolyline.polylines)))
        
        mapView.showsUserLocation = true
        mapView.showsScale = true
        mapView.showsCompass = true
        mapView.isPitchEnabled = false
        
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
