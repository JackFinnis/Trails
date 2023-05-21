//
//  Sheet.swift
//  Trails
//
//  Created by Jack Finnis on 18/04/2023.
//

import SwiftUI
import MapKit

struct Sheet<Content: View, Header: View>: View {
    @EnvironmentObject var vm: ViewModel
    @State var headerHeight = CGFloat.zero
    
    @ViewBuilder let content: () -> Content
    @ViewBuilder let header: () -> Header
    
    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height
            let medium = height * 3/5
            let bottom = height - headerHeight
            let detents = vm.isEditing ? [0] : [0, medium, bottom]
            
            VStack(spacing: 0) {
                DraggableBar()
                    .padding(.top, 5)
                    .padding(.bottom, 7)
                
                header()
                    .padding(.horizontal)
                    .padding(.bottom, 17)
                    .overlay {
                        GeometryReader { headerGeo in
                            Color.clear.task {
                                headerHeight = headerGeo.size.height + 17
                                vm.snapOffset = [0, medium, geo.size.height - headerHeight].min { $0.distance(to: vm.snapOffset).magnitude < $1.distance(to: vm.snapOffset).magnitude }!
                            }
                        }
                    }
                
                content()
                    .opacity((bottom - (vm.snapOffset + vm.dragOffset))/50.0)
                
                Spacer(minLength: 0)
                    .layoutPriority(-1)
            }
            .blurBackground(thick: false)
            .offset(x: 0, y: vm.snapOffset + vm.dragOffset)
            .gesture(DragGesture(minimumDistance: 1)
                .onChanged { value in
                    let end = vm.snapOffset + value.translation.height
                    if end < 0 {
                        vm.dragOffset = -vm.snapOffset - sqrt(-end)
                    } else if vm.isEditing {
                        vm.dragOffset = vm.snapOffset + sqrt(end)
                    } else if end > bottom {
                        vm.dragOffset = bottom - vm.snapOffset + sqrt(end - bottom)
                    } else {
                        vm.dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    let end = vm.snapOffset + value.predictedEndTranslation.height
                    withAnimation(.sheet) {
                        vm.snapOffset = detents.min { $0.distance(to: end).magnitude < $1.distance(to: end).magnitude }!
                        vm.dragOffset = 0
                    }
                }
            )
        }
        .padding(.top, 20)
        .transition(.move(edge: .bottom))
    }
}

struct Sheet_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Map(mapRect: .constant(.world))
                .ignoresSafeArea()
            Sheet {} header: {}
        }
        .environmentObject(ViewModel())
    }
}
