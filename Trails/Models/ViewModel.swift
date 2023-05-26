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
import GeoJSON
import Contacts

@MainActor
class ViewModel: NSObject, ObservableObject {
    static let shared = ViewModel()
    
    // MARK: - Properties
    // Trails
    var trails = [Trail]()
    var trailsTrips = [TrailTrips]()
    var selectedTrips: TrailTrips? { getTrips(trail: selectedTrail) }
    @Published var selectedTrail: Trail? { didSet {
        selectedTrailId = selectedTrail?.id ?? -1
        if selectedTrail == nil {
            headerSize.height = 73
        }
    }}
    @Storage("selectedTrailId") var selectedTrailId = Int16(-1)
    @Storage("favouriteTrails") var favouriteTrails = [Int16]() { didSet {
        objectWillChange.send()
    }}
    @Storage("completedTrails") var completedTrails = [Int16]() { didSet {
        objectWillChange.send()
    }}
    
    // Filter
    var isFiltering: Bool { trailFilter != nil || isSearching }
    @Published var filteredTrails = [Trail]()
    @Published var trailFilter: TrailFilter? { didSet {
        filterTrails()
        zoomToFilteredTrails()
    }}
    @Storage("ascending") var ascending = false
    @Storage("sortBy") var sortBy = TrailSort.name { didSet {
        if oldValue == sortBy {
            ascending.toggle()
        }
        sortTrails()
    }}
    
    // Search
    var searchBar: UISearchBar?
    var isEditing = false
    @Published var isSearching = false
    @Published var searchText = "" { didSet {
        searchBar?.text = searchText
        filterTrails()
    }}
    
    // Select Section
    var selectBarSize = CGSize()
    @Published var isSelecting = false { didSet {
        refreshCompass()
    }}
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
    
    // Sheet
    @Published var headerSize = CGSize()
    @Published var sheetDetent = SheetDetent.small { didSet {
        refreshCompass()
        if sheetDetent != .large && isEditing {
            stopSearching()
        }
    }}
    
    // Dimensions
    let mediumDetentHeight = 270.0
    let regularSheetWidth = 320.0
    var unsafeWindowSize: CGSize {
        mapView?.layoutMarginsGuide.layoutFrame.size ?? .zero
    }
    func isCompact(_ size: CGSize) -> Bool {
        size.width < 500
    }
    func isMapDisabled(_ size: CGSize) -> Bool {
        sheetDetent == .large && isCompact(size) && !isSelecting
    }
    func getMaxSheetWidth(_ size: CGSize) -> CGFloat {
        isCompact(size) ? .infinity : regularSheetWidth
    }
    func getTopSheetPadding(_ size: CGSize) -> CGFloat {
        isCompact(size) ? 20 : 10
    }
    func getHorizontalSheetPadding(_ size: CGSize) -> CGFloat {
        isCompact(size) ? 0 : 10
    }
    func getSpacerHeight(_ size: CGSize, detent: SheetDetent) -> CGFloat {
        size.height - getDetentHeight(size, detent: detent)
    }
    func getDetentHeight(_ size: CGSize, detent: SheetDetent) -> CGFloat {
        switch detent {
        case .large:
            return size.height - getTopSheetPadding(size)
        case .medium:
            return mediumDetentHeight
        case .small:
            return headerSize.height
        }
    }
    func refreshCompass() {
        UIView.animate(withDuration: 0.3) {
            self.mapView?.compass?.alpha = self.isMapDisabled(self.unsafeWindowSize) ? 0 : 1
        }
    }
    
    // Completed Alert
    @Storage("shownReviewPrompt") var shownReviewPrompt = false
    @Published var showCompletedAlert = false { didSet {
        if !showCompletedAlert {
            shownReviewPrompt = true
        }
    }}
    
    // Preferences
    @Storage("metric") var metric = true { didSet {
        objectWillChange.send()
    }}
    
    // MapView
    var mapView: _MKMapView?
    var annotationSelected = false
    var annotationAddedDate = Date.now
    @Published var trackingMode = MKUserTrackingMode.none
    @Published var mapType = MKMapType.standard
    var lightOverlays: Bool {
        UITraitCollection.current.userInterfaceStyle == .dark || mapView?.mapType == .hybrid
    }
    var trailOverlayColor: UIColor {
        lightOverlays ? UIColor(.cyan) : .link
    }
    var tapDelta: Double {
        guard let rect = mapView?.visibleMapRect else { return 0 }
        let left = MKMapPoint(x: rect.minX, y: rect.midY)
        let right = MKMapPoint(x: rect.maxX, y: rect.midY)
        return left.distance(to: right) / 20
    }
    
    // CLLocationManager
    let locationManager = CLLocationManager()
    var authStatus = CLAuthorizationStatus.notDetermined
    @Published var showAuthAlert = false
    @Published var showWiFiAlert = false
    
    // Persistence
    let container = NSPersistentContainer(name: "Trails")
    func save() {
        try? container.viewContext.save()
    }
    
    // MARK: - Initialiser
    override init() {
        super.init()
        locationManager.delegate = self
        loadData()
        selectedTrail = trails.first { $0.id == selectedTrailId }
    }
    
    // MARK: - Load Data
    func loadData(from file: String) -> Data {
        let url = Bundle.main.url(forResource: file, withExtension: "")!
        return try! Data(contentsOf: url)
    }
    
    func decodeJSON<T: Decodable>(data: Data) -> T {
        try! JSONDecoder().decode(T.self, from: data)
    }
    
    func loadJSON<T: Decodable>(from file: String) -> T {
        let data = loadData(from: file)
        return decodeJSON(data: data)
    }
    
    func loadData() {
        let trailsMetadata: [TrailMetadata] = loadJSON(from: "Metadata.json")
        
        for metadata in trailsMetadata {
            let geojsonData = loadData(from: "\(metadata.name).geojson")
            let features = try! MKGeoJSONDecoder().decode(geojsonData) as! [MKGeoJSONFeature]
            let polyline = features.first?.geometry.first as! MKPolyline
            let trail = Trail(metadata: metadata, polyline: polyline)
            trails.append(trail)
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
    
    func loadElevationProfile(trail: Trail) {
        let collection: FeatureCollection = loadJSON(from: "\(trail.name).geojson")
        let geometry = collection.features.first!.geometry!
        switch geometry {
        case .lineString(let lineString):
            let maxPoints = 200
            let n = max(1, Int(lineString.coordinates.count / maxPoints))
            let locations = lineString.coordinates.map(\.location).enumerated().compactMap { index, element in index % n == 0 ? element : nil }
            trail.elevationProfile = getElevationProfile(locations: locations, distance: trail.metres)
        default: return
        }
    }
    
    func getElevationProfile(locations: [CLLocation], distance: Double) -> ElevationProfile? {
        guard locations.isNotEmpty else { return nil }
        let points = locations.enumerated().map { index, location in
            CGPoint(x: distance * (Double(index) / Double(locations.count)), y: locations[index].altitude)
        }
        let minElevation = points.map(\.y).min()!
        let shift = CGAffineTransform(translationX: 0, y: -minElevation)
        let maxElevation = points.map(\.y).max()! - minElevation
        let scale = CGAffineTransform(scaleX: 1/distance, y: 1/maxElevation)
        let normalised = points.map { $0.applying(shift).applying(scale) }
        return ElevationProfile(points: normalised, locations: locations, maxElevation: maxElevation, minElevation: minElevation, distance: distance)
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
    
    func selectTrail(_ trail: Trail?, animated: Bool = true) {
        selectedTrail = trail
        refreshOverlays()
        if let trail {
            loadElevationProfile(trail: trail)
            stopEditing(animated: animated)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.zoomTo(trail, animated: animated)
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
            return searching && filter
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.setRect(self.filteredTrails.rect, animated: animated)
            }
        }
    }
}

// MARK: - Map
extension ViewModel {
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
        guard let mapView else { return }
        mapView.removeOverlays(trails)
        mapView.removeOverlays(trailsTrips)
        if let selectedTrail {
            mapView.addOverlay(selectedTrail, level: .aboveRoads)
            if let selectedTrips {
                mapView.addOverlay(selectedTrips, level: .aboveRoads)
            }
        } else {
            mapView.addOverlays(filteredTrails, level: .aboveRoads)
        }
        refreshSelectPolyline()
        refreshWaypoints()
    }
    
    func refreshWaypoints() {
        guard let mapView else { return }
        mapView.removeAnnotations(mapView.annotations.filter { $0 is Waypoint })
        if let selectedTrail {
            var waypoints = Set<CLLocationCoordinate2D>()
            addWaypoints(of: selectedTrail.polyline, to: &waypoints)
            if let selectedTrips {
                selectedTrips.multiPolyline.polylines.forEach { polyline in
                    addWaypoints(of: polyline, to: &waypoints)
                }
            }
            annotationAddedDate = .now
            mapView.addAnnotations(waypoints.map(Waypoint.init))
        }
    }
    
    func addWaypoints(of polyline: MKPolyline, to waypoints: inout Set<CLLocationCoordinate2D>) {
        if let coord = polyline.coordinates.first {
            waypoints.insert(coord)
        }
        if let coord = polyline.coordinates.last {
            waypoints.insert(coord)
        }
    }
    
    func zoomTo(_ overlay: MKOverlay?, extraPadding: Bool = false, animated: Bool = true) {
        if let overlay {
            setRect(overlay.boundingMapRect, extraPadding: extraPadding, animated: animated)
        }
    }
    
    func setRect(_ rect: MKMapRect, extraPadding: Bool = false, animated: Bool = true) {
        guard let mapView else { return }
        let size = mapView.safeAreaLayoutGuide.layoutFrame.size
        let compact = isCompact(size)
        let bottom: CGFloat
        if isSelecting {
            bottom = selectBarSize.height - 10
        } else if !compact {
            bottom = 0
        } else if sheetDetent == .large {
            bottom = mediumDetentHeight
        } else {
            bottom = getDetentHeight(size, detent: sheetDetent)
        }
        let left = compact || isSelecting ? 0.0 : getHorizontalSheetPadding(size) + regularSheetWidth
        let padding = extraPadding ? 40.0 : 20.0
        let insets = UIEdgeInsets(top: padding, left: padding + left, bottom: padding + bottom, right: padding)
        mapView.setVisibleMapRect(rect, edgePadding: insets, animated: animated)
    }
    
    func reverseGeocode(coord: CLLocationCoordinate2D, completion: @escaping (CLPlacemark) -> Void) {
        CLGeocoder().reverseGeocodeLocation(coord.location) { placemarks, error in
            if let error, MKError(_nsError: error as NSError).code == MKError.serverFailure {
                self.showWiFiAlert = true
            } else if let placemark = placemarks?.first {
                completion(placemark)
            }
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
    func startSelecting() {
        isSelecting = true
    }
    
    func resetSelecting() {
        selectError = false
        removeSelectPins()
        removeSelectPolyline()
    }
    
    func stopSelecting() {
        resetSelecting()
        isSelecting = false
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
    
    func newSelectCoord(coord: CLLocationCoordinate2D) {
        guard Date.now.timeIntervalSince(annotationAddedDate) > 0.5 else { return }
        reverseGeocode(coord: coord) { placemark in
            self.newSelectPin(annotation: Annotation(type: .select, placemark: placemark))
        }
    }
    
    func newSelectPin(annotation: Annotation) {
        if startPin == nil {
            startPin = annotation
        } else if endPin == nil {
            endPin = annotation
        } else {
            return
        }
        annotationAddedDate = .now
        mapView?.addAnnotation(annotation)
        
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
        refreshWaypoints()
        
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
            newSelectCoord(coord: coord)
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
            renderer.strokeColor = trailOverlayColor
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
    
    func getShareMenu(mapItem: MKMapItem?, coord: CLLocationCoordinate2D, allowsDirections: Bool) -> UIButton {
        let options = getButton(systemName: "ellipsis.circle")
        var children = [UIMenuElement]()
        if allowsDirections {
            children.append(UIAction(title: "Get Directions", image: UIImage(systemName: "arrow.triangle.turn.up.right.diamond")) { _ in
                self.openInMaps(mapItem: mapItem, coord: coord, directions: true)
            })
        }
        children.append(UIAction(title: "Open in Maps", image: UIImage(systemName: "map")) { _ in
            self.openInMaps(mapItem: mapItem, coord: coord, directions: false)
        })
        children.append(UIAction(title: "Share...", image: UIImage(systemName: "square.and.arrow.up")) { _ in
            self.shareCoord(coord)
        })
        options.menu = UIMenu(children: children)
        options.showsMenuAsPrimaryAction = true
        return options
    }
    
    func openInMaps(mapItem: MKMapItem?, coord: CLLocationCoordinate2D, directions: Bool) {
        if let mapItem {
            openInMaps(mapItem: mapItem, directions: directions)
        } else {
            reverseGeocode(coord: coord) { placemark in
                let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
                self.openInMaps(mapItem: mapItem, directions: directions)
            }
        }
    }
    
    func openInMaps(mapItem: MKMapItem, directions: Bool) {
        mapItem.openInMaps(launchOptions: directions ? [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault] : nil)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? Annotation {
            let removeButton = getButton(systemName: "xmark")
            let shareMenu = getShareMenu(mapItem: annotation.mapItem, coord: annotation.coordinate, allowsDirections: true)
            switch annotation.type {
            case .select:
                let pin = mapView.dequeueReusableAnnotationView(withIdentifier: MKPinAnnotationView.id, for: annotation) as? MKPinAnnotationView
                pin?.displayPriority = .required
                pin?.animatesDrop = true
                pin?.canShowCallout = true
                pin?.pinTintColor = UIColor(.orange)
                pin?.rightCalloutAccessoryView = shareMenu
                pin?.leftCalloutAccessoryView = removeButton
                return pin
            case .drop:
                let marker = mapView.dequeueReusableAnnotationView(withIdentifier: MKMarkerAnnotationView.id, for: annotation) as? MKMarkerAnnotationView
                marker?.displayPriority = .required
                marker?.animatesWhenAdded = true
                marker?.canShowCallout = true
                marker?.rightCalloutAccessoryView = shareMenu
                marker?.leftCalloutAccessoryView = removeButton
                return marker
            }
        } else if let waypoint = annotation as? Waypoint {
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: WaypointView.id, for: annotation) as? WaypointView
            view?.vm = self
            view?.canShowCallout = true
            view?.rightCalloutAccessoryView = getShareMenu(mapItem: nil, coord: waypoint.coordinate, allowsDirections: true)
            return view
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        if let view = mapView.view(for: mapView.userLocation),
           let user = view.annotation {
            view.rightCalloutAccessoryView = getShareMenu(mapItem: nil, coord: user.coordinate, allowsDirections: false)
        }
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
        }
    }
    
    func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        if !animated {
            updateTrackingMode(.none)
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else { return }
        annotationSelected = true
        if isSelecting && selectPolyline == nil {
            mapView.deselectAnnotation(annotation, animated: false)
            newSelectCoord(coord: annotation.coordinate)
        }
        if Date.now.timeIntervalSince(annotationAddedDate) < 0.5 {
            mapView.deselectAnnotation(annotation, animated: false)
        }
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        annotationSelected = false
    }
}

// MARK: - UISearchBarDelegate
extension ViewModel: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        zoomToFilteredTrails()
        stopEditing()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        stopSearching()
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
        isEditing = true
        searchBar?.becomeFirstResponder()
        searchBar?.setShowsCancelButton(true, animated: true)
        withAnimation(.sheet) {
            isSearching = true
            sheetDetent = .large
        }
    }
    
    func stopEditing(animated: Bool = true) {
        isEditing = false
        searchBar?.resignFirstResponder()
        if let cancelButton = searchBar?.value(forKey: "cancelButton") as? UIButton {
            cancelButton.isEnabled = true
        }
        if animated {
            withAnimation(.sheet) {
                sheetDetent = .medium
            }
        } else {
            sheetDetent = .medium
        }
    }
    
    func stopSearching() {
        searchText = ""
        stopEditing()
        searchBar?.setShowsCancelButton(false, animated: false)
        withAnimation(.sheet) {
            isSearching = false
        }
    }
}
