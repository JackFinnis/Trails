//
//  WiFiError.swift
//  Trails
//
//  Created by Jack Finnis on 20/03/2023.
//

import SwiftUI

struct WiFiError: View {
    @EnvironmentObject var vm: ViewModel
    
    let compact: Bool
    
    var body: some View {
        if compact {
            Button {
                vm.openSettings()
            } label: {
                Label("No Internet Connection", systemImage: "wifi.slash")
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .accentColor(.black)
            .padding()
            .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            VStack(spacing: 20) {
                BigLabel(systemName: "wifi.slash", title: "No Internet Connection", message: "Please check your internet\nconnection and try again.")
                Button("Open Settings") {
                    vm.openSettings()
                }
                .font(.subheadline.bold())
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
            }
        }
    }
}
