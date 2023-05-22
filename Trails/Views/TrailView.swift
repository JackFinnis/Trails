//
//  TrailView.swift
//  Trails
//
//  Created by Jack Finnis on 18/04/2023.
//

import SwiftUI

struct TrailView: View {
    @EnvironmentObject var vm: ViewModel
    @State var showWebView = false
    
    let trail: Trail
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(trail.headline)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 10) {
                let divider = Divider().frame(height: 20)
                TrailViewStat(name: "Distance", value: vm.formatDistance(trail.metres, showUnit: true, round: true), systemName: "point.topleft.down.curvedto.point.bottomright.up.fill")
                divider
                TrailViewStat(name: "Duration", value: "\(trail.days) days", systemName: "clock")
                if let ascent = trail.ascent {
                    divider
                    TrailViewStat(name: "Ascent", value: vm.formatDistance(ascent, showUnit: true, round: false), systemName: "arrow.up")
                }
                if let metres = vm.getTrips(trail: trail)?.metres, metres > 0 {
                    divider
                    let complete = Int(trail.metres / metres * 100)
                    let completed = vm.isCompleted(trail)
                    TrailViewStat(name: "Completed", value: "\(complete)%", systemName: completed ? "checkmark.circle.fill" : "checkmark.circle", tint: completed ? .accentColor : .secondary)
                }
            }
            
            GeometryReader { geo in
                HStack(spacing: 10) {
                    Button {
                        vm.toggleFavourite(trail)
                    } label: {
                        let favourite = vm.isFavourite(trail)
                        TrailViewButton(title: favourite ? "Saved" : "Save", systemName: favourite ? "bookmark.fill" : "bookmark", geo: geo)
                    }
                    Button {
                        vm.startSelecting()
                    } label: {
                        TrailViewButton(title: "Select", systemName: "point.topleft.down.curvedto.point.bottomright.up", geo: geo)
                    }
                    Button {
                        guard vm.sheetDetent != .large else { return }
                        vm.zoomTo(trail)
                    } label: {
                        TrailViewButton(title: "Zoom", systemName: "arrow.up.left.and.arrow.down.right", geo: geo)
                    }
                    Button {
                        showWebView = true
                    } label: {
                        TrailViewButton(title: "Website", systemName: "safari", geo: geo)
                    }
                }
                .font(.subheadline.bold())
            }
            .frame(height: 60)
            
            TrailImage(trail: trail)
                .continuousRadius(10)
            Spacer()
        }
        .padding(.horizontal)
        .background {
            NavigationLink("", isActive: $showWebView) {
                WebView(webVM: WebVM(url: trail.url), trail: trail)
            }
            .hidden()
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
    let geo: GeometryProxy
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: systemName)
                .font(.body.weight(.medium))
            Text(title)
                .font(.footnote.bold())
        }
        .frame(width: (geo.size.width - 30)/4, height: geo.size.height)
        .background(Color(colorScheme == .light ? .tertiarySystemFill : .quaternarySystemFill))
        .continuousRadius(10)
    }
}

struct TrailViewStat: View {
    let name: String
    let value: String
    let systemName: String
    var tint: Color = .secondary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
                .textCase(.uppercase)
                .foregroundColor(.secondary)
                .font(.caption2.weight(.bold))
            HStack(spacing: 5) {
                Image(systemName: systemName)
                    .font(.footnote.weight(.bold))
                    .foregroundColor(tint)
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
            }
        }
    }
}
