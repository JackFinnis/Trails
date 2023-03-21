//
//  RootView.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI

struct RootView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject var vm = ViewModel.shared
    @AppStorage("launchedBefore") var launchedBefore = false
    @State var showWelcomeView = false

    var body: some View {
        NavigationView {
            ZStack {
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
                
                VStack {
                    Blur()
                        .ignoresSafeArea(.all, edges: .all)
                    Spacer()
                        .layoutPriority(1)
                }
                
                Buttons()
                    .alert("🎉 Congratulations! 🎉", isPresented: $vm.showCompletedAlert) {
                        Button("Review \(NAME)") {
                            Store.writeReview()
                        }
                        Button("Rate \(NAME)") {
                            Store.requestRating()
                        }
                        Button("Maybe Later") {}
                    } message: {
                        Text("You have walked the entire length of \(vm.selectedTrail?.name ?? ""); that's over \(vm.formatMiles(vm.selectMetres, showUnit: true, round: true))! Please consider leaving a review or rating \(NAME) if the app helped you navigate.")
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
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showWelcomeView) {
            InfoView(welcome: true)
        }
        .environmentObject(vm)
        .onChange(of: colorScheme) { _ in
            vm.refreshOverlays()
        }
        .task {
            if !launchedBefore {
                launchedBefore = true
                showWelcomeView = true
            }
        }
    }
}
