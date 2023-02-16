//
//  RootView.swift
//  Trails
//
//  Created by Jack Finnis on 16/02/2023.
//

import SwiftUI

struct RootView: View {
    @StateObject var vm = ViewModel()
    
    var body: some View {
        MapView()
            .ignoresSafeArea()
            .environmentObject(vm)
            .task {
                vm.loadTrails()
            }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
