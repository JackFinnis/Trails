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
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.black)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .padding()
            .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    Image(systemName: "wifi.slash")
                        .font(.largeTitle)
                    Text("No Internet Connection")
                        .font(.title3.bold())
                }
                .allowsHitTesting(false)
                .foregroundColor(.secondary)
                
                Button("Open Settings") {
                    vm.openSettings()
                }
                .font(.headline)
            }
            .transition(.opacity)
        }
    }
}

struct WiFiError_Previews: PreviewProvider {
    static var previews: some View {
        WiFiError(compact: false)
    }
}
