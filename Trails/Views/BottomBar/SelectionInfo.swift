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
    
    let polyline: MKPolyline
    
    var body: some View {
        HStack(spacing: 0) {
            DistanceLabel(metres: vm.selectMetres)
                .font(.headline)
            Spacer(minLength: 0)
            
            Menu {
                Picker("Speed", selection: $vm.speed) {
                    ForEach([3.0, 3.5, 4.0, 4.5, 5.0], id: \.self) { speed in
                        Text("\(speed) kmh")
                    }
                }
            } label: {
                Text((vm.selectMetres / vm.speed).formattedInterval())
                    .font(.headline)
            }
            
            Button {
                vm.completeSelectPolyline()
            } label: {
                Image(systemName: "checkmark.circle")
                    .frame(width: SIZE, height: SIZE)
            }
            Divider().frame(height: SIZE)
            
            Button {
                vm.stopSelecting()
            } label: {
                Image(systemName: "xmark")
                    .frame(width: SIZE, height: SIZE)
            }
        }
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
