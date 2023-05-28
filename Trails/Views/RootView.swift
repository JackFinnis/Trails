//
//  RootView.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI

struct RootView: View {
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("launchedBefore") var launchedBefore = false
    @StateObject var vm = ViewModel.shared
    @State var showWelcomeView = false
    @FocusState var focused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                GeometryReader { geo in
                    let disabled = vm.isMapDisabled(geo.size)
                    MapView()
                        .disabled(disabled)
                    Color.black.opacity(disabled ? 0.15 : 0)
                }
                .ignoresSafeArea()
                .sheet(isPresented: $showWelcomeView) {
                    InfoView(welcome: true)
                }
                
                VStack(spacing: 0) {
                    CarbonCopy()
                        .id(scenePhase)
                        .blur(radius: 10, opaque: true)
                        .ignoresSafeArea()
                    Spacer()
                        .layoutPriority(1)
                }
                
                GeometryReader { geo in
                    VStack {
                        HStack {
                            Spacer()
                            if !vm.isMapDisabled(geo.size) {
                                MapButtons()
                            }
                        }
                        Spacer()
                    }
                }
                
                Sheet {
                    TrailsView()
                } header: {
                    TrailsView.Header()
                }
                .opacity(vm.showTrailsView ? 1 : 0)
                
                TrailSheet()
                SelectionSheet()
                
                GeometryReader { geo in
                    HStack {
                        VStack {
                            Spacer()
                            if vm.selectionProfile == nil && vm.isSelecting {
                                SelectBar()
                                    .frame(maxWidth: vm.getMaxSheetWidth(geo.size))
                                    .padding(10)
                            }
                        }
                        .animation(.sheet, value: vm.selectionProfile)
                        Spacer(minLength: 0)
                    }
                }
                
                if vm.showSpeedInput {
                    VStack(spacing: 0) {
                        Color.black.opacity(0.15)
                            .ignoresSafeArea()
                        HStack(spacing: 15) {
                            Button("Cancel") {
                                vm.showSpeedInput = false
                            }
                            TextField("Enter speed in \(vm.distanceUnit.speedUnit)", value: $vm.newSpeed, formatter: vm.distanceUnit.formatter)
                                .focused($focused)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                            Button("Submit") {
                                vm.speed = vm.newSpeed * vm.distanceUnit.conversion
                                vm.newSpeed = 0
                                Haptics.tap()
                                withAnimation {
                                    vm.showSpeedInput = false
                                }
                            }
                            .disabled(vm.newSpeed == 0)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(Color(.systemBackground))
                    }
                    .task {
                        focused = true
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
        .onChange(of: colorScheme) { _ in
            vm.refreshOverlays()
        }
        .task {
            if !launchedBefore {
                launchedBefore = true
                showWelcomeView = true
            }
            if let trail = vm.trails.first(where: { $0.id == vm.selectedTrailId }) {
                vm.selectTrail(trail, animated: false)
            } else {
                vm.refreshOverlays()
                vm.zoomToFilteredTrails(animated: false)
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
                    Button("Dismiss", role: .cancel) {}
                    if !vm.tappedReviewBefore {
                        Button("Maybe Later", role: .cancel) {}
                        Button("Review \(Constants.name)") {
                            vm.writeReview()
                        }
                        Button("Rate \(Constants.name)") {
                            vm.requestRating()
                        }
                    }
                } message: {
                    if let trail = vm.selectedTrail {
                        let prompt = vm.tappedReviewBefore ? "" : "\n\nPlease consider leaving a review or rating \(Constants.name) if the app helped you navigate."
                        Text("You have walked the entire length of \(trail.name) - that's over \(vm.formatDistance(trail.metres, unit: true, round: true))!\(prompt)")
                    }
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
        .environmentObject(vm)
        .navigationViewStyle(.stack)
    }
}
