//
//  MapView.swift
//  Trails
//
//  Created by Jack Finnis on 16/02/2023.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @EnvironmentObject var vm: ViewModel

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        
        mapView.delegate = vm
        vm.mapView = mapView
        
        mapView.showsUserLocation = true
        mapView.showsScale = true
        mapView.showsCompass = true
        mapView.isPitchEnabled = false
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {}
}
