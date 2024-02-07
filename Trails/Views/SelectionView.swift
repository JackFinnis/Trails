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
                    DismissCross()
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
                                Picker("", selection: $vm.speedMetres) {
                                    let system = vm.measurementSystem
                                    ForEach(system.speeds, id: \.self) { speed in
                                        Text(system.formatSpeed(speed))
                                            .tag(speed * system.metres)
                                    }
                                    let speed = vm.speedMetres / system.metres
                                    if !system.speeds.contains(speed) {
                                        Text(system.formatSpeed(speed, decimalPlaces: 2))
                                            .tag(vm.speedMetres)
                                    }
                                }
                                Button {
                                    withAnimation {
                                        vm.showSpeedInput = true
                                    }
                                } label: {
                                    Label("Custom Speed", systemImage: "pencil")
                                }
                            } label: {
                                let duration = (max(1, profile.distance / (vm.speedMetres / 3600))).formattedInterval()
                                SheetStat(name: "Duration", value: duration, systemName: "clock")
                            }
                            divider
                            SheetStat(name: "Ascent", value: vm.formatDistance(profile.ascent, unit: true, round: false), systemName: "arrow.up.forward")
                            divider
                            SheetStat(name: "Descent", value: vm.formatDistance(profile.descent, unit: true, round: false), systemName: "arrow.down.forward")
                        }
                        .padding(.horizontal)
                    }
                    
                    ElevationChart(profile: profile)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Waypoints")
                            .font(.headline)
                        VStack(spacing: 0) {
                            if let start = vm.startPin,
                               let address = start.mapItem.placemark.postalAddress {
                                WaypointButton(annotation: start, title: address.formatted(), type: .start)
                            }
                            Divider()
                                .padding(.leading, 15)
                            if let end = vm.endPin,
                               let address = end.mapItem.placemark.postalAddress {
                                WaypointButton(annotation: end, title: address.formatted(), type: .end)
                            }
                        }
                        .continuousRadius(10)
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 10) {
                        Button {
                            vm.reverseSelection()
                        } label: {
                            SheetButton(title: "Reverse Selection", systemName: "arrow.left.arrow.right")
                        }
                        if vm.canComplete {
                            Button {
                                vm.completeSelectPolyline()
                            } label: {
                                SheetButton(title: "Mark as Completed", systemName: "checkmark.circle")
                            }
                        }
                        if vm.canUncomplete {
                            Button(role: .destructive) {
                                vm.uncompleteSelectPolyline()
                            } label: {
                                SheetButton(title: "Remove from Completed", systemName: "minus.circle")
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
