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
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var vm: ViewModel
    @State var headerSize = CGSize()
    
    @ViewBuilder let content: () -> Content
    @ViewBuilder let header: () -> Header
    
    var body: some View {
        HStack {
            GeometryReader { geo in
                let height = geo.size.height
                let medium = height - 270
                let bottom = height - headerSize.height
                
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
                .safeAreaInset(edge: .bottom) {
                    Spacer(minLength: 0)
                        .frame(height: vm.snapOffset)
                }
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
                        if vm.isEditing {
                            setDetent(detent: .large, geo: geo)
                        } else {
                            let end = vm.snapOffset + value.predictedEndTranslation.height
                            let detent = [(0, SheetDetent.large), (medium, .medium), (bottom, .small)].min {
                                $0.0.distance(to: end).magnitude < $1.0.distance(to: end).magnitude
                            }!.1
                            setDetent(detent: detent, geo: geo)
                        }
                    }
                )
                .task(id: vm.sheetDetent) {
                    setDetent(detent: vm.sheetDetent, geo: geo)
                }
                .onChange(of: vm.selectedTrail) { _ in
                    setDetent(detent: vm.sheetDetent, geo: geo)
                }
                .onChange(of: horizontalSizeClass) { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        setDetent(detent: vm.sheetDetent, geo: geo)
                    }
                }
            }
            .frame(maxWidth: horizontalSizeClass == .regular ? 350 : 1000)
            Spacer(minLength: 0)
        }
        .padding(.top, 20)
        .padding(.horizontal, horizontalSizeClass == .compact ? 0 : 10)
        .transition(.move(edge: .bottom))
    }
    
    func setDetent(detent: SheetDetent, geo: GeometryProxy) {
        withAnimation(vm.detentSet ? .sheet : .none) {
            vm.sheetDetent = detent
            vm.detentSet = true
            vm.dragOffset = 0
            switch detent {
            case .small:
                vm.snapOffset = geo.size.height - headerSize.height
            case .medium:
                vm.snapOffset = geo.size.height - 270
            case .large:
                vm.snapOffset = 0
            }
        }
    }
}
