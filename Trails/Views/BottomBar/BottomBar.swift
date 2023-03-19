//
//  FloatingButtons.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI
import MapKit

struct BottomBar: View {
    @EnvironmentObject var vm: ViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            if let trail = vm.selectedTrail {
                TrailRow(showTrailsView: .constant(false), trail: trail, list: false)
                    .materialBackground()
                    .dismissable(edge: .top) {
                        vm.deselectTrail()
                    }
            }
            Spacer()
            if vm.isSelecting || vm.isSearching {
                Group {
                    if let polyline = vm.selectPolyline {
                        SelectionBar(polyline: polyline)
                    } else if vm.isSelecting {
                        SelectBar()
                    } else if vm.isSearching {
                        SearchBar()
                    }
                }
                .materialBackground()
                .frame(maxWidth: 500)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .offset(x: vm.noResults ? 20 : 0, y: 0)
                .dismissable(edge: .bottom) {
                    vm.stopSelecting()
                    vm.stopSearching()
                }
            } else {
                ActionButtons()
            }
        }
        .animation(.default, value: vm.isSearching)
        .animation(.default, value: vm.isSelecting)
        .animation(.default, value: vm.selectedTrail)
        .padding(10)
    }
}

struct BottomBar_Previews: PreviewProvider {
    static var previews: some View {
        BottomBar()
            .environmentObject(ViewModel())
    }
}
