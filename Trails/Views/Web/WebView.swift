//
//  WebView.swift
//  Trails
//
//  Created by Jack Finnis on 16/03/2023.
//

import SwiftUI

struct WebView: View {
    @EnvironmentObject var vm: ViewModel
    @Environment(\.openURL) var openURL
    @StateObject var webVM: WebVM
    
    let trail: Trail
    
    var body: some View {
        WebUIView(webVM: webVM)
            .ignoresSafeArea()
            .overlay {
                if webVM.error && !webVM.loaded {
                    WiFiError(compact: false)
                }
            }
            .overlay(alignment: .bottom) {
                if webVM.error && webVM.loaded {
                    WiFiError(compact: true)
                }
            }
            .background {
                if webVM.loading {
                    ProgressView()
                }
            }
            .animation(.default, value: webVM.error)
            .navigationTitle(trail.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button {
                        openURL(trail.url)
                    } label: {
                        Image(systemName: "safari")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        openURL(trail.url)
                    } label: {
                        Image(systemName: "safari")
                    }
                }
            }
    }
}
