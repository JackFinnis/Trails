//
//  TrailView.swift
//  Trails
//
//  Created by Jack Finnis on 18/04/2023.
//

import SwiftUI

struct TrailView: View {
    struct Header: View {
        @EnvironmentObject var vm: ViewModel
        
        let trail: Trail
        
        var body: some View {
            HStack(alignment: .firstTextBaseline) {
                Text(trail.name)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.title2.weight(.semibold))
                Spacer()
                Button {
                    vm.selectTrail(nil)
                } label: {
                    DismissCross(toolbar: false)
                }
                .buttonStyle(.plain)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                vm.zoomTo(trail)
            }
        }
    }
    
    @EnvironmentObject var vm: ViewModel
    @State var showWebView = false
    
    let trail: Trail
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.leading)
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text(trail.headline)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            let divider = Divider().frame(height: 20)
                            SheetStat(name: "Distance", value: vm.formatDistance(trail.metres, unit: true, round: true), systemName: "point.topleft.down.curvedto.point.bottomright.up.fill")
                            if let metres = vm.getTrips(trail)?.metres, metres > 0 {
                                let percentageCompleted = Int(round((metres / trail.metres) * 100))
                                let completed = vm.isCompleted(trail)
                                let value = "\(completed ? "" : "\(vm.formatDistance(metres, unit: true, round: true)), ")\(percentageCompleted)%"
                                divider
                                SheetStat(name: "Completed", value: value, systemName: completed ? "checkmark.circle.fill" : "checkmark.circle", tint: completed ? .accentColor : .secondary)
                            }
                            divider
                            SheetStat(name: "Duration", value: "\(trail.days) days", systemName: "clock")
                            divider
                            SheetStat(name: "Ascent", value: vm.formatDistance(trail.ascent, unit: true, round: false), systemName: "arrow.up.forward")
                            divider
                            SheetStat(name: "Descent", value: vm.formatDistance(trail.descent, unit: true, round: false), systemName: "arrow.down.forward")
                            if trail.cycleway {
                                divider
                                SheetStat(name: "Cycleway", value: trail.cycleStatus.name, systemName: "bicycle")
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    GeometryReader { geo in
                        let width = max(0, (geo.size.width - 30)/4)
                        HStack(spacing: 10) {
                            Button {
                                vm.toggleFavourite(trail)
                            } label: {
                                let favourite = vm.isFavourite(trail)
                                TrailViewButton(title: favourite ? "Saved" : "Save", systemName: favourite ? "bookmark.fill" : "bookmark", width: width)
                            }
                            Button {
                                vm.startSelecting()
                            } label: {
                                TrailViewButton(title: "Select", systemName: "point.topleft.down.curvedto.point.bottomright.up", width: width)
                            }
                            Button {
                                vm.zoomTo(trail)
                            } label: {
                                TrailViewButton(title: "Zoom", systemName: "arrow.up.left.and.arrow.down.right", width: width)
                            }
                            Button {
                                showWebView = true
                            } label: {
                                TrailViewButton(title: "Website", systemName: "safari", width: width)
                            }
                        }
                        .font(.subheadline.bold())
                    }
                    .frame(height: 60)
                    .padding(.horizontal)
                    
                    TrailImage(trail: trail)
                        .continuousRadius(10)
                        .padding(.horizontal)
                    
                    if let profile = trail.elevationProfile {
                        ElevationChart(profile: profile)
                            .padding(.horizontal)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Waypoints")
                            .font(.headline)
                            .padding(.leading, 5)
                        VStack(spacing: 0) {
                            if let start = vm.startWaypoint {
                                WaypointButton(annotation: start, title: trail.start, type: .start)
                            }
                            Divider()
                                .padding(.leading, 15)
                            if let end = vm.endWaypoint {
                                WaypointButton(annotation: end, title: trail.end, type: .end)
                            }
                        }
                        .continuousRadius(10)
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 10) {
                        if !vm.isCompleted(trail) {
                            Button {
                                vm.completeTrail()
                            } label: {
                                SheetButton(title: "Mark Trail as Completed", systemName: "checkmark.circle")
                            }
                        } else {
                            Button(role: .destructive) {
                                vm.uncompleteTrail()
                            } label: {
                                SheetButton(title: "Remove All Completed Sections", systemName: "minus.circle")
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .contentShape(Rectangle())
                .onTapGesture {}
                .overlay {
                    NavigationLink("", isActive: $showWebView) {
                        WebView(webVM: WebVM(url: trail.url), trail: trail)
                    }
                    .hidden()
                }
            }
        }
    }
}

struct TrailView_Previews: PreviewProvider {
    static var previews: some View {
        TrailView(trail: .example)
            .environmentObject(ViewModel())
    }
}

struct TrailViewButton: View {
    @Environment(\.colorScheme) var colorScheme
    
    let title: String
    let systemName: String
    let width: CGFloat
    
    var body: some View {
        VStack(spacing: 2) {
            Spacer(minLength: 0)
            Image(systemName: systemName)
                .font(.body.weight(.medium))
            Text(title)
                .font(.footnote.bold())
            Spacer(minLength: 0)
        }
        .frame(width: width)
        .containerBackground(light: false)
        .continuousRadius(10)
    }
}
