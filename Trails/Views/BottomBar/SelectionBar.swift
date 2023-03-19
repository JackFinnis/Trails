//
//  SelectionInfo.swift
//  Trails
//
//  Created by Jack Finnis on 19/02/2023.
//

import SwiftUI
import MapKit

struct SelectionBar: View {
    @EnvironmentObject var vm: ViewModel
    @AppStorage("metric") var metric = true
    @AppStorage("speed") var speed = 4000.0
    
    let polyline: MKPolyline
    
    var body: some View {
        HStack(spacing: 0) {
            DistanceLabel(metres: vm.selectMetres)
                .font(.headline)
            Text(" • ")
            Menu {
                Picker("Speed", selection: $speed) {
                    if metric {
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
                Text((vm.selectMetres / (speed / 3600)).formattedInterval())
                    .font(.headline)
            }
            
            Spacer()
            HStack(spacing: 15) {
                Button {
                    vm.completeSelectPolyline()
                } label: {
                    Image(systemName: "checkmark.circle")
                        .font(.title2)
                }
                Button {
                    vm.stopSelecting()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                }
            }
        }
        .padding(10)
        .padding(.trailing, 5)
        .frame(height: SIZE)
        .onTapGesture {
            vm.zoomTo(polyline)
        }
    }
}

struct SelectionBar_Previews: PreviewProvider {
    static var previews: some View {
        SelectionBar(polyline: MKPolyline())
    }
}
