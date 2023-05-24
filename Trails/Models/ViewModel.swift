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
    @Published var filteredTrails = [Trail]()
    @Published var trailFilter: TrailFilter? { didSet {
        filterTrails()
        zoomToFilteredTrails()
    }}
    
    // Search
    var searchBar: UISearchBar?
    var searchRect: MKMapRect?
    var localSearch: MKLocalSearch?
    let searchCompleter = MKLocalSearchCompleter()
    var previousSearch: Search?
    @Published var searchCompletions = [MKLocalSearchCompletion]()
    @Published var isEditing = false
    @Published var searchResults = [Annotation]()
    @Published var searchRequestLoading = false
    @Published var filteredRecentSearches = [String]()
    @Published var searchScope = SearchScope.Trails
    @Published var isSearching = false { didSet {
        filterTrails()
    }}
    @Published var searchText = "" { didSet {
        searchBar?.text = searchText
        filterTrails()
        filterRecentSearches()
        fetchCompletions()
    }}
    
    // Select Section
    var selectBarSize = CGSize()
    @Published var isSelecting = false
    @Published var selectError = false
    @Published var canUncomplete = false
    @Published var canComplete = false
    @Published var selectMetres = 0.0
    @Published var selectPolyline: MKPolyline?
    @Published var startPin: Annotation?
    @Published var endPin: Annotation?
    
    // Animations
    @Published var degrees = 0.0
    @Published var scale = 1.0
    @Published var shake = false
    var animateDetentChange = false
    @Published var sheetDetent = SheetDetent.small
    @Published var safeAreaInset = 0.0
    @Published var dragOffset = 0.0
    @Published var snapOffset = 5000.0 { didSet {
        UIView.animate(withDuration: 0.5) {
            self.mapView?.compass?.alpha = self.mapDisabled ? 0 : 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.safeAreaInset = self.snapOffset
        }
    }}
    
    // Traits
    var lightOverlays: Bool {
        UITraitCollection.current.userInterfaceStyle == .dark || mapView?.mapType == .hybrid
    }
    var compact: Bool {
        mapView?.safeAreaLayoutGuide.layoutFrame.width ?? 0 < 500
    }
    var mapDisabled: Bool {
        snapOffset == 0 && compact
    }
    
    // Dimensions
    let mediumSheetHeight = 270.0
    let regularWidth = 320.0
    var topPadding: CGFloat {
        compact ? 20 : 10
    }
    var horizontalPadding: CGFloat {
        compact ? 0 : 10
    }
    var sheetHeight: CGFloat {
        (mapView?.safeAreaLayoutGuide.layoutFrame.height ?? 0) - (topPadding + snapOffset)
    }
    var maxWidth: CGFloat {
        compact ? .infinity : regularWidth
    }
    
    // View State
    @Published var showCompletedAlert = false
    
    // Storage
    @Storage("favouriteTrails") var favouriteTrails = [Int16]() { didSet {
        objectWillChange.send()
    }}
    @Storage("completedTrails") var completedTrails = [Int16]() { didSet {
        objectWillChange.send()
    }}
    @Storage("recentSearches") var recentSearches = [String]() { didSet {
        filterRecentSearches()
    }}
    @Storage("metric") var metric = true { didSet {
        objectWillChange.send()
    }}
    @Storage("shownReviewPrompt") var shownReviewPrompt = false
    @Storage("ascending") var ascending = false
    @Storage("sortBy") var sortBy = TrailSort.name { didSet {
        if oldValue == sortBy {
            ascending.toggle()
        }
        sortTrails()
    }}
    
    // MapView
    var mapView: _MKMapView?
    var annotationSelected = false
    var pinAddedDate = Date.now
    @Published var trackingMode = MKUserTrackingMode.none
    @Published var mapType = MKMapType.standard
    
    // CLLocationManager
    let locationManager = CLLocationManager()
    var authStatus = CLAuthorizationStatus.notDetermined
    @Published var showAuthAlert = false
    
    // Persistence
    let container = NSPersistentContainer(name: "Trails")
    func save() {
        try? container.viewContext.save()
    }
    
    // MARK: - Initialiser
    override init() {
        super.init()
        locationManager.delegate = self
        searchCompleter.delegate = self
        loadData()
        filterRecentSearches()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @objc
    func orientationDidChange() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.refreshSheetDetent()
        }
    }
    
    func refreshSheetDetent() {
        sheetDetent = sheetDetent
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
        let metadataData = loadData(from: "Metadata.json")
        let trailsMetadata: [TrailMetadata] = decodeJSON(data: metadataData)
        
        for metadata in trailsMetadata {
            let geojsonData = loadData(from: "\(metadata.name).geojson")
            let features = try! MKGeoJSONDecoder().decode(geojsonData) as! [MKGeoJSONFeature]
            let polyline = features.first?.geometry.first as! MKPolyline
            trails.append(Trail(metadata: metadata, polyline: polyline))
        }
        
        container.loadPersistentStores { description, error in
            self.trailsTrips = (try? self.container.viewContext.fetch(TrailTrips.fetchRequest()) as? [TrailTrips]) ?? []
            self.trailsTrips.forEach { $0.reload() }
            self.filterTrails()
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
        return String(format: "%.\(round ? 0 : 1)f", max(0.1, value)) + (showUnit ? (metric ? " km" : " miles") : "")
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
        stopEditing()
        selectedTrail = trail
        refreshOverlays()
        if let trail {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.zoomTo(trail)
            }
        }
    }
    
    func filterTrails() {
        filteredTrails = trails.filter { trail in
            let searching = trail.name.localizedCaseInsensitiveContains(searchText) || searchText.isEmpty
            let filter: Bool
            switch trailFilter {
            case nil:
                filter = true
            case .favourite:
                filter = isFavourite(trail)
            case .completed:
                filter = isCompleted(trail)
            case .country(let country):
                filter = country == trail.country
            }
            return isSearching ? searching : filter
        }
        sortTrails()
        refreshOverlays()
    }
    
    func sortTrails() {
        let sorted = filteredTrails.sorted {
            switch sortBy {
            case .name:
                return $0.name < $1.name
            case .ascent:
                return $0.ascent < $1.ascent
            case .distance:
                return $0.metres < $1.metres
            case .completed:
                return getTrips(trail: $0)?.metres ?? 0 < getTrips(trail: $1)?.metres ?? 0
            }
        }
        filteredTrails = ascending ? sorted : sorted.reversed()
    }
    
    func zoomToFilteredTrails(animated: Bool = true) {
        if filteredTrails.isNotEmpty {
            setRect(filteredTrails.rect, animated: animated)
        }
    }
    
    func filterRecentSearches() {
        filteredRecentSearches = recentSearches.filter { search in
            searchText.isEmpty || search.localizedStandardContains(searchText) && searchText != search
        }.reversed()
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
        mapView?.removeOverlays(trails)
        mapView?.removeOverlays(trailsTrips)
        if let selectedTrail {
            mapView?.addOverlay(selectedTrail, level: .aboveRoads)
            if let selectedTrips {
                mapView?.addOverlay(selectedTrips, level: .aboveRoads)
            }
        } else {
            mapView?.addOverlays(filteredTrails, level: .aboveRoads)
        }
        refreshSelectPolyline()
    }
    
    func zoomTo(_ overlay: MKOverlay?, extraPadding: Bool = false) {
        if let overlay {
            setRect(overlay.boundingMapRect, extraPadding: extraPadding)
        }
    }
    
    func setRect(_ rect: MKMapRect, extraPadding: Bool = false, animated: Bool = true) {
        guard let mapView else { return }
        let padding = extraPadding ? 40.0 : 20.0
        let bottom = isSelecting ? selectBarSize.height - 10 : (sheetDetent == .large || !compact ? 0 : sheetHeight)
        let left = compact || isSelecting ? 0.0 : horizontalPadding + regularWidth
        let insets = UIEdgeInsets(top: padding, left: padding + left, bottom: padding + bottom, right: padding)
        mapView.setVisibleMapRect(rect, edgePadding: insets, animated: animated)
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
    func newSelectPin(annotation: Annotation) {
        if startPin == nil {
            startPin = annotation
        } else if endPin == nil {
            endPin = annotation
        } else {
            return
        }
        mapView?.addAnnotation(annotation)
        pinAddedDate = .now
        
        if let startPin, let endPin {
            let coords = calculateLine(between: startPin.coordinate, and: endPin.coordinate)
            
            selectError = coords.count < 2
            guard !selectError else {
                removeSelectPins()
                Haptics.error()
                shake = true
                withAnimation(.spring(response: 0.2, dampingFraction: 0.2, blendDuration: 0.2)) {
                    shake = false
                }
                return
            }
            
            if let selectedTrips {
                canComplete = coords.contains { !selectedTrips.coordsSet.contains($0) }
                canUncomplete = coords.contains { selectedTrips.coordsSet.contains($0) }
            } else {
                canComplete = true
                canUncomplete = false
            }
            
            let polyline = MKPolyline(coordinates: coords, count: coords.count)
            selectPolyline = polyline
            refreshSelectPolyline()
            selectMetres = coords.metres()
            Haptics.tap()
            DispatchQueue.main.async {
                self.zoomTo(polyline, extraPadding: true)
            }
        }
    }
    
    func startSelecting() {
        withAnimation(.sheet) {
            isSelecting = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.zoomTo(self.selectedTrail)
        }
    }
    
    func resetSelecting() {
        selectError = false
        removeSelectPins()
        removeSelectPolyline()
    }
    
    func removeSelectPins() {
        if let startPin {
            mapView?.removeAnnotation(startPin)
            self.startPin = nil
        }
        if let endPin {
            mapView?.removeAnnotation(endPin)
            self.endPin = nil
        }
    }
    
    func stopSelecting() {
        resetSelecting()
        withAnimation(.sheet) {
            isSelecting = false
        }
    }
    
    func removeSelectPolyline() {
        if let selectPolyline {
            mapView?.removeOverlay(selectPolyline)
            self.selectPolyline = nil
        }
    }
    
    func refreshSelectPolyline() {
        if let selectPolyline {
            mapView?.removeOverlay(selectPolyline)
            mapView?.addOverlay(selectPolyline, level: .aboveRoads)
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
        guard let mapView else { return nil }
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
        guard !(isSelecting && selectPolyline == nil), press.state == .began, let coord = getCoord(from: press) else { return }
        reverseGeocode(coord: coord) { placemark in
            Haptics.tap()
            let annotation = Annotation(type: .drop, placemark: placemark)
            self.mapView?.addAnnotation(annotation)
            self.mapView?.selectAnnotation(annotation, animated: true)
        }
    }
    
    @objc
    func handleTap(_ tap: UITapGestureRecognizer) {
        guard !annotationSelected, let coord = getCoord(from: tap) else { return }

        if isSelecting {
            reverseGeocode(coord: coord) { placemark in
                self.newSelectPin(annotation: Annotation(type: .select, placemark: placemark))
            }
        } else {
            let searchTrails = selectedTrail == nil ? trails : [selectedTrail!]
            let (_, trail) = getClosestTrail(to: coord, trails: searchTrails, maxDelta: tapDelta)
            selectTrail(trail)
        }
    }
    
    @objc
    func tappedCompass() {
        guard trackingMode == .followWithHeading else { return }
        updateTrackingMode(.follow)
    }
}

// MARK: - CLLocationManagerDelegate
extension ViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authStatus = manager.authorizationStatus
        if authStatus == .denied {
            showAuthAlert = true
        } else if authStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }
    
    func validateAuth() -> Bool {
        showAuthAlert = authStatus == .denied
        return !showAuthAlert
    }
}

// MARK: - MKMapViewDelegate
extension ViewModel: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let trail = overlay as? Trail {
            let renderer = MKPolylineRenderer(polyline: trail.polyline)
            renderer.lineWidth = trail == selectedTrail ? 3 : 2
            renderer.strokeColor = lightOverlays ? UIColor(.cyan) : .link
            return renderer
        } else if let trips = overlay as? TrailTrips {
            let renderer = MKMultiPolylineRenderer(multiPolyline: trips.multiPolyline)
            renderer.lineWidth = 3
            renderer.strokeColor = lightOverlays ? .white : .black
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
        let config = UIImage.SymbolConfiguration(font: .systemFont(ofSize: Constants.size/2))
        let image = UIImage(systemName: systemName, withConfiguration: config)
        button.setImage(image, for: .normal)
        button.frame.size = CGSize(width: Constants.size, height: Constants.size)
        return button
    }
    
    func getShareMenu(mapItem: MKMapItem, allowsDirections: Bool) -> UIButton {
        let options = getButton(systemName: "ellipsis.circle")
        var children = [UIMenuElement]()
        if allowsDirections {
            children.append(UIAction(title: "Get Directions", image: UIImage(systemName: "arrow.triangle.turn.up.right.diamond")) { _ in
                self.openInMaps(mapItem: mapItem, directions: true)
            })
        }
        children.append(UIAction(title: "Open in Maps", image: UIImage(systemName: "map")) { _ in
            self.openInMaps(mapItem: mapItem, directions: false)
        })
        children.append(UIAction(title: "Share...", image: UIImage(systemName: "square.and.arrow.up")) { _ in
            self.shareCoord(mapItem.placemark.coordinate)
        })
        options.menu = UIMenu(children: children)
        options.showsMenuAsPrimaryAction = true
        return options
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? Annotation else { return nil }
        let removeButton = getButton(systemName: "xmark")
        let shareMenu = getShareMenu(mapItem: annotation.mapItem, allowsDirections: true)
        switch annotation.type {
        case .select:
            let pin = mapView.dequeueReusableAnnotationView(withIdentifier: MKPinAnnotationView.id, for: annotation) as? MKPinAnnotationView
            pin?.displayPriority = .required
            pin?.animatesDrop = true
            pin?.rightCalloutAccessoryView = shareMenu
            pin?.leftCalloutAccessoryView = removeButton
            pin?.canShowCallout = true
            pin?.pinTintColor = UIColor(.orange)
            return pin
        case .search, .drop:
            let marker = mapView.dequeueReusableAnnotationView(withIdentifier: MKMarkerAnnotationView.id, for: annotation) as? MKMarkerAnnotationView
            marker?.displayPriority = .required
            marker?.animatesWhenAdded = true
            marker?.rightCalloutAccessoryView = shareMenu
            marker?.canShowCallout = true
            if let category = annotation.mapItem.pointOfInterestCategory {
                marker?.glyphImage = UIImage(systemName: category.systemName)
                marker?.markerTintColor = UIColor(category.color)
            }
            if annotation.type == .drop {
                marker?.leftCalloutAccessoryView = removeButton
            }
            return marker
        }
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        if let view = mapView.view(for: mapView.userLocation),
           let user = view.annotation {
            reverseGeocode(coord: user.coordinate) { placemark in
                let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
                mapItem.name = "My Location"
                view.rightCalloutAccessoryView = self.getShareMenu(mapItem: mapItem, allowsDirections: false)
            }
        }
    }
    
    func openInMaps(mapItem: MKMapItem, directions: Bool) {
        mapItem.openInMaps(launchOptions: directions ? [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault] : nil)
    }
    
    func shareCoord(_ coord: CLLocationCoordinate2D) {
        guard let mapView, let url = URL(string: "https://maps.apple.com/?ll=\(coord.latitude),\(coord.longitude)") else { return }
        let point = mapView.convert(coord, toPointTo: mapView)
        let shareVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        shareVC.popoverPresentationController?.sourceView = mapView
        shareVC.popoverPresentationController?.sourceRect = CGRect(origin: point, size: .zero)
        mapView.window?.rootViewController?.present(shareVC, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let annotation = view.annotation as? Annotation else { return }
        switch annotation.type {
        case .drop:
            mapView.deselectAnnotation(annotation, animated: true)
            mapView.removeAnnotation(annotation)
        case .select:
            if startPin == annotation {
                startPin = nil
            }
            if endPin == annotation {
                endPin = nil
            }
            mapView.removeAnnotation(annotation)
            removeSelectPolyline()
        default: break
        }
    }
    
    func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        if !animated {
            updateTrackingMode(.none)
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        annotationSelected = true
        if Date.now.timeIntervalSince(pinAddedDate) < 0.5 {
            mapView.deselectAnnotation(view.annotation, animated: false)
        }
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        annotationSelected = false
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if let searchRect, !mapView.visibleMapRect.intersects(searchRect) {
            searchMaps(newSearch: nil)
        }
    }
}

// MARK: - UISearchBarDelegate
extension ViewModel: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        switch searchScope {
        case .Maps:
            searchText = searchText.trimmed
            guard searchText.isNotEmpty else { return }
            searchMaps(newSearch: .string(searchText))
        case .Trails:
            zoomToFilteredTrails()
            stopEditing()
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        stopSearching()
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        withAnimation(.sheet) {
            searchScope = SearchScope.allCases[selectedScope]
            sheetDetent = .large
        }
        startEditing()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        startEditing()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        stopEditing()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange text: String) {
        searchText = text
    }
    
    func startEditing() {
        fetchCompletions()
        isEditing = true
        sheetDetent = .large
        resetSearching()
        searchBar?.becomeFirstResponder()
        if !isSearching {
            startSearching()
        }
    }
    
    func stopEditing() {
        isEditing = false
        searchBar?.resignFirstResponder()
        if let cancelButton = searchBar?.value(forKey: "cancelButton") as? UIButton {
            cancelButton.isEnabled = true
        }
    }
    
    func startSearching() {
        searchBar?.becomeFirstResponder()
        searchBar?.setShowsCancelButton(true, animated: true)
        searchBar?.setShowsScope(true, animated: true)
        isSearching = true
    }
    
    func stopSearching() {
        searchText = ""
        resetSearching()
        stopEditing()
        searchBar?.setShowsCancelButton(false, animated: false)
        searchBar?.setShowsScope(false, animated: false)
        isSearching = false
        sheetDetent = .medium
    }
    
    func stopSearchRequest() {
        localSearch?.cancel()
        searchRequestLoading = false
    }
    
    func resetSearching() {
        mapView?.removeAnnotations(searchResults)
        stopSearchRequest()
        searchResults = []
        searchRect = nil
    }
    
    func updateRecentSearches(with string: String) {
        recentSearches.removeAll { $0.lowercased() == string.lowercased() }
        recentSearches.append(string)
    }
    
    func searchMaps(newSearch: Search?) {
        previousSearch = newSearch ?? previousSearch
        guard let search = previousSearch else { return }
        let request: MKLocalSearch.Request
        switch search {
        case .string(let string):
            request = .init()
            request.naturalLanguageQuery = string
            searchText = string
            updateRecentSearches(with: string)
        case .completion(let completion):
            request = .init(completion: completion)
            updateRecentSearches(with: completion.title)
        }
        guard let mapView else { return }
        request.region = mapView.region
        request.resultTypes = [.address, .pointOfInterest]
        
        sheetDetent = .medium
        resetSearching()
        stopEditing()
        searchRect = mapView.visibleMapRect
        
        stopSearchRequest()
        searchRequestLoading = true
        localSearch = MKLocalSearch(request: request)
        localSearch?.start { response, error in
            self.searchRequestLoading = false
            guard let response else { return }

            let rect = response.boundingRegion.rect
            let results = response.mapItems.map { mapItem in
                Annotation(type: .search, mapItem: mapItem)
            }
            
            self.searchRect = rect
            self.searchResults = results.filter { result in !self.searchResults.contains { $0.coordinate == result.coordinate } }
            mapView.addAnnotations(results)
            if results.count == 1 {
                mapView.selectAnnotation(results.first!, animated: true)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.setRect(rect, extraPadding: true)
            }
        }
    }
}

// MARK: - MKLocalSearchCompleterDelegate
extension ViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchCompletions = completer.results
    }
    
    func fetchCompletions() {
        guard let mapView, searchText.isNotEmpty, searchScope == .Maps else { return }
        searchCompleter.cancel()
        searchCompleter.queryFragment = searchText
        searchCompleter.region = mapView.region
        searchCompleter.resultTypes = [.address, .pointOfInterest, .query]
    }
}
