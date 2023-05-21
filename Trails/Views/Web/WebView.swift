//
//  WebView.swift
//  Trails
//
//  Created by Jack Finnis on 16/03/2023.
//

import SwiftUI

struct WebView: View {
    @EnvironmentObject var vm: ViewModel
    @StateObject var webVM: WebVM
    @State var showShareSheet = false
    
    let trail: Trail
    
    var body: some View {
        WebUIView(webVM: webVM)
            .ignoresSafeArea(edges: .bottom)
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
            .shareSheet(items: [trail.url], showsSharedAlert: false, isPresented: $showShareSheet)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            UIApplication.shared.open(trail.url)
                        } label: {
                            Label("Open in Safari", systemImage: "safari")
                        }
                        Button {
                            UIPasteboard.general.url = trail.url
                            Haptics.tap()
                        } label: {
                            Label("Copy Link", systemImage: "link")
                        }
                        Button {
                            showShareSheet = true
                        } label: {
                            Label("Share...", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
    }
}
