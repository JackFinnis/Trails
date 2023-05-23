//
//  RootView.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI

struct RootView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("launchedBefore") var launchedBefore = false
    @StateObject var vm = ViewModel.shared
    @State var showInfoView = false
    @State var showWelcomeView = false
    @GestureState var dragOffset = CGFloat.zero
    
    var mapDisabled: Bool {
        vm.snapOffset == 0 && horizontalSizeClass == .compact
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .topTrailing) {
                MapView()
                    .disabled(mapDisabled)
                    .overlay {
                        if mapDisabled {
                            Color.black.opacity(0.1)
                        }
                    }
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    CarbonCopy()
                        .id(colorScheme)
                        .blur(radius: 10, opaque: true)
                        .ignoresSafeArea()
                    Spacer()
                        .layoutPriority(1)
                }
                
                if !mapDisabled {
                    MapButtons()
                }
                
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
                    .zIndex(1)
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
            vm.refreshTrailOverlays()
        }
        .task {
            if !launchedBefore {
                launchedBefore = true
                showWelcomeView = true
            }
        }
        .shareSheet(items: vm.shareItems, showsSharedAlert: false, isPresented: $vm.showShareSheet)
        .sheet(isPresented: $showWelcomeView) {
            InfoView(welcome: true)
        }
        .sheet(isPresented: $showInfoView) {
            InfoView(welcome: false)
        }
        .animation(.default, value: mapDisabled)
        .environmentObject(vm)
        .navigationViewStyle(.stack)
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
                .alert("🎉 Congratulations! 🎉", isPresented: $vm.showCompletedAlert) {
                    Button("Review \(Constants.name)") {
                        Store.writeReview()
                    }
                    Button("Rate \(Constants.name)") {
                        Store.requestRating()
                    }
                    Button("Maybe Later") {}
                } message: {
                    Text("You have walked the entire length of \(vm.selectedTrail?.name ?? ""); that's over \(vm.formatDistance(vm.selectMetres, showUnit: true, round: true))! Please consider leaving a review or rating \(Constants.name) if the app helped you navigate.")
                }
        }
    }
}
