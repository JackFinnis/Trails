//
//  RootView.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI

struct RootView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("launchedBefore") var launchedBefore = false
    @StateObject var vm = ViewModel.shared

    var body: some View {
        NavigationView {
            ZStack(alignment: .topTrailing) {
                MapView()
                    .ignoresSafeArea()
                    .alert("Access Denied", isPresented: $vm.showAuthError) {
                        Button("Maybe Later") {}
                        Button("Settings", role: .cancel) {
                            vm.openSettings()
                        }
                    } message: {
                        Text("\(NAME) needs access to your location to show where you are on the map. Please go to Settings > \(NAME) > Location and allow access while using the app.")
                    }
                
                VStack(spacing: 0) {
                    CarbonCopy()
                        .blur(radius: 10, opaque: true)
                        .ignoresSafeArea()
                    Spacer()
                        .layoutPriority(1)
                }
                .alert("🎉 Congratulations! 🎉", isPresented: $vm.showCompletedAlert) {
                    Button("Review \(NAME)") {
                        Store.writeReview()
                    }
                    Button("Rate \(NAME)") {
                        Store.requestRating()
                    }
                    Button("Maybe Later") {}
                } message: {
                    Text("You have walked the entire length of \(vm.selectedTrail?.name ?? ""); that's over \(vm.formatDistance(vm.selectMetres, showUnit: true, round: true))! Please consider leaving a review or rating \(NAME) if the app helped you navigate.")
                }
                
                if vm.snapOffset != 0 {
                    MapButtons()
                }
                
                Sheet {
                    if vm.searchScope == .Trails || !vm.isSearching {
                        TrailsList()
                    } else {
                        SearchList()
                    }
                } header: {
                    HStack {
                        SearchBar()
                            .padding(.vertical, -10)
                            .padding(.horizontal, -8)
                        
                        if !vm.isSearching {
                            Button {
                                vm.welcome = false
                                vm.showInfoView = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .font(.icon)
                            }
                        }
                    }
                    .animation(.none, value: vm.isSearching)
                }
                
                if let trail = vm.selectedTrail {
                    Sheet {
                        TrailView(trail: trail)
                    } header: {
                        HStack(alignment: .firstTextBaseline) {
                            Text(trail.name)
                                .font(.title2.weight(.semibold))
                            Spacer(minLength: 0)
                            Button {
                                vm.selectTrail(nil)
                            } label: {
                                DismissCross(toolbar: false)
                            }
                            .buttonStyle(.plain)
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
        .navigationViewStyle(.stack)
        .onChange(of: colorScheme) { _ in
            vm.refreshOverlays()
        }
        .task {
            if !launchedBefore {
                launchedBefore = true
                vm.welcome = true
                vm.showInfoView = true
            }
        }
        .shareSheet(items: vm.shareLocationItems, isPresented: $vm.showShareLocationSheet)
        .sheet(isPresented: $vm.showInfoView) {
            InfoView(welcome: vm.welcome)
        }
        .environmentObject(vm)
    }
}
