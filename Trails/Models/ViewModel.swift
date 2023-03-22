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
    var trailsTrips = [TrailTrips]()
    var selectedTrips: TrailTrips? { getSelectedTrips(trail: selectedTrail) }
    @Published var selectedTrail: Trail? { didSet {
        if let selectedTrail {
            mapView?.removeOverlays(trails)
            mapView?.addOverlay(selectedTrail, level: .aboveRoads)
            if let selectedTrips {
                mapView?.addOverlay(selectedTrips, level: .aboveRoads)
            }
        } else {
            mapView?.removeOverlays(trailsTrips)
            mapView?.addOverlays(trails, level: .aboveRoads)
        }
        updateLayoutMargins(animate: selectedTrail == nil)
    }}
    
    // Search Bar
    var searchBar: UISearchBar?
    var localSearch: MKLocalSearch?
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
    @Defaults("completedTrailIDs") var completedTrailIDs = [Int16]() { didSet {
        objectWillChange.send()
    }}
    @Defaults("expand") var expand = false { didSet {
        updateLayoutMargins()
        objectWillChange.send()
    }}
    @Defaults("metric") var metric = true { didSet {
        objectWillChange.send()
    }}
    @Defaults("recentSearches") var recentSearches = [String]() { didSet {
        objectWillChange.send()
        if recentSearches.count > 3 {
            recentSearches.remove(at: 0)
        }
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
    
    // MARK: - Initialiser
    override init() {
        super.init()
        manager.delegate = self
        loadData()
    }
    
    // MARK: - Load Data
    func loadData(from file: String) -> Data {
        let url = Bundle.main.url(forResource: file, withExtension: "")!
        return try! Data(contentsOf: url)
    }
    
    func decodeJSON<T: Decodable>(data: Data) -> T {
        try! JSONDecoder().decode(T.self, from: data)
    }

    func loadData() {
        let linesData = loadData(from: "Coords.geojson")
        let features = try! MKGeoJSONDecoder().decode(linesData) as! [MKGeoJSONFeature]
        let trailsLines = features.map { feature in
            let properties: TrailProperties = decodeJSON(data: feature.properties!)
            return TrailLines(id: properties.id, multiPolyline: feature.geometry.first as! MKMultiPolyline)
        }
        let metadataData = loadData(from: "Metadata.json")
        let trailsMetadata: [TrailMetadata] = decodeJSON(data: metadataData)
        
        for id in 0...44 {
            let lines = trailsLines.first { $0.id == id }!
            let metadata = trailsMetadata.first { $0.id == id }!
            trails.append(Trail(lines: lines, metadata: metadata))
        }
        
        container.loadPersistentStores { description, error in
//            self.deleteAll(entityName: "TrailTrips")
//            self.completedTrailIDs = []
            self.trailsTrips = (try? self.container.viewContext.fetch(TrailTrips.fetchRequest()) as? [TrailTrips]) ?? []
            self.trailsTrips.forEach { $0.reload() }
        }
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
    
    // MARK: - General
    func formatMiles(_ metres: Double, showUnit: Bool, round: Bool) -> String {
        let value = metres / (metric ? 1000 : 1609.34)
        return String(format: "%.\(round ? 0 : 1)f", value) + (showUnit ? (metric ? " km" : " miles") : "")
    }
    
    func formatFeet(_ metres: Int) -> String {
        let value = Double(metres) * (metric ? 2 : 3.28084)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return (formatter.string(from: NSNumber(value: Int(value))) ?? "") + (metric ? " m" : " feet")
    }
    
    func shakeError() {
        Haptics.tap()
        shake = true
        withAnimation(.spring(response: 0.2, dampingFraction: 0.2, blendDuration: 0.2)) {
            shake = false
        }
    }
    
    func getSelectedTrips(trail: Trail?) -> TrailTrips? {
        trailsTrips.first { $0.id == trail?.id }
    }
    
    var darkMode: Bool {
        UITraitCollection.current.userInterfaceStyle == .dark || mapView?.mapType == .hybrid
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
    
    func refreshOverlays() {
        let overlays = mapView?.overlays(in: .aboveRoads) ?? []
        mapView?.removeOverlays(overlays)
        mapView?.addOverlays(overlays, level: .aboveRoads)
    }
    
    func updateLayoutMargins(animate: Bool = true) {
        var top = CGFloat.zero
        if let selectedTrail {
            top = expand ? 275 : 80
            if selectedTrail.name.count > 30 {
                top += 25
            }
        }
        let padding = UIEdgeInsets(top: top, left: 0, bottom: 30, right: 0)
        UIView.animate(withDuration: animate ? 0.35 : 0) {
            self.mapView?.layoutMargins = padding
        }
    }
    
    func setRect(_ rect: MKMapRect, extraPadding: Bool = false) {
        let padding: CGFloat = extraPadding ? 40 : 20
        let insets = UIEdgeInsets(top: padding, left: padding, bottom: padding + 30, right: padding)
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
                self.newSelectPin(placemark: placemark, coord: coord)
            }
        }
    }
    
    func newSelectPin(placemark: CLPlacemark, coord: CLLocationCoordinate2D) {
        let annotation = Annotation(type: .select, placemark: placemark, coord: coord)
        selectPins.append(annotation)
        mapView?.addAnnotation(annotation)
        mapView?.deselectAnnotation(annotation, animated: false)
        
        if selectPins.count == 2 {
            let coords = calculateLine(between: selectPins[0].coordinate, and: selectPins[1].coordinate)
            
            selectError = coords.count < 2
            guard !selectError else { shakeError(); return }
            
            guard let start = coords.first, let end = coords.last else { return }
            let tripCoords = selectedTrips?.linesCoords.flatMap { $0 } ?? []
            canUncomplete = tripCoords.contains(start) || tripCoords.contains(end)
            
            selectPolyline = MKPolyline(coordinates: coords, count: coords.count)
            mapView?.addOverlay(selectPolyline!, level: .aboveRoads)
            selectMetres = coords.metres()
            zoomTo(selectPolyline, extraPadding: true)
            Haptics.tap()
        }
    }
    
    func startSelecting() {
        stopSelecting()
        stopSearching()
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
        guard let selectedTrail, let selectedCoords = selectPolyline?.coordinates else { return }
        let trips: TrailTrips
        
        if let selectedTrips {
            trips = selectedTrips
            let existingCoords = selectedTrips.linesCoords.flatMap { $0 }
            var newLines = [[CLLocationCoordinate2D]]()
            
            for coords in selectedTrail.linesCoords {
                var newLine = [CLLocationCoordinate2D]()
                for coord in coords {
                    if selectedCoords.contains(coord) || existingCoords.contains(coord) {
                        newLine.append(coord)
                    } else {
                        newLines.append(newLine)
                        newLine = []
                    }
                }
                if newLine.isNotEmpty {
                    newLines.append(newLine)
                }
            }
            trips.lines = newLines.map { $0.map { [$0.latitude, $0.longitude] } }
        } else {
            trips = TrailTrips(context: container.viewContext)
            trips.id = selectedTrail.id
            trips.lines = [selectedCoords.map { [$0.latitude, $0.longitude] }]
            trailsTrips.append(trips)
        }
        save()
        trips.reload()
        mapView?.removeOverlay(trips)
        mapView?.addOverlay(trips, level: .aboveRoads)
        stopSelecting()
        
        if trips.metres.equalTo(selectedTrail.metres, to: -3) && !completedTrailIDs.contains(selectedTrail.id) {
            Haptics.success()
            completedTrailIDs.append(selectedTrail.id)
            showCompletedAlert = true
        } else {
            Haptics.tap()
        }
    }
    
    func uncompleteSelectPolyline() {
        guard let selectedTrail, let selectedTrips, let selectedCoords = selectPolyline?.coordinates else { return }

        let existingCoords = selectedTrips.linesCoords.flatMap { $0 }
        var newLines = [[CLLocationCoordinate2D]]()
        
        for coords in selectedTrail.linesCoords {
            var newLine = [CLLocationCoordinate2D]()
            for coord in coords {
                if existingCoords.contains(coord) && !selectedCoords.contains(coord) {
                    newLine.append(coord)
                } else {
                    newLines.append(newLine)
                    newLine = []
                }
            }
            if newLine.isNotEmpty {
                newLines.append(newLine)
            }
        }
        selectedTrips.lines = newLines.map { $0.map { [$0.latitude, $0.longitude] } }
        save()
        selectedTrips.reload()
        mapView?.removeOverlay(selectedTrips)
        mapView?.addOverlay(selectedTrips, level: .aboveRoads)
        stopSelecting()
        
        if !selectedTrips.metres.equalTo(selectedTrail.metres, to: -3) {
            completedTrailIDs.removeAll(selectedTrail.id)
        }
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
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let trail = overlay as? Trail {
            let renderer = MKMultiPolylineRenderer(multiPolyline: trail.multiPolyline)
            renderer.lineWidth = trail == selectedTrail ? 3 : 2
            renderer.strokeColor = darkMode ? UIColor(.cyan) : .link
            return renderer
        } else if let trips = overlay as? TrailTrips {
            let renderer = MKMultiPolylineRenderer(multiPolyline: trips.multiPolyline)
            renderer.lineWidth = 3
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
                pin?.pinTintColor = UIColor(.orange)
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
        search(text: text)
    }
    
    func stopSearching() {
        isSearching = false
        resetSearching()
    }
    
    func resetSearching() {
        mapView?.removeAnnotations(searchResults)
        searchResults = []
    }
    
    func search(text: String) {
        search(text: text) { success in
            if success {
                self.searchBar?.resignFirstResponder()
                if !self.recentSearches.contains(text) {
                    self.recentSearches.append(text)
                }
            } else {
                self.shakeError()
            }
        }
    }
    
    func search(text: String, completion: @escaping (Bool) -> Void) {
        resetSearching()
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = text
        guard let mapView else { return }
        request.region = mapView.region
        
        localSearch?.cancel()
        localSearch = MKLocalSearch(request: request)
        localSearch?.start { response, error in
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
