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
                    .squareButton()
                    .rotation3DEffect(.degrees(vm.mapType == .standard ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                    .rotation3DEffect(.degrees(vm.degrees), axis: (x: 0, y: 1, z: 0))
            }
            
            Divider().frame(width: SIZE)
            Button {
                updateTrackingMode()
            } label: {
                Image(systemName: trackingModeImage)
                    .scaleEffect(vm.scale)
                    .squareButton()
            }
        }
        .blurBackground(opacity: 0.2)
        .padding(10)
        .transition(.opacity)
    }
    
    func updateTrackingMode() {
        var mode: MKUserTrackingMode {
            switch vm.trackingMode {
            case .none:
                return .follow
            case .follow:
                return .followWithHeading
            default:
                return .none
            }
        }
        vm.updateTrackingMode(mode)
    }
    
    func updateMapType() {
        var type: MKMapType {
            switch vm.mapType {
            case .standard:
                return .hybrid
            default:
                return .standard
            }
        }
        vm.updateMapType(type)
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
