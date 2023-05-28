//
//  SheetsView.swift
//  Trails
//
//  Created by Jack Finnis on 28/05/2023.
//

import SwiftUI

struct SheetsView: View {
    @EnvironmentObject var vm: ViewModel
    @State var profile: ElevationProfile?
    @State var trail: Trail?
    @State var isSelecting = false
    
    var body: some View {
        Sheet(isPresented: vm.selectedTrail != nil && !isSelecting) {
            if let trail {
                TrailView(trail: trail)
            }
        } header: {
            if let trail {
                TrailView.Header(trail: trail)
            }
        }
        .animation(.sheet, value: vm.selectedTrail)
        .onChange(of: vm.selectedTrail) { selectedTrail in
            if let selectedTrail {
                trail = selectedTrail
            }
        }
        .onChange(of: vm.isSelecting) { isSelecting in
            withAnimation(profile != nil && !isSelecting ? .none : .sheet) {
                self.isSelecting = isSelecting
            }
        }
        
        Sheet(isPresented: vm.isSelecting && vm.selectionProfile != nil) {
            if let profile {
                SelectionView(profile: profile)
            }
        } header: {
            if let profile {
                SelectionView.Header(profile: profile)
            }
        }
        .animation(.sheet, value: vm.selectionProfile)
        .animation(.sheet, value: vm.isSelecting)
        .onChange(of: vm.selectionProfile) { selectionProfile in
            if let selectionProfile {
                profile = selectionProfile
            }
        }
    }
}
