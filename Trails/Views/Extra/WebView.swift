//
//  WebView.swift
//  Trails
//
//  Created by Jack Finnis on 16/03/2023.
//

import SwiftUI
import WebKit

struct WebView: View {
    @Environment(\.openURL) var openURL
    @StateObject var webVM = WebVM()
    
    let trail: Trail
    
    var body: some View {
        WebUIView(webVM: webVM)
            .ignoresSafeArea()
            .overlay {
                if webVM.error {
                    BigLabel(systemName: "wifi.slash", title: "No Connection", message: "The \(NAME) app isn't connected to the internet. To view the news, check your internet connection, then try again.")
                }
            }
            .onAppear {
                webVM.load(url: trail.url)
            }
            .navigationTitle(trail.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 10) {
                        if webVM.loading {
                            ProgressView()
                        }
                        Button {
                            openURL(trail.url)
                        } label: {
                            Image(systemName: "safari")
                        }
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
        webVM.webView = webView
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {}
}
