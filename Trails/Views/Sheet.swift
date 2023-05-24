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
                            .opacity(((geo.size.height - headerSize.height) - (vm.snapOffset + vm.dragOffset))/50.0)
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    Spacer(minLength: 0)
                        .frame(height: vm.safeAreaInset)
                }
                .opacity(vm.isSelecting ? 0 : 1)
                .offset(y: (vm.isSelecting ? vm.sheetHeight : 0) + vm.snapOffset + vm.dragOffset)
                .gesture(DragGesture(minimumDistance: 1)
                    .onChanged { gesture in
                        let end = vm.snapOffset + gesture.translation.height
                        let bottom = geo.size.height - headerSize.height
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
                        let height = geo.size.height
                        let detents = [(0, SheetDetent.large), (height - vm.mediumSheetHeight, .medium), (height - headerSize.height, .small)]
                        let closest = detents.min { $0.0.distance(to: end).magnitude < $1.0.distance(to: end).magnitude }!.1
                        vm.sheetDetent = vm.isEditing ? .large : closest
                    }
                )
                .onReceive(vm.$sheetDetent) { detent in
                    withAnimation(vm.animateDetentChange ? .sheet : .none) {
                        let height = geo.size.height
                        let detents = [(0, SheetDetent.large), (height - vm.mediumSheetHeight, .medium), (height - headerSize.height, .small)]
                        vm.snapOffset = detents.first { $0.1 == detent }!.0
                        vm.dragOffset = 0
                    }
                }
            }
            .frame(maxWidth: vm.maxWidth)
            Spacer(minLength: 0)
        }
        .padding(.top, vm.topPadding)
        .padding(.horizontal, vm.horizontalPadding)
        .transition(.move(edge: .bottom))
    }
}
