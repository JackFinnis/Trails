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
    
    func stat(key: String, value: String, icon: String, tint: Color = .secondary) -> some View {
        VStack(alignment: .leading) {
            Text(key)
                .textCase(.uppercase)
                .foregroundColor(.secondary)
                .font(.caption2.weight(.bold))
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.footnote.weight(.bold))
                    .foregroundColor(tint)
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
            }
        }
    }
    
    func button(title: String, icon: String, geo: GeometryProxy) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.headline)
            Text(title)
                .font(.footnote.bold())
        }
        .frame(width: (geo.size.width - 30)/4, height: geo.size.height)
        .background(Color(.secondarySystemFill))
        .continuousRadius(10)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(trail.headline)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    let divider = Divider().frame(height: 20)
                    stat(key: "Distance", value: vm.formatDistance(trail.metres, showUnit: true, round: true), icon: "point.topleft.down.curvedto.point.bottomright.up.fill")
                    divider
                    stat(key: "Duration", value: "\(trail.days) days", icon: "clock")
                    if let ascent = trail.ascent {
                        divider
                        stat(key: "Ascent", value: vm.formatDistance(ascent, showUnit: true, round: false), icon: "arrow.up")
                    }
                    if let metres = vm.getTrips(trail: trail)?.metres, metres > 0 {
                        divider
                        let complete = Int(trail.metres / metres * 100)
                        let completed = vm.isCompleted(trail)
                        stat(key: "Completed", value: "\(complete)%", icon: completed ? "checkmark.circle.fill" : "checkmark.circle", tint: completed ? .accentColor : .secondary)
                    }
                }
                .padding(.horizontal)
            }
            
            GeometryReader { geo in
                HStack(spacing: 10) {
                    Button {
                        vm.toggleFavourite(trail)
                    } label: {
                        let favourite = vm.isFavourite(trail)
                        button(title: favourite ? "Unfavourite" : "Favourite", icon: favourite ? "star.slash.fill" : "star", geo: geo)
                    }
                    Button {
                        vm.startSelecting()
                    } label: {
                        button(title: "Select", icon: "point.topleft.down.curvedto.point.bottomright.up", geo: geo)
                    }
                    Button {
                        vm.zoomTo(trail)
                    } label: {
                        button(title: "Zoom", icon: "arrow.up.left.and.arrow.down.right", geo: geo)
                    }
                    Button {
                        showWebView = true
                    } label: {
                        button(title: "Website", icon: "safari", geo: geo)
                    }
                }
                .font(.subheadline.bold())
            }
            .frame(height: 60)
            .padding(.horizontal)
            
            TrailImage(trail: trail)
                .continuousRadius(10)
                .padding(.horizontal)
        }
        .padding(.bottom)
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
