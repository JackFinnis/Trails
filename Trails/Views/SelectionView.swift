//
//  SelectionInfo.swift
//  Trails
//
//  Created by Jack Finnis on 19/02/2023.
//

import SwiftUI
import MapKit
import CoreLocation

struct SelectionView: View {
    struct Header: View {
        @EnvironmentObject var vm: ViewModel
        
        let profile: ElevationProfile
        
        var title: String {
            guard let startPin = vm.startPin, let endPin = vm.endPin else { return "" }
            let start = startPin.name
            let end = endPin.name
            if start.isEmpty && end.isEmpty { return vm.selectedTrail?.name ?? "" }
            if start.isEmpty { return end }
            if end.isEmpty { return start }
            if start == end { return start }
            return start + " to " + end
        }
        
        var body: some View {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.title2.weight(.semibold))
                Spacer()
                Button {
                    vm.stopSelecting()
                } label: {
                    DismissCross(toolbar: false)
                }
                .buttonStyle(.plain)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                vm.zoomTo(profile.polyline, extraPadding: true)
            }
        }
    }
    
    @EnvironmentObject var vm: ViewModel
    @AppStorage("speed") var speed = 4000.0
    
    let profile: ElevationProfile
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.leading)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 15) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            let divider = Divider().frame(height: 20)
                            SheetStat(name: "Distance", value: vm.formatDistance(profile.distance, unit: true, round: false), systemName: "point.topleft.down.curvedto.point.bottomright.up.fill")
                            divider
                            Menu {
                                Picker("", selection: $speed) {
                                    if vm.metric {
                                        ForEach([3.0, 3.5, 4.0, 4.5, 5.0], id: \.self) { kmh in
                                            Text(String(format: "%.1f", kmh) + " kmh")
                                                .tag(kmh * 1000)
                                        }
                                    } else {
                                        ForEach([1.9, 2.2, 2.5, 2.8, 3.1], id: \.self) { mph in
                                            Text(String(format: "%.1f", mph) + " mph")
                                                .tag(mph * 1609.34)
                                        }
                                    }
                                }
                            } label: {
                                SheetStat(name: "Duration", value: (max(1, profile.distance / (speed / 3600))).formattedInterval(), systemName: "clock")
                            }
                            divider
                            SheetStat(name: "Ascent", value: vm.formatDistance(profile.ascent, unit: true, round: false), systemName: "arrow.up")
                            divider
                            SheetStat(name: "Descent", value: vm.formatDistance(profile.descent, unit: true, round: false), systemName: "arrow.down")
                        }
                        .padding(.horizontal)
                    }
                    
                    ElevationChart(profile: profile)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Waypoints")
                            .font(.headline)
                        VStack(spacing: 0) {
                            if let start = vm.startPin {
                                WaypointButton(annotation: start, type: .start)
                            }
                            Divider()
                                .padding(.leading, 15)
                            if let end = vm.endPin {
                                WaypointButton(annotation: end, type: .end)
                            }
                        }
                        .continuousRadius(10)
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 10) {
                        Button {
                            vm.reverseSelection()
                        } label: {
                            SelectionViewButton(title: "Reverse Selection", systemName: "arrow.left.arrow.right")
                        }
                        if vm.canComplete {
                            Button {
                                vm.completeSelectPolyline()
                            } label: {
                                SelectionViewButton(title: "Mark as Completed", systemName: "checkmark.circle")
                            }
                        }
                        if vm.canUncomplete {
                            Button(role: .destructive) {
                                vm.uncompleteSelectPolyline()
                            } label: {
                                SelectionViewButton(title: "Remove from Completed", systemName: "minus.circle")
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .contentShape(Rectangle())
                .onTapGesture {}
            }
        }
    }
}

struct SelectionView_Previews: PreviewProvider {
    static var previews: some View {
        SelectionView(profile: .example)
            .environmentObject(ViewModel())
    }
}

struct SelectionViewButton: View {
    let title: String
    let systemName: String
    
    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: systemName)
                .squareButton()
            Text(title)
            Spacer(minLength: 0)
        }
        .containerBackground(light: false)
        .continuousRadius(10)
    }
}

struct WaypointButton: View {
    @EnvironmentObject var vm: ViewModel
    
    let annotation: Annotation
    let type: WaypointType
    
    var body: some View {
        Button {
            vm.mapView?.selectAnnotation(annotation, animated: true)
            vm.ensureMapVisible()
        } label: {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(type.rawValue)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    if let address = annotation.mapItem.placemark.postalAddress {
                        Text(address.formatted())
                            .multilineTextAlignment(.leading)
                            .font(.subheadline)
                    }
                }
                .foregroundColor(.primary)
                Spacer(minLength: 0)
                Image(systemName: "map")
                    .font(.icon)
                    .padding(.top, 5)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 15)
            .containerBackground(light: true)
        }
    }
}