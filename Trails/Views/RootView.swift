//
//  RootView.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI

struct RootView: View {
    @Environment(\.scenePhase) var scenePhase//todo
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("launchedBefore") var launchedBefore = false
    @StateObject var vm = ViewModel.shared
    @State var showInfoView = false
    @State var showWelcomeView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                GeometryReader { geo in
                    let disabled = vm.isMapDisabled(geo.size)
                    MapView()
                        .disabled(disabled)
                    Color.black.opacity(disabled ? 0.1 : 0)
                }
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    CarbonCopy()
                        .id(scenePhase)
                        .blur(radius: 10, opaque: true)
                        .ignoresSafeArea()
                    Spacer()
                        .layoutPriority(1)
                }
                
                GeometryReader { geo in
                    let disabled = vm.isMapDisabled(geo.size)
                    VStack {
                        HStack {
                            Spacer()
                            if !disabled {
                                MapButtons()
                            }
                        }
                        Spacer()
                    }
                }
                
                Sheet(isPresented: vm.selectedTrail == nil) {
                    TrailsView()
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
                    Sheet(isPresented: !vm.isSelecting) {
                        TrailView(trail: trail)
                    } header: {
                        HStack(alignment: .firstTextBaseline) {
                            Text(trail.name)
                                .fixedSize(horizontal: false, vertical: true)
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
                
                GeometryReader { geo in
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
                            .frame(maxWidth: vm.getMaxSheetWidth(geo.size))
                            .animation(.sheet, value: vm.selectPolyline)
                        }
                        Spacer(minLength: 0)
                    }
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
        .animation(.sheet, value: vm.isSelecting)
        .animation(.sheet, value: vm.selectedTrail)
        .onChange(of: colorScheme) { _ in
            vm.refreshOverlays()
        }
        .task {
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
            Text("")
                .alert("Congratulations!", isPresented: $vm.showCompletedAlert) {
                    if !vm.shownReviewPrompt {
                        Button("Review \(Constants.name)") {
                            Store.writeReview()
                        }
                        Button("Rate \(Constants.name)") {
                            Store.requestRating()
                        }
                    }
                    Button("Maybe Later") {}
                } message: {
                    Text("You have walked the entire length of \(vm.selectedTrail?.name ?? "")! That's over \(vm.formatDistance(vm.selectMetres, showUnit: true, round: true))!\(vm.shownReviewPrompt ? "" : "\nPlease consider leaving a review or rating \(Constants.name) if the app helped you navigate.")")
                }
            Text("")
                .alert("No Connection", isPresented: $vm.showWiFiAlert) {
                    Button("Dismiss", role: .cancel) {}
                    Button("Open Settings") {
                        vm.openSettings()
                    }
                } message: {
                    Text("Check your internet connection and try again")
                }
        }
        .background {
            Text("")
                .sheet(isPresented: $showInfoView) {
                    InfoView(welcome: false)
                }
            Text("")
                .sheet(isPresented: $showWelcomeView) {
                    InfoView(welcome: true)
                }
        }
        .environmentObject(vm)
        .navigationViewStyle(.stack)
    }
}
