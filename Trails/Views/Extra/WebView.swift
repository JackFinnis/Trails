//
//  WebView.swift
//  Trails
//
//  Created by Jack Finnis on 16/03/2023.
//

import SwiftUI
import WebKit

struct WebView: View {
    @EnvironmentObject var vm: ViewModel
    @Environment(\.openURL) var openURL
    @StateObject var webVM = WebVM()
    
    let trail: Trail
    
    var body: some View {
        WebUIView(webVM: webVM)
            .ignoresSafeArea()
            .overlay {
                if webVM.error {
                    VStack {
                        BigLabel(systemName: "wifi.slash", title: "No Internet Connection", message: "")
                        Button("Open Settings") {
                            vm.openSettings()
                        }
                        .font(.headline)
                    }
                }
            }
            .background {
                if webVM.loading {
                    ProgressView()
                }
            }
            .onAppear {
                webVM.load(url: trail.url)
            }
            .navigationTitle(trail.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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

struct WebUIView: UIViewRepresentable {
    @ObservedObject var webVM: WebVM
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = webVM
        webView.isOpaque = false
        webVM.webView = webView
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {}
}
