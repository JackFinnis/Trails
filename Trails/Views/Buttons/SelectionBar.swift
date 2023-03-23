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
        guard vm.selectPins.count == 2 else { return "" }
        let start = vm.selectPins[0]
        let end = vm.selectPins[1]
        return (start.placemark.subLocality ?? start.placemark.name ?? "") + " to " + (end.placemark.subLocality ?? end.placemark.name ?? "")
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 0) {
                    Text(vm.formatMiles(vm.selectMetres, showUnit: true, round: false) + " • ")
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
                        Text("Speed")
                    } label: {
                        Text((vm.selectMetres / (speed / 3600)).formattedInterval)
                    }
                    .animation(.none)
                    .onTapGesture {
                        tappedMenu = .now
                    }
                }
                .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            HStack(spacing: 15) {
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
                            Label("Remove from Completed", systemImage: "xmark")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .iconFont()
                }
                .onTapGesture {
                    tappedMenu = .now
                }
                
                Button {
                    vm.stopSelecting()
                } label: {
                    Image(systemName: "xmark")
                        .iconFont()
                }
            }
        }
        .padding(10)
        .padding(.trailing, 5)
        .contentShape(Rectangle())
        .onTapGesture {
            guard tappedMenu.distance(to: .now) > 1 else { return }
            vm.zoomTo(polyline, extraPadding: true)
        }
    }
}

struct SelectionBar_Previews: PreviewProvider {
    static var previews: some View {
        SelectionBar(polyline: MKPolyline())
    }
}
