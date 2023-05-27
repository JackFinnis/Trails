//
//  LineChart.swift
//  Trails
//
//  Created by Jack Finnis on 24/05/2023.
//

import SwiftUI
import MapKit

struct ElevationChart: View {
    @EnvironmentObject var vm: ViewModel
    @State var userPoint: CGPoint?
    
    let profile: ElevationProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Elevation")
                .font(.headline)
                .padding(.leading, 5)
            HStack(alignment: .top) {
                VStack(alignment: .trailing) {
                    Text(String(Int(profile.maxElevation)) + " m")
                    Spacer()
                    Text(String(Int(profile.minElevation)) + " m")
                }
                .frame(height: 100)
                VStack(alignment: .trailing) {
                    GeometryReader { geo in
                        let translation = CGAffineTransform(translationX: 0, y: -1)
                        let scale = CGAffineTransform(scaleX: geo.size.width, y: -geo.size.height)
                        let transform = translation.concatenating(scale)
                        Path { path in
                            path.move(to: profile.points.first!)
                            profile.points.forEach {
                                path.addLine(to: $0)
                            }
                        }
                        .transform(transform)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .overlay {
                            if let userPoint {
                                Menu {
                                    let elevation = profile.getElevation(of: userPoint)
                                    let distance = vm.formatDistance(profile.getDistance(of: userPoint), unit: true, round: false)
                                    Text("My Location\n\(distance) • \(Int(elevation)) m")
                                } label: {
                                    Circle().fill(Color.orange)
                                        .frame(width: 10, height: 10)
                                        .frame(width: 30, height: 30)
                                }
                                .position(userPoint.applying(transform))
                            }
                        }
                    }
                    .padding(1)
                    .frame(height: 100)
                    .background(alignment: .leading) {
                        Capsule().fill(Color(.separator))
                            .frame(width: 1)
                    }
                    .background(alignment: .bottom) {
                        Capsule().fill(Color(.separator))
                            .frame(height: 1)
                            .padding(.leading, 1)
                    }
                    HStack {
                        Text("0 km")
                        Spacer()
                        Text(vm.formatDistance(profile.distance, unit: true, round: false))
                    }
                }
            }
            .foregroundColor(.secondary)
            .font(.caption2.bold())
            .padding(10)
            .containerBackground(light: true)
            .continuousRadius(10)
        }
        .onAppear {
            guard let location = vm.locationManager.location,
                  profile.polyline.boundingMapRect.padded.contains(MKMapPoint(location.coordinate)),
                  let closest = profile.locations.min(by: { $0.distance(from: location) < $1.distance(from: location) }),
                  closest.distance(from: location) < 100,
                  let index = profile.locations.firstIndex(of: closest)
            else { return }
            userPoint = profile.points[safe: index]
        }
    }
}

struct ElevationProfile: Equatable {
    let points: [CGPoint]
    let locations: [CLLocation]
    let allLocations: [CLLocation]
    let maxElevation: Double
    let minElevation: Double
    let ascent: Double
    let descent: Double
    let distance: Double
    let polyline: MKPolyline
    
    func getElevation(of point: CGPoint) -> Double {
        point.y * (maxElevation - minElevation) + minElevation
    }
    
    func getDistance(of point: CGPoint) -> Double {
        point.x * distance
    }
    
    static let example = ElevationProfile(
        points: [CGPoint(x: 0.0, y: 0.0), CGPoint(x: 0.5, y: 1.0), CGPoint(x: 1.0, y: 0.5)],
        locations: [],
        allLocations: [],
        maxElevation: 500,
        minElevation: 200,
        ascent: 1000,
        descent: 900,
        distance: 10000,
        polyline: MKPolyline()
    )
}

extension ElevationProfile {
    init?(allLocations: [CLLocation], distance: Double, polyline: MKPolyline, ascent: Double, descent: Double) {
        guard allLocations.isNotEmpty else { return nil }
        
        let maxPoints = 200
        let n = max(1, Int(allLocations.count / maxPoints))
        let locations = allLocations.every(n)
        
        let count = Double(locations.count - 1)
        let points = locations.enumerated().map { index, location in
            CGPoint(x: distance * (Double(index) / count), y: locations[index].altitude)
        }
        let minElevation = points.map(\.y).min()!
        let maxElevation = points.map(\.y).max()!
        let shift = CGAffineTransform(translationX: 0, y: -minElevation)
        let scale = CGAffineTransform(scaleX: 1/distance, y: 1/(maxElevation - minElevation))
        let normalised = points.map { $0.applying(shift).applying(scale) }
        self.init(points: normalised, locations: locations, allLocations: allLocations, maxElevation: maxElevation, minElevation: minElevation, ascent: ascent, descent: descent, distance: distance, polyline: polyline)
    }
}
