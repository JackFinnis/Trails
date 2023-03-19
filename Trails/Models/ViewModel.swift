//
//  ViewModel.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import Foundation
import MapKit
import CoreData
import SwiftUI
import StoreKit

@MainActor
class ViewModel: NSObject, ObservableObject {
    static let shared = ViewModel()
    
    // MARK: - Properties
    var trails = [Trail]()
    var trips = [Trip]()
    @Published var annotations = [Annotation]()
    @Published var selectedTrail: Trail? { didSet {
        if let selectedTrail {
            mapView?.removeOverlays(trails)
            mapView?.addOverlay(selectedTrail, level: .aboveRoads)
        } else {
            mapView?.addOverlays(trails, level: .aboveRoads)
        }
    }}
    @Published var selectedAnnotation: Annotation?
    
    // Search Bar
    var searchBar: UISearchBar?
    var search: MKLocalSearch?
    @Published var noResults = false
    @Published var isSearching = false
    
    // Select line
    @Published var selectPolyline: MKPolyline?
    @Published var selectMetres = 0.0
    @Published var isSelecting = false
    
    // Animations
    @Published var degrees = 0.0
    @Published var scale = 1.0
    
    // Map View
    var mapView: MKMapView?
    @Published var trackingMode = MKUserTrackingMode.follow
    @Published var mapType = MKMapType.standard
    
    // CLLocationManager
    let manager = CLLocationManager()
    var authStatus = CLAuthorizationStatus.notDetermined
    @Published var showAuthError = false
    
    // Persistence
    let container = NSPersistentContainer(name: "Trails")
    func save() {
        try? container.viewContext.save()
    }
    
    override init() {
        super.init()
        manager.delegate = self
        loadData()
    }
    
    func loadJSON<T: Decodable>(from file: String) -> T {
        let url = Bundle.main.url(forResource: file, withExtension: "json")!
        let data = try! Data(contentsOf: url)
        return try! JSONDecoder().decode(T.self, from: data)
    }
    
    func loadData() {
        let trailsLines: [TrailLines] = loadJSON(from: "Coords")
        let trailsMetadata: [TrailMetadata] = loadJSON(from: "Metadata")
        for id in 0...14 {
            let lines = trailsLines.first { $0.id == id }!
            let metadata = trailsMetadata.first { $0.id == id }!
            trails.append(Trail(lines: lines, metadata: metadata))
        }
        trails.sort { $0.name < $1.name }
        
        container.loadPersistentStores { description, error in
            self.trips = (try? self.container.viewContext.fetch(Trip.fetchRequest()) as? [Trip]) ?? []
        }
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Map
extension ViewModel {
    var tapDelta: Double {
        guard let rect = mapView?.visibleMapRect else { return 0 }
        let left = MKMapPoint(x: rect.minX, y: rect.midY)
        let right = MKMapPoint(x: rect.maxX, y: rect.midY)
        return left.distance(to: right) / 20
    }
    
    func updateTrackingMode(_ newMode: MKUserTrackingMode) {
        mapView?.setUserTrackingMode(newMode, animated: true)
        if trackingMode == .followWithHeading || newMode == .followWithHeading {
            withAnimation(.easeInOut(duration: 0.25)) {
                scale = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.trackingMode = newMode
                withAnimation(.easeInOut(duration: 0.25)) {
                    self.scale = 1
                }
            }
        } else {
            trackingMode = newMode
        }
    }
    
    func updateMapType(_ newType: MKMapType) {
        mapView?.mapType = newType
        withAnimation(.easeInOut(duration: 0.25)) {
            degrees += 90
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.mapType = newType
            withAnimation(.easeInOut(duration: 0.25)) {
                self.degrees += 90
            }
        }
    }
    
    func setRect(_ rect: MKMapRect) {
        let padding = UIEdgeInsets(top: 80, left: 20, bottom: 80, right: 20)
        mapView?.setVisibleMapRect(rect, edgePadding: padding, animated: true)
    }
    
    func zoomTo(_ overlay: MKOverlay?) {
        if let overlay {
            setRect(overlay.boundingMapRect)
        }
    }
    
    func reverseGeocode(coord: CLLocationCoordinate2D, completion: @escaping (CLPlacemark?) -> Void) {
        CLGeocoder().reverseGeocodeLocation(coord.location) { placemarks, error in
            completion(placemarks?.first)
        }
    }
    
    func selectClosestTrail(to coord: CLLocationCoordinate2D) {
        (_, _, selectedTrail) = getClosestTrail(to: coord, trails: trails)
        zoomTo(selectedTrail)
    }
    
    func getClosestTrail(to targetCoord: CLLocationCoordinate2D, trails: [Trail]) -> (CLLocationCoordinate2D?, [CLLocation]?, Trail?) {
        let targetLocation = targetCoord.location
        let maxDelta = tapDelta
        var shortestDistance = Double.infinity
        var closestCoord: CLLocationCoordinate2D?
        var closestLine: [CLLocation]?
        var closestTrail: Trail?
        
        for trail in trails {
            for line in trail.linesLocations {
                for location in line {
                    let delta = location.distance(from: targetLocation)
                    
                    if delta < shortestDistance && delta < maxDelta {
                        shortestDistance = delta
                        closestTrail = trail
                        closestCoord = location.coordinate
                        closestLine = line
                    }
                }
            }
        }
        return (closestCoord, closestLine, closestTrail)
    }
}

// MARK: - Select
extension ViewModel {
    func newSelectCoord(_ coord: CLLocationCoordinate2D) {
        if annotations.count < 2 {
            reverseGeocode(coord: coord) { placemark in
                guard let placemark else { return }
                let annotation = Annotation(type: .select, placemark: placemark, coord: coord)
                self.annotations.append(annotation)
                self.mapView?.addAnnotation(annotation)
                
                if self.annotations.count == 2 {
                    let coords = self.calculateLine(between: self.annotations[0].coordinate, and: self.annotations[1].coordinate)
                    self.selectPolyline = MKPolyline(coordinates: coords, count: coords.count)
                    self.mapView?.addOverlay(self.selectPolyline!)
                    self.selectMetres = coords.getDistance()
                    self.zoomTo(self.selectPolyline)
                }
            }
        }
    }
    
    func stopSelecting() {
        isSelecting = false
        mapView?.removeAnnotations(annotations)
        annotations = []
        removeSelectPolyline()
    }
    
    func removeSelectPolyline() {
        if let selectPolyline {
            mapView?.removeOverlay(selectPolyline)
            self.selectPolyline = nil
        }
    }
    
    func getClosestCoord(to targetCoord: CLLocationCoordinate2D, along line: [CLLocation]) -> CLLocationCoordinate2D? {
        let targetLocation = targetCoord.location
        var shortestDistance = Double.infinity
        var closestCoord: CLLocationCoordinate2D?
        
        for location in line {
            let delta = location.distance(from: targetLocation)
            
            if delta < shortestDistance {
                shortestDistance = delta
                closestCoord = location.coordinate
            }
        }
        return closestCoord
    }
    
    func calculateLine(between coord1: CLLocationCoordinate2D, and coord2: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
        guard let selectedTrail else { return [] }
        let (startCoord, line, _) = getClosestTrail(to: coord1, trails: [selectedTrail])
        guard let startCoord, let line, let endCoord = getClosestCoord(to: coord2, along: line) else { return [] }
        
        let coords = line.map(\.coordinate)
        guard let startIndex = coords.firstIndex(of: startCoord),
              let endIndex = coords.firstIndex(of: endCoord)
        else { return [] }
        
        return Array(coords[min(startIndex, endIndex)...max(startIndex, endIndex)])
    }
    
    func completeSelectPolyline() {
        let trip = Trip(context: container.viewContext)
        trip.id = selectedTrail?.id ?? 0
        trip.line = (selectPolyline?.coordinates ?? []).map { [$0.latitude, $0.longitude] }
        save()
        trips.append(trip)
        mapView?.addOverlay(trip)
        stopSelecting()
        Haptics.success()
    }
}

// MARK: - Gesture Recogniser
extension ViewModel {
    func getCoord(from gesture: UIGestureRecognizer) -> CLLocationCoordinate2D? {
        guard let mapView = mapView else { return nil }
        let point = gesture.location(in: mapView)
        return mapView.convert(point, toCoordinateFrom: mapView)
    }
    
    @objc
    func handlePress(_ press: UIGestureRecognizer) {
        guard selectedAnnotation == nil, let coord = getCoord(from: press) else { return }
        reverseGeocode(coord: coord) { placemark in
            guard let placemark else { return }
            Haptics.tap()
            let annotation = Annotation(type: .drop, placemark: placemark, coord: coord)
            self.mapView?.addAnnotation(annotation)
            self.mapView?.selectAnnotation(annotation, animated: true)
        }
    }
    
    @objc
    func handleTap(_ tap: UIGestureRecognizer) {
        guard let coord = getCoord(from: tap) else { return }
        
        if isSelecting {
            newSelectCoord(coord)
        } else if selectedAnnotation == nil {
            selectClosestTrail(to: coord)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension ViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authStatus = manager.authorizationStatus
        if authStatus == .denied {
            showAuthError = true
        } else if authStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }
    
    func validateAuth() -> Bool {
        showAuthError = authStatus == .denied
        return !showAuthError
    }
}

// MARK: - MKMapViewDelegate
extension ViewModel: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let trail = overlay as? Trail {
            let renderer = MKMultiPolylineRenderer(multiPolyline: trail.multiPolyline)
            renderer.lineWidth = 2
            renderer.strokeColor = UIColor(trail.color)
            return renderer
        } else if let trip = overlay as? Trip {
            let renderer = MKPolylineRenderer(polyline: trip.polyline)
            renderer.lineWidth = 2
            renderer.strokeColor = UIColor(.accentColor)
            return renderer
        } else if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.lineWidth = 3
            renderer.strokeColor = UIColor(.orange)
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func getButton(systemName: String) -> UIButton {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(font: .systemFont(ofSize: SIZE/2))
        let image = UIImage(systemName: systemName, withConfiguration: config)
        button.setImage(image, for: .normal)
        button.frame.size = CGSize(width: SIZE, height: SIZE)
        return button
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? Annotation {
            let openButton = getButton(systemName: "arrow.triangle.turn.up.right.circle")
            switch annotation.type {
            case .select:
                let pin = mapView.dequeueReusableAnnotationView(withIdentifier: MKPinAnnotationView.id, for: annotation) as? MKPinAnnotationView
                pin?.displayPriority = .required
                pin?.animatesDrop = true
                pin?.rightCalloutAccessoryView = openButton
                pin?.leftCalloutAccessoryView = getButton(systemName: "xmark")
                pin?.canShowCallout = true
                return pin
            case .search, .drop:
                let marker = mapView.dequeueReusableAnnotationView(withIdentifier: MKMarkerAnnotationView.id, for: annotation) as? MKMarkerAnnotationView
                marker?.displayPriority = .required
                marker?.animatesWhenAdded = true
                marker?.rightCalloutAccessoryView = openButton
                marker?.canShowCallout = true
                return marker
            }
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
        selectedAnnotation = annotation as? Annotation
    }
    
    func mapView(_ mapView: MKMapView, didDeselect annotation: MKAnnotation) {
        guard let selectedAnnotation else { return }
        if selectedAnnotation.type == .drop {
            mapView.removeAnnotation(selectedAnnotation)
        }
        self.selectedAnnotation = nil
    }
    
    func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        if !animated {
            trackingMode = .none
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let annotation = view.annotation as? Annotation else { return }
        if control == view.leftCalloutAccessoryView {
            annotations.removeAll { $0 == annotation }
            mapView.removeAnnotation(annotation)
            removeSelectPolyline()
        } else {
            annotation.openInMaps()
        }
    }
}

// MARK: - UISearchBarDelegate
extension ViewModel: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, text.isNotEmpty else { return }
        search(text: text) { success in
            if success {
                searchBar.resignFirstResponder()
            } else {
                Haptics.error()
                self.noResults = true
                withAnimation(.spring(response: 0.2, dampingFraction: 0.2, blendDuration: 0.2)) {
                    self.noResults = false
                }
            }
        }
    }
    
    func stopSearching() {
        isSearching = false
        resetSearching()
    }
    
    func resetSearching() {
        mapView?.removeAnnotations(annotations)
        annotations = []
    }
    
    func search(text: String, completion: @escaping (Bool) -> Void) {
        resetSearching()
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = text
        guard let mapView else { return }
        request.region = mapView.region
        
        search?.cancel()
        search = MKLocalSearch(request: request)
        search?.start { response, error in
            guard let response else { completion(false); return }
            let filteredResults = response.mapItems.filter { $0.placemark.countryCode == "GB" }
            guard filteredResults.isNotEmpty else { completion(false); return }
            
            DispatchQueue.main.async {
                self.annotations = filteredResults.map { item in
                    Annotation(type: .search, placemark: item.placemark, coord: item.placemark.coordinate)
                }
                self.mapView?.addAnnotations(self.annotations)
                self.mapView?.setRegion(response.boundingRegion, animated: true)
                completion(true)
            }
        }
    }
}
