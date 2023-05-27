//
//  Sheet.swift
//  Trails
//
//  Created by Jack Finnis on 18/04/2023.
//

import SwiftUI
import MapKit

enum SheetDetent: CaseIterable {
    case large
    case medium
    case small
}

struct Sheet<Content: View, Header: View>: View {
    @EnvironmentObject var vm: ViewModel
    @GestureState var translation = 0.0
    
    let isPresented: Bool
    
    @ViewBuilder let content: () -> Content
    @ViewBuilder let header: () -> Header
    
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    let spacerHeight = vm.getSpacerHeight(geo.size, detent: vm.sheetDetent)
                    Spacer()
                        .frame(height: max(isPresented ? 1 : geo.size.height + geo.safeAreaInsets.bottom, spacerHeight + translation))
                    
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
                            .detectSize($vm.headerSize)
                            
                            content()
                                .opacity((vm.getSpacerHeight(geo.size, detent: .small) - (spacerHeight + translation))/50.0)
                        }
                    }
                }
                .animation(.sheet, value: translation == 0)
                .gesture(DragGesture(minimumDistance: 1)
                    .updating($translation) { gesture, state, transaction in
                        let current = vm.getSpacerHeight(geo.size, detent: vm.sheetDetent)
                        let end = current + gesture.translation.height
                        let min = vm.getSpacerHeight(geo.size, detent: .large)
                        let max = vm.getSpacerHeight(geo.size, detent: .small)
                        if end < min {
                            state = (min - sqrt(min.distance(to: end).magnitude)) - current
                        } else if end > max {
                            state = (max + sqrt(max.distance(to: end).magnitude)) - current
                        } else {
                            state = gesture.translation.height
                        }
                    }
                    .onEnded { gesture in
                        let current = vm.getSpacerHeight(geo.size, detent: vm.sheetDetent)
                        let end = current + gesture.predictedEndTranslation.height
                        let spacerHeights = SheetDetent.allCases.map { ($0, vm.getSpacerHeight(geo.size, detent: $0)) }
                        let detent = spacerHeights.min {
                            $0.1.distance(to: end).magnitude < $1.1.distance(to: end).magnitude
                        }!.0
                        vm.setSheetDetent(detent)
                    }
                )
                .frame(maxWidth: vm.getMaxSheetWidth(geo.size))
                .padding(.horizontal, vm.getHorizontalSheetPadding(geo.size))
                Spacer(minLength: 0)
            }
        }
        .transition(.move(edge: .bottom))
    }
}

struct SheetStat: View {
    let name: String
    let value: String
    let systemName: String
    var tint: Color = .secondary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
                .textCase(.uppercase)
                .foregroundColor(.secondary)
                .font(.caption2.weight(.bold))
            HStack(spacing: 5) {
                Image(systemName: systemName)
                    .font(.footnote.weight(.bold))
                    .foregroundColor(tint)
                Text(value)
                    .font(.subheadline.bold())
            }
        }
    }
}
