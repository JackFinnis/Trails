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
    @State var showShareSheet = false
    
    @StateObject var webVM: WebVM
    let trail: Trail
    
    var body: some View {
        WebUIView(webVM: webVM, url: trail.url)
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
            .overlay(alignment: .top) {
                if webVM.loading {
                    ProgressView(value: webVM.progress)
                        .padding(.horizontal, -2)
                }
            }
            .animation(.default, value: webVM.error)
            .animation(.default, value: webVM.loading)
            .animation(.default, value: webVM.progress)
            .navigationTitle(trail.name)
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear {
                webVM.observer?.invalidate()
            }
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
                    .sharePopover(items: [trail.url], showsSharedAlert: false, isPresented: $showShareSheet)
                }
            }
    }
}

struct WebUIView: UIViewRepresentable {
    @ObservedObject var webVM: WebVM
    
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.navigationDelegate = webVM
        
        webVM.webView = webView
        webVM.load()
        webVM.observer = webView.observe(\.estimatedProgress, options: [.new]) { _, observation in
            webVM.progress = observation.newValue ?? 0
        }
        
        let refresh = UIRefreshControl()
        refresh.addTarget(webVM, action: #selector(WebVM.load), for: .valueChanged)
        webView.scrollView.refreshControl = refresh
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {}
}
