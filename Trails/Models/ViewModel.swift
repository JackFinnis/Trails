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
    // Trails
    var trails = [Trail]()
    var trailsTrips = [TrailTrips]()
    var selectedTrips: TrailTrips? { getTrips(trail: selectedTrail) }
    @Published var selectedTrail: Trail?
    
    // Search
    var searchBar: UISearchBar?
    var searchRect: MKMapRect?
    var localSearch: MKLocalSearch?
    @Published var isSearching = false
    @Published var isEditing = false
    @Published var searchResults = [Annotation]()
    @Published var searchText = ""
    @Published var searchScope = SearchScope.Trails
    
    // Select Section
    @Published var isSelecting = false
    @Published var selectError = false
    @Published var canUncomplete = false
    @Published var canComplete = false
    @Published var selectMetres = 0.0
    @Published var selectPolyline: MKPolyline?
    @Published var selectPins = [Annotation]()
    
    // Animations
    @Published var snapOffset: CGFloat = 5000
    @Published var dragOffset = CGFloat.zero
    @Published var degrees = 0.0
    @Published var scale = 1.0
    
    // View
    @Published var showShareLocationSheet = false
    @Published var showCompletedAlert = false
    @Published var showInfoView = false
    @Published var welcome = false
    
    // Other
    var shareLocationItems = [Any]()
    var annotationSelected = false
    
    // Defaults
    @Storage("favouriteTrails") var favouriteTrails = [Int16]() { didSet {
        objectWillChange.send()
    }}
    @Storage("completedTrails") var completedTrails = [Int16]() { didSet {
        objectWillChange.send()
    }}
    @Storage("recentSearches") var recentSearches = [String]() { didSet {
        objectWillChange.send()
    }}
    @Storage("metric") var metric = true { didSet {
        objectWillChange.send()
    }}
    @Storage("ascending") var ascending = false { didSet {
        objectWillChange.send()
    }}
    @Storage("sortBy") var sortBy = TrailSort.name { didSet {
        objectWillChange.send()
        if oldValue == sortBy {
            ascending.toggle()
        }
    }}
    
    // MapView
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
        let start = Date.now
        
        let metadataData = loadData(from: "Metadata.json")
        let trailsMetadata: [TrailMetadata] = decodeJSON(data: metadataData)
        
        for metadata in trailsMetadata {
            let geojsonData = loadData(from: "\(metadata.name).geojson")
            let features = try! MKGeoJSONDecoder().decode(geojsonData) as! [MKGeoJSONFeature]
            let polyline = features.first?.geometry.first as! MKPolyline
            trails.append(Trail(metadata: metadata, polyline: polyline))
        }
        
        container.loadPersistentStores { description, error in
//            self.deleteAll(entityName: "TrailTrips")
//            self.completedTrails = []
            self.trailsTrips = (try? self.container.viewContext.fetch(TrailTrips.fetchRequest()) as? [TrailTrips]) ?? []
            self.trailsTrips.forEach { $0.reload() }
        }
    }
    
    func deleteAll(entityName: String) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        _ = try? container.viewContext.execute(deleteRequest)
    }
    
    // MARK: - General
    func formatDistance(_ metres: Double, showUnit: Bool, round: Bool) -> String {
        let value = metres / (metric ? 1000 : 1609.34)
        return String(format: "%.\(round ? 0 : 1)f", value) + (showUnit ? (metric ? " km" : " miles") : "")
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    func getTrips(trail: Trail?) -> TrailTrips? {
        trailsTrips.first { $0.id == trail?.id }
    }
    
    func isFavourite(_ trail: Trail) -> Bool {
        favouriteTrails.contains(trail.id)
    }
    
    func isCompleted(_ trail: Trail) -> Bool {
        completedTrails.contains(trail.id)
    }
    
    func toggleFavourite(_ trail: Trail) {
        if favouriteTrails.contains(trail.id) {
            favouriteTrails.removeAll(trail.id)
        } else {
            favouriteTrails.append(trail.id)
            Haptics.tap()
        }
    }
    
    func selectTrail(_ trail: Trail?) {
        selectedTrail = trail
        if let trail {
            mapView?.removeOverlays(trails)
            mapView?.addOverlay(trail, level: .aboveRoads)
            if let selectedTrips {
                mapView?.addOverlay(selectedTrips, level: .aboveRoads)
            }
            zoomTo(trail)
        } else {
            mapView?.removeOverlays(trailsTrips)
            mapView?.addOverlays(trails, level: .aboveRoads)
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
        guard validateAuth() else { return }
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
    
//    func updateLayoutMargins(animate: Bool = true) {
//        let padding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
//        UIView.animate(withDuration: animate ? 0.35 : 0) {
//            self.mapView?.layoutMargins = padding
//        }
//    }
    
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
    
    func getClosestTrail(to targetCoord: CLLocationCoordinate2D, trails: [Trail], maxDelta: Double) -> (CLLocationCoordinate2D?, Trail?) {
        let targetLocation = targetCoord.location
        var shortestDistance = Double.infinity
        var closestCoord: CLLocationCoordinate2D?
        var closestTrail: Trail?
        
        for trail in trails {
            for location in trail.locations {
                let delta = location.distance(from: targetLocation)
                
                if delta < shortestDistance && delta < maxDelta {
                    shortestDistance = delta
                    closestTrail = trail
                    closestCoord = location.coordinate
                }
            }
        }
        return (closestCoord, closestTrail)
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
            guard !selectError else { return }
            
            if let selectedTrips {
                canComplete = coords.contains { !selectedTrips.coordsSet.contains($0) }
                canUncomplete = coords.contains { selectedTrips.coordsSet.contains($0) }
            }
            
            selectPolyline = MKPolyline(coordinates: coords, count: coords.count)
            mapView?.addOverlay(selectPolyline!, level: .aboveRoads)
            selectMetres = coords.metres()
            zoomTo(selectPolyline, extraPadding: true)
            Haptics.tap()
        }
    }
    
    func startSelecting() {
        isSelecting = true
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
    
    func calculateLine(between coord1: CLLocationCoordinate2D, and coord2: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
        guard let selectedTrail else { return [] }
        let (startCoord, _) = getClosestTrail(to: coord1, trails: [selectedTrail], maxDelta: .infinity)
        let (endCoord, _) = getClosestTrail(to: coord2, trails: [selectedTrail], maxDelta: .infinity)
        guard let startCoord, let endCoord else { return [] }
        
        let coords = selectedTrail.coords
        guard let startIndex = coords.firstIndex(of: startCoord),
              let endIndex = coords.firstIndex(of: endCoord)
        else { return [] }
        
        return Array(coords[min(startIndex, endIndex)...max(startIndex, endIndex)])
    }
    
    func completeSelectPolyline() {
        guard let selectedTrail,
              let selectedCoords = selectPolyline?.coordinates
        else { return }
        
        if let selectedTrips {
            var newCoords = Set(selectedTrips.coordsSet)
            newCoords.formUnion(selectedCoords)
            update(trips: selectedTrips, with: newCoords)
        } else {
            let trips = TrailTrips(context: container.viewContext)
            trips.id = selectedTrail.id
            trailsTrips.append(trips)
            update(trips: trips, with: Set(selectedCoords))
        }
        Haptics.success()
    }
    
    func uncompleteSelectPolyline() {
        guard let selectedTrips,
              let selectedCoords = selectPolyline?.coordinates
        else { return }

        var newCoords = Set(selectedTrips.coordsSet)
        newCoords.subtract(selectedCoords)
        
        update(trips: selectedTrips, with: newCoords)
    }
    
    func update(trips: TrailTrips, with newCoords: Set<CLLocationCoordinate2D>) {
        guard let selectedTrail else { return }
        
        var newLines = [[CLLocationCoordinate2D]]()
        var newLine = [CLLocationCoordinate2D]()
        for coord in selectedTrail.coords {
            if newCoords.contains(coord) {
                newLine.append(coord)
            } else {
                newLines.append(newLine)
                newLine = []
            }
        }
        if newLine.isNotEmpty {
            newLines.append(newLine)
        }
        trips.lines = newLines.map { $0.map { [$0.latitude, $0.longitude] } }
        save()
        trips.reload()
        mapView?.removeOverlay(trips)
        mapView?.addOverlay(trips, level: .aboveRoads)
        stopSelecting()
        
        if trips.metres.equalTo(selectedTrail.metres, to: -4) {
            if !completedTrails.contains(selectedTrail.id) {
                completedTrails.append(selectedTrail.id)
                showCompletedAlert = true
            }
        } else {
            completedTrails.removeAll(selectedTrail.id)
        }
    }
}

// MARK: - UIGestureRecognizer
extension ViewModel: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { true }
    
    func getCoord(from gesture: UIGestureRecognizer) -> CLLocationCoordinate2D? {
        guard let mapView = mapView else { return nil }
        let point = gesture.location(in: mapView)
        
        var views = [UIView]()
        var view = mapView.hitTest(point, with: nil)
        while view != nil {
            views.append(view!)
            view = view?.superview
        }
        
        guard !views.contains(where: { $0 is MKAnnotationView }) else { return nil }
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
        } else if !annotationSelected {
            let searchTrails = selectedTrail == nil ? trails : [selectedTrail!]
            let (_, trail) = getClosestTrail(to: coord, trails: searchTrails, maxDelta: tapDelta)
            selectTrail(trail)
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
        let darkMode = UITraitCollection.current.userInterfaceStyle == .dark || mapView.mapType == .hybrid
        if let trail = overlay as? Trail {
            let renderer = MKPolylineRenderer(polyline: trail.polyline)
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
            renderer.lineWidth = 4
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
        guard let annotation = annotation as? Annotation else { return nil }
        let openButton = getButton(systemName: "arrow.triangle.turn.up.right.circle")
        let removeButton = getButton(systemName: "xmark")
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
    }
    
    func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        if !animated {
            updateTrackingMode(.none)
        }
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        let view = mapView.view(for: mapView.userLocation)
        view?.leftCalloutAccessoryView = getButton(systemName: "square.and.arrow.up")
        view?.rightCalloutAccessoryView = getButton(systemName: "map")
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        annotationSelected = true
        guard let annotation = view.annotation else { return }
        if isSelecting && selectPins.count < 2 {
            mapView.deselectAnnotation(annotation, animated: false)
        }
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        annotationSelected = false
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if let searchRect, !mapView.region.rect.intersects(searchRect) {
            searchMaps()
        }
    }
    
    @objc
    func tappedCompass() {
        guard trackingMode == .followWithHeading else { return }
        updateTrackingMode(.follow)
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let annotation = view.annotation as? Annotation {
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
        } else if let user = view.annotation as? MKUserLocation {
            let coord = user.coordinate
            if control == view.leftCalloutAccessoryView {
                guard let url = URL(string: "https://maps.apple.com/?ll=\(coord.latitude),\(coord.longitude)") else { return }
                shareLocationItems = [url]
                showShareLocationSheet = true
            } else {
                reverseGeocode(coord: coord) { placemark in
                    let item = MKMapItem(placemark: MKPlacemark(placemark: placemark))
                    item.name = "My Location"
                    item.openInMaps()
                }
            }
        }
    }
}

// MARK: - UISearchBarDelegate
extension ViewModel: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if searchScope == .Maps {
            searchMaps()
        }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        stopSearching()
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        withAnimation {
            searchScope = SearchScope.allCases[selectedScope]
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        isEditing = true
        withAnimation(.sheet) {
            snapOffset = 0
        }
        guard !isSearching else { return }
        startSearching()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        isEditing = false
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
    }
    
    func startSearching() {
        searchBar?.becomeFirstResponder()
        searchBar?.setShowsCancelButton(true, animated: true)
        searchBar?.setShowsScope(true, animated: true)
        withAnimation {
            isSearching = true
        }
    }
    
    func stopSearching() {
        searchBar?.text = ""
        searchText = ""
        resetSearching()
        stopLocalSearch()
        searchBar?.resignFirstResponder()
        searchBar?.setShowsCancelButton(false, animated: false)
        searchBar?.setShowsScope(false, animated: true)
        withAnimation {
            isSearching = false
        }
    }
    
    func stopLocalSearch() {
        localSearch?.cancel()
    }
    
    func resetSearching() {
        mapView?.removeAnnotations(searchResults)
        searchResults = []
        searchRect = nil
    }
    
    func searchMaps() {
        guard let text = searchBar?.text, text.isNotEmpty else { return }
        searchMaps(text: text) { success in
            if success {
                self.searchBar?.resignFirstResponder()
                if !self.recentSearches.contains(text) {
                    self.recentSearches.append(text)
                }
            }
        }
    }
    
    func searchMaps(text: String, completion: @escaping (Bool) -> Void) {
        resetSearching()
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = text
        guard let mapView else { return }
        request.region = mapView.region
        
        stopLocalSearch()
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
                self.searchRect = response.boundingRegion.rect
                self.setRect(self.searchRect!, extraPadding: true)
                completion(true)
            }
        }
    }
}
