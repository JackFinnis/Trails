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
    var selectedTrips: [Trip] { trips.filter { $0.trailID == selectedTrail?.id ?? -1 } }
    @Published var completedMetres = 0.0
    @Published var selectedTrail: Trail? { didSet {
        if let selectedTrail {
            mapView?.removeOverlays(trails)
            mapView?.addOverlay(selectedTrail, level: .aboveRoads)
            mapView?.addOverlays(selectedTrips, level: .aboveRoads)
            calculateCompletedMetres()
        } else {
            mapView?.removeOverlays(trips)
            mapView?.addOverlays(trails, level: .aboveRoads)
        }
        updateLayoutMargins()
    }}
    
    // Search Bar
    var searchBar: UISearchBar?
    var search: MKLocalSearch?
    @Published var searchResults = [Annotation]()
    @Published var isSearching = false { didSet {
        updateLayoutMargins()
    }}
    
    // Select line
    @Published var selectPolyline: MKPolyline?
    @Published var selectMetres = 0.0
    @Published var selectError = false
    @Published var canUncomplete = false
    @Published var selectPins = [Annotation]()
    @Published var isSelecting = false { didSet {
        updateLayoutMargins()
    }}
    
    // Animations
    @Published var shake = false
    @Published var degrees = 0.0
    @Published var scale = 1.0
    
    // Defaults
    @Published var showCompletedAlert = false
    @Defaults("completedTrails") var completedTrails = [Int16]() { didSet {
        objectWillChange.send()
    }}
    @Defaults("expand") var expand = false { didSet {
        updateLayoutMargins()
        objectWillChange.send()
    }}
    @Defaults("metric") var metric = true { didSet {
        objectWillChange.send()
    }}
    
    // Map View
    var mapView: MKMapView?
    @Published var trackingMode = MKUserTrackingMode.none
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
//        completedTrails = []
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
//            self.deleteAll(entityName: "Trip")
            self.loadTrips()
        }
    }
    
    func loadTrips() {
        self.trips = (try? self.container.viewContext.fetch(Trip.fetchRequest()) as? [Trip]) ?? []
    }
    
    func deleteAll(entityName: String) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        _ = try? container.viewContext.execute(deleteRequest)
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
        refreshOverlays()
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
    
    func formatDistance(_ metres: Double, showUnit: Bool, round: Bool) -> String {
        let value = metres / (metric ? 1000 : 1609.34)
        return String(format: "%.\(round ? 0 : 1)f", value) + (showUnit ? (metric ? " km" : " miles") : "")
    }
    
    func calculateCompletedMetres() {
        let trips = selectedTrips
        var coords = [(CLLocationCoordinate2D, UUID)]()
        for trip in trips {
            for coord in trip.lineCoords {
                if !coords.contains(where: { $0.0 == coord }) {
                    coords.append((coord, trip.id))
                }
            }
        }
        var metres = 0.0
        let dict = Dictionary(grouping: coords) { $0.1 }
        dict.forEach { _, coords in
            metres += coords.map(\.0).getDistance()
        }
        completedMetres = metres
    }
    
    func refreshOverlays() {
        let overlays = mapView?.overlays(in: .aboveRoads) ?? []
        mapView?.removeOverlays(overlays)
        mapView?.addOverlays(overlays, level: .aboveRoads)
    }
    
    func updateLayoutMargins() {
        UIView.animate(withDuration: 0.35) {
            var top = CGFloat.zero
            if let selectedTrail = self.selectedTrail {
                top = self.expand ? 270 : 80
                if selectedTrail.name.count > 30 {
                    top += 30
                }
            }
            let bottom: CGFloat = (self.isSearching ? 70 : (self.isSelecting ? 75 : 60))
            let padding = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
            self.mapView?.layoutMargins = padding
        }
    }
    
    func setRect(_ rect: MKMapRect, extraPadding: Bool = false) {
        let padding: CGFloat = extraPadding ? 40 : 20
        let insets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        mapView?.setVisibleMapRect(rect, edgePadding: insets, animated: true)
    }
    
    func zoomTo(_ overlay: MKOverlay?, extraPadding: Bool = false) {
        if let overlay {
            setRect(overlay.boundingMapRect, extraPadding: extraPadding)
        }
    }
    
    func reverseGeocode(coord: CLLocationCoordinate2D, completion: @escaping (CLPlacemark) -> Void) {
        CLGeocoder().reverseGeocodeLocation(coord.location) { placemarks, error in
            guard let placemark = placemarks?.first else { return }
            completion(placemark)
        }
    }
    
    func selectClosestTrail(to coord: CLLocationCoordinate2D) {
        (_, _, selectedTrail) = getClosestTrail(to: coord, trails: trails, maxDelta: tapDelta)
        zoomTo(selectedTrail)
    }
    
    func getClosestTrail(to targetCoord: CLLocationCoordinate2D, trails: [Trail], maxDelta: Double) -> (CLLocationCoordinate2D?, [CLLocation]?, Trail?) {
        let targetLocation = targetCoord.location
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
        if selectPins.count < 2 {
            reverseGeocode(coord: coord) { placemark in
                let annotation = Annotation(type: .select, placemark: placemark, coord: coord)
                self.selectPins.append(annotation)
                self.mapView?.addAnnotation(annotation)
                self.mapView?.deselectAnnotation(annotation, animated: false)
                
                if self.selectPins.count == 2 {
                    let coords = self.calculateLine(between: self.selectPins[0].coordinate, and: self.selectPins[1].coordinate)
                    
                    self.selectError = coords.count < 2
                    guard !self.selectError else { self.shakeError(); return }
                    
                    guard let start = coords.first, let end = coords.last else { return }
                    let tripCoords = self.selectedTrips.flatMap(\.lineCoords)
                    self.canUncomplete = tripCoords.contains(start) || tripCoords.contains(end)
                    
                    self.selectPolyline = MKPolyline(coordinates: coords, count: coords.count)
                    self.mapView?.addOverlay(self.selectPolyline!, level: .aboveRoads)
                    self.selectMetres = coords.getDistance()
                    self.zoomTo(self.selectPolyline, extraPadding: true)
                    Haptics.tap()
                }
            }
        }
    }
    
    func startSelecting() {
        stopSelecting()
        isSelecting = true
    }
    
    func deselectTrail() {
        selectedTrail = nil
        stopSelecting()
    }
    
    func stopSelecting() {
        isSelecting = false
        selectError = false
        mapView?.removeAnnotations(selectPins)
        selectPins = []
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
        let (startCoord, line, _) = getClosestTrail(to: coord1, trails: [selectedTrail], maxDelta: .greatestFiniteMagnitude)
        guard let startCoord, let line, let endCoord = getClosestCoord(to: coord2, along: line) else { return [] }
        
        let coords = line.map(\.coordinate)
        guard let startIndex = coords.firstIndex(of: startCoord),
              let endIndex = coords.firstIndex(of: endCoord)
        else { return [] }
        
        return Array(coords[min(startIndex, endIndex)...max(startIndex, endIndex)])
    }
    
    func completeSelectPolyline() {
        guard let selectedTrail, let selectPolyline else { return }
        let trip = Trip(context: container.viewContext)
        trip.id = UUID()
        trip.trailID = selectedTrail.id
        trip.line = selectPolyline.coordinates.map { [$0.latitude, $0.longitude] }
        save()
        trips.append(trip)
        mapView?.addOverlay(trip, level: .aboveRoads)
        stopSelecting()
        calculateCompletedMetres()
        
        if Int(completedMetres/1000) == Int(selectedTrail.metres/1000) && !completedTrails.contains(selectedTrail.id) {
            Haptics.success()
            completedTrails.append(selectedTrail.id)
            showCompletedAlert = true
        } else {
            Haptics.tap()
        }
    }
    
    func uncompleteSelectPolyline() {
//        let line = selectPolyline?.coordinates ?? []
//        for trip in selectedTrips {
//            trip.line.removeAll { line.contains(CLLocationCoordinate2DMake($0[0], $0[1])) }
//        }
//        save()
//        loadTrips()
//        refreshOverlays()
//        calculateCompletedMetres()
        stopSelecting()
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
    func handlePress(_ press: UILongPressGestureRecognizer) {
        guard !(isSelecting && selectPins.count < 2), press.state == .began, let coord = getCoord(from: press) else { return }
        reverseGeocode(coord: coord) { placemark in
            Haptics.tap()
            let annotation = Annotation(type: .drop, placemark: placemark, coord: coord)
            self.mapView?.addAnnotation(annotation)
            self.mapView?.selectAnnotation(annotation, animated: true)
        }
    }
    
    @objc
    func handleTap(_ tap: UITapGestureRecognizer) {
        guard let coord = getCoord(from: tap) else { return }
        
        if isSelecting {
            newSelectCoord(coord)
        } else if selectedTrail == nil {
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
    var darkMode: Bool {
        UITraitCollection.current.userInterfaceStyle == .dark || mapView?.mapType == .hybrid
    }
    
    func getColor(of trail: Trail) -> Color {
        if darkMode {
            switch trail.colour {
            case 1: return Color(.link)
            case 2: return .cyan
            case 3: return .mint
            default: return .pink
            }
        } else {
            switch trail.colour {
            case 1: return Color(.link)
            case 2: return .purple
            case 3: return .indigo
            default: return .pink
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let trail = overlay as? Trail {
            let renderer = MKMultiPolylineRenderer(multiPolyline: trail.multiPolyline)
            renderer.lineWidth = 2
            renderer.strokeColor = UIColor(getColor(of: trail))
            return renderer
        } else if let trip = overlay as? Trip {
            let renderer = MKPolylineRenderer(polyline: trip.polyline)
            renderer.lineWidth = 2.1
            renderer.strokeColor = darkMode ? .white : .black
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
        let openButton = getButton(systemName: "arrow.triangle.turn.up.right.circle")
        let removeButton = getButton(systemName: "xmark")
        let shareButton = getButton(systemName: "square.and.arrow.up")
        if let annotation = annotation as? Annotation {
            switch annotation.type {
            case .select:
                let pin = mapView.dequeueReusableAnnotationView(withIdentifier: MKPinAnnotationView.id, for: annotation) as? MKPinAnnotationView
                pin?.displayPriority = .required
                pin?.animatesDrop = true
                pin?.rightCalloutAccessoryView = openButton
                pin?.leftCalloutAccessoryView = removeButton
                pin?.canShowCallout = true
                return pin
            case .search, .drop:
                let marker = mapView.dequeueReusableAnnotationView(withIdentifier: MKMarkerAnnotationView.id, for: annotation) as? MKMarkerAnnotationView
                marker?.displayPriority = .required
                marker?.animatesWhenAdded = true
                marker?.rightCalloutAccessoryView = openButton
                if annotation.type == .drop {
                    marker?.leftCalloutAccessoryView = removeButton
                }
                marker?.canShowCallout = true
                return marker
            }
        } else if let user = annotation as? MKUserLocation {
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: MKUserLocationView.id, for: user) as? MKUserLocationView
            view?.rightCalloutAccessoryView = openButton
            view?.leftCalloutAccessoryView = shareButton
            return view
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        if !animated {
            updateTrackingMode(.none)
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else { return }
        if annotation is MKUserLocation {
            mapView.deselectAnnotation(annotation, animated: false)
        } else if isSelecting && selectPins.count < 2 {
            mapView.deselectAnnotation(annotation, animated: false)
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let annotation = view.annotation as? Annotation else { return }
        if control == view.leftCalloutAccessoryView {
            if annotation.type == .drop {
                mapView.deselectAnnotation(annotation, animated: true)
                mapView.removeAnnotation(annotation)
            } else {
                selectPins.removeAll { $0 == annotation }
                mapView.removeAnnotation(annotation)
                removeSelectPolyline()
            }
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
                self.shakeError()
            }
        }
    }
    
    func shakeError() {
        Haptics.error()
        self.shake = true
        withAnimation(.spring(response: 0.2, dampingFraction: 0.2, blendDuration: 0.2)) {
            self.shake = false
        }
    }
    
    func stopSearching() {
        isSearching = false
        resetSearching()
    }
    
    func resetSearching() {
        mapView?.removeAnnotations(searchResults)
        searchResults = []
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
                self.searchResults = filteredResults.map { item in
                    Annotation(type: .search, placemark: item.placemark, coord: item.placemark.coordinate)
                }
                self.mapView?.addAnnotations(self.searchResults)
                self.setRect(response.boundingRegion.rect, extraPadding: true)
                completion(true)
            }
        }
    }
}
