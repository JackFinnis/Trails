//
//  ActionButtons.swift
//  Trails
//
//  Created by Jack Finnis on 19/02/2023.
//

import SwiftUI
import MapKit

struct ActionButtons: View {
    @EnvironmentObject var vm: ViewModel
    @State var showTrailsView = false
    
    var body: some View {
        HStack {
            HStack(spacing: 0) {
                Button {
                    updateMapType()
                } label: {
                    Image(systemName: mapTypeImage)
                        .squareButton()
                        .rotation3DEffect(.degrees(vm.mapType == .standard ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                        .rotation3DEffect(.degrees(vm.degrees), axis: (x: 0, y: 1, z: 0))
                }
                
                Divider().frame(height: SIZE)
                Button {
                    updateTrackingMode()
                } label: {
                    Image(systemName: trackingModeImage)
                        .scaleEffect(vm.scale)
                        .squareButton()
                }
            }
            .materialBackground()
            
            Spacer()
            HStack(spacing: 0) {
                Button {
                    vm.isSearching = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .squareButton()
                }
                
                Divider().frame(height: SIZE)
                Button {
                    showTrailsView = true
                } label: {
                    Image(systemName: "list.bullet")
                        .squareButton()
                }
                .sheet(isPresented: $showTrailsView) {
                    TrailsView(showTrailsView: $showTrailsView)
                }
            }
            .materialBackground()
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
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

struct ActionButtons_Previews: PreviewProvider {
    static var previews: some View {
        ActionButtons()
    }
}
