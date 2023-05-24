//
//  RootView.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI

struct RootView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("launchedBefore") var launchedBefore = false
    @StateObject var vm = ViewModel.shared
    @State var showInfoView = false
    @State var showWelcomeView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                MapView()
                    .disabled(vm.mapDisabled)
                    .overlay {
                        if vm.mapDisabled {
                            Color.black.opacity(0.1)
                        }
                    }
                    .ignoresSafeArea()
                    .animation(.default, value: vm.mapDisabled)
                
                VStack(spacing: 0) {
                    CarbonCopy()
                        .id(scenePhase)
                        .blur(radius: 10, opaque: true)
                        .ignoresSafeArea()
                    Spacer()
                        .layoutPriority(1)
                }
                
                VStack {
                    HStack {
                        Spacer()
                        if !vm.mapDisabled {
                            MapButtons()
                        }
                    }
                    Spacer()
                }
                .animation(.default, value: vm.mapDisabled)
                
                Sheet {
                    if vm.searchScope == .Trails || !vm.isSearching {
                        TrailsView()
                    } else {
                        SearchView()
                    }
                } header: {
                    HStack {
                        SearchBar()
                            .padding(.vertical, -10)
                            .padding(.horizontal, -8)
                        
                        if !vm.isSearching {
                            Button {
                                showInfoView = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .font(.icon)
                            }
                        }
                    }
                }
                
                if let trail = vm.selectedTrail {
                    Sheet {
                        TrailView(trail: trail)
                    } header: {
                        HStack(alignment: .firstTextBaseline) {
                            Text(trail.name)
                                .font(.title2.weight(.semibold))
                            Spacer()
                            Button {
                                vm.selectTrail(nil)
                            } label: {
                                DismissCross(toolbar: false)
                            }
                            .buttonStyle(.plain)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            vm.zoomTo(trail)
                        }
                    }
                }
                
                HStack {
                    VStack {
                        Spacer()
                        Group {
                            if let polyline = vm.selectPolyline {
                                SelectionBar(polyline: polyline)
                            } else if vm.isSelecting {
                                SelectBar()
                            }
                        }
                        .detectSize($vm.selectBarSize)
                        .frame(maxWidth: vm.maxWidth)
                        .animation(.sheet, value: vm.selectPolyline)
                    }
                    Spacer(minLength: 0)
                }
            }
            .navigationTitle("Map")
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("")
                }
            }
        }
        .animation(.sheet, value: vm.selectedTrail)
        .onChange(of: colorScheme) { _ in
            vm.refreshOverlays()
        }
        .onChange(of: horizontalSizeClass) { _ in
            vm.refreshSheetDetent()
        }
        .task {
            vm.refreshSheetDetent()
            vm.animateDetentChange = true
            if !launchedBefore {
                launchedBefore = true
                showWelcomeView = true
            }
        }
        .background {
            Text("")
                .alert("Access Denied", isPresented: $vm.showAuthAlert) {
                    Button("Maybe Later") {}
                    Button("Settings", role: .cancel) {
                        vm.openSettings()
                    }
                } message: {
                    Text("\(Constants.name) needs access to your location to show where you are on the map. Please go to Settings > \(Constants.name) > Location and allow access while using the app.")
                }
                .sheet(isPresented: $showWelcomeView) {
                    InfoView(welcome: true)
                }
            Text("")
                .alert("🎉 Congratulations! 🎉", isPresented: $vm.showCompletedAlert) {
                    if !vm.shownReviewPrompt {
                        Button("Review \(Constants.name)") {
                            vm.shownReviewPrompt = true
                            Store.writeReview()
                        }
                        Button("Rate \(Constants.name)") {
                            vm.shownReviewPrompt = true
                            Store.requestRating()
                        }
                    }
                    Button("Maybe Later") {}
                } message: {
                    Text("You have walked the entire length of \(vm.selectedTrail?.name ?? "")! That's over \(vm.formatDistance(vm.selectMetres, showUnit: true, round: true))!\n\(vm.shownReviewPrompt ? "" : "Please consider leaving a review or rating \(Constants.name) if the app helped you navigate.")")
                }
                .sheet(isPresented: $showInfoView) {
                    InfoView(welcome: false)
                }
        }
        .environmentObject(vm)
        .navigationViewStyle(.stack)
    }
}
