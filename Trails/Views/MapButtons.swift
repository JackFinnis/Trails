//
//  ActionButtons.swift
//  Trails
//
//  Created by Jack Finnis on 19/02/2023.
//

import SwiftUI
import MapKit

struct MapButtons: View {
    @EnvironmentObject var vm: ViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Button {
                updateMapType()
            } label: {
                Image(systemName: mapTypeImage)
                    .rotation3DEffect(.degrees(vm.mapType == .standard ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                    .rotation3DEffect(.degrees(vm.degrees), axis: (x: 0, y: 1, z: 0))
                    .squareButton()
            }
            
            Divider().frame(width: Constants.size)
            Button {
                updateTrackingMode()
            } label: {
                Image(systemName: trackingModeImage)
                    .scaleEffect(vm.scale)
                    .squareButton()
            }
        }
        .blurBackground(prominentShadow: true)
        .padding(10)
    }
    
    func updateTrackingMode() {
        let mode: MKUserTrackingMode
        switch vm.trackingMode {
        case .none:
            mode = .follow
        case .follow:
            mode = .followWithHeading
        default:
            mode = .none
        }
        vm.setTrackingMode(mode)
    }
    
    func updateMapType() {
        let type: MKMapType
        switch vm.mapType {
        case .standard:
            type = .hybrid
        default:
            type = .standard
        }
        vm.setMapType(type)
    }
    
    var trackingModeImage: String {
        switch vm.trackingMode {
        case .none:
            return "location"
        case .follow:
            return "location.fill"
        default:
            return "location.north.line.fill"
        }
    }
    
    var mapTypeImage: String {
        switch vm.mapType {
        case .standard:
            return "globe.europe.africa.fill"
        default:
            return "map"
        }
    }
}

struct MapButtons_Previews: PreviewProvider {
    static var previews: some View {
        MapButtons()
    }
}
