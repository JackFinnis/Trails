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
            .overlay(alignment: .bottom) {
                if webVM.error {
                    Button {
                        vm.openSettings()
                    } label: {
                        Label("No Internet Connection", systemImage: "wifi.slash")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.black)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
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
            .animation(.default, value: webVM.error)
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
