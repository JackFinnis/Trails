//
//  Sheet.swift
//  Trails
//
//  Created by Jack Finnis on 18/04/2023.
//

import SwiftUI
import MapKit

enum SheetDetent {
    case large
    case medium
    case small
}

struct Sheet<Content: View, Header: View>: View {
    @EnvironmentObject var vm: ViewModel
    @State var headerSize = CGSize()
    
    @ViewBuilder let content: () -> Content
    @ViewBuilder let header: () -> Header
    
    var body: some View {
        HStack {
            GeometryReader { geo in
                let height = geo.size.height
                let medium = height - vm.mediumSheetHeight
                let bottom = height - headerSize.height
                let detents = [(0, SheetDetent.large), (medium, .medium), (bottom, .small)]
                
                ZStack(alignment: .top) {
                    RoundedCorners(radius: 10, corners: [.topLeft, .topRight])
                        .fill(.thickMaterial)
                        .ignoresSafeArea()
                        .shadow(color: Color.black.opacity(0.1), radius: 5)
                    
                    VStack(spacing: 0) {
                        VStack(spacing: 0) {
                            DraggableBar()
                                .padding(.top, 5)
                                .padding(.bottom, 7)
                            header()
                                .padding(.horizontal)
                                .padding(.bottom, 17)
                        }
                        .detectSize($headerSize)
                        
                        content()
                            .opacity((bottom - (vm.snapOffset + vm.dragOffset))/50.0)
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    Spacer(minLength: 0)
                        .frame(height: vm.safeAreaInset)
                }
                .offset(x: 0, y: vm.snapOffset + vm.dragOffset)
                .gesture(DragGesture(minimumDistance: 1)
                    .onChanged { gesture in
                        let end = vm.snapOffset + gesture.translation.height
                        if end < 0 {
                            vm.dragOffset = -vm.snapOffset - sqrt(-end)
                        } else if vm.isEditing {
                            vm.dragOffset = vm.snapOffset + sqrt(end)
                        } else if end > bottom {
                            vm.dragOffset = bottom - vm.snapOffset + sqrt(end - bottom)
                        } else {
                            vm.dragOffset = gesture.translation.height
                        }
                    }
                    .onEnded { gesture in
                        let end = vm.snapOffset + gesture.predictedEndTranslation.height
                        let closest = detents.min { $0.0.distance(to: end).magnitude < $1.0.distance(to: end).magnitude }!.1
                        vm.sheetDetent = vm.isEditing ? .large : closest
                    }
                )
                .onReceive(vm.$sheetDetent) { detent in
                    withAnimation(vm.animateDetentChange ? .sheet : .none) {
                        vm.dragOffset = 0
                        vm.snapOffset = detents.first { $0.1 == detent }!.0
                    }
                }
            }
            .frame(maxWidth: vm.compact ? .infinity : vm.regularWidth)
            Spacer(minLength: 0)
        }
        .padding(.top, vm.topPadding)
        .padding(.horizontal, vm.horizontalPadding)
        .transition(.move(edge: .bottom))
    }
}
