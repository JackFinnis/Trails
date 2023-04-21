//
//  WiFiError.swift
//  Trails
//
//  Created by Jack Finnis on 20/03/2023.
//

import SwiftUI

struct WiFiError: View {
    @Environment(\.openURL) var openURL
    @Environment(\.colorScheme) var colorScheme
    
    let compact: Bool
    
    var body: some View {
        if compact {
            Button(action: openSettings) {
                Label("No Internet Connection", systemImage: "wifi.slash")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.black)
                    .background(Color.black)
                    .continuousRadius(10)
            }
            .buttonStyle(.plain)
            .padding()
            .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            VStack(spacing: 20) {
                BigLabel(systemName: "wifi.slash", title: "News Unavailable", message: "Please check your internet connection\nand try again.")
                Button(action: openSettings) {
                    Text("Open Settings")
                }
                .font(.subheadline.bold())
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
            }
        }
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}
