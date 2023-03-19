//
//  RootView.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI

struct RootView: View {
    @StateObject var vm = ViewModel.shared
    @AppStorage("launchedBefore") var launchedBefore = false
    @State var showWelcomeView = false

    var body: some View {
        NavigationView {
            ZStack {
                MapView()
                    .ignoresSafeArea()
                
                VStack {
                    Blur()
                        .ignoresSafeArea(.all, edges: .all)
                    Spacer()
                        .layoutPriority(1)
                }
                
                BottomBar()
            }
            .navigationTitle("Map")
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("")
                }
            }
            .environmentObject(vm)
            .sheet(isPresented: $showWelcomeView) {
                InfoView(welcome: true)
            }
            .alert("Access Denied", isPresented: $vm.showAuthError) {
                Button("Maybe Later") {}
                Button("Settings", role: .cancel) {
                    vm.openSettings()
                }
            } message: {
                Text("\(NAME) needs access to your location to show where you are on the map. Please go to Settings > \(NAME) > Location and allow access while using the app.")
            }
        }
    }
}
