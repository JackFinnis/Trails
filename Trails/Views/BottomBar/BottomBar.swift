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
    @State var offset = 0.0
    
    var body: some View {
        VStack(spacing: 10) {
            if let trail = vm.selectedTrail {
                TrailRow(showTrailsView: .constant(false), trail: trail, list: false)
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
                .offset(x: 0, y: offset)
                .opacity((100 - offset)/100)
                .gesture(DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 {
                            offset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.predictedEndTranslation.height > 50 {
                            vm.stopSelecting()
                            vm.stopSearching()
                            offset = 0
                        } else {
                            withAnimation(.spring()) {
                                offset = 0
                            }
                        }
                    }
                )
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
