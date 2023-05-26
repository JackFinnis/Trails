//
//  SelectionInfo.swift
//  Trails
//
//  Created by Jack Finnis on 19/02/2023.
//

import SwiftUI
import MapKit
import CoreLocation

struct SelectionBar: View {
    @EnvironmentObject var vm: ViewModel
    @AppStorage("speed") var speed = 4000.0
    @State var tappedMenu = Date.now
    
    let polyline: MKPolyline
    
    var description: String {
        guard let startPin = vm.startPin, let endPin = vm.endPin else { return "" }
        let start = startPin.title ?? startPin.subtitle ?? ""
        let end = endPin.title ?? endPin.subtitle ?? ""
        if start.isEmpty { return end }
        if end.isEmpty { return start }
        if start == end { return start }
        return start + " to " + end
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 0) {
                    Text(vm.formatDistance(vm.selectMetres, showUnit: true, round: false) + " • ")
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
                        Text((vm.selectMetres / (speed / 3600)).formattedInterval)
                    }
                    .onTapGesture {
                        tappedMenu = .now
                    }
                }
                .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
            Menu {
                if vm.canComplete {
                    Button {
                        vm.completeSelectPolyline()
                    } label: {
                        Label("Mark as Completed", systemImage: "checkmark.circle")
                    }
                }
                if vm.canUncomplete {
                    Button(role: .destructive) {
                        vm.uncompleteSelectPolyline()
                    } label: {
                        Label("Remove from Completed", systemImage: "minus.circle")
                    }
                }
                Divider()
                Button(role: .destructive) {
                    vm.stopSelecting()
                } label: {
                    Label("Stop Selecting", systemImage: "xmark")
                }
                Button {
                    vm.resetSelecting()
                } label: {
                    Label("Select New Section", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.icon)
            }
            .onTapGesture {
                tappedMenu = .now
            }
            .padding(.horizontal, 5)
        }
        .padding(10)
        .blurBackground(prominentShadow: true)
        .onTapGesture {
            guard tappedMenu.distance(to: .now) > 1 else { return }
            vm.zoomTo(polyline, extraPadding: true)
        }
        .onDismiss {
            vm.resetSelecting()
        }
        .padding(10)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

struct SelectionBar_Previews: PreviewProvider {
    static var previews: some View {
        SelectionBar(polyline: MKPolyline())
    }
}
