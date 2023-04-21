//
//  WebUIView.swift
//  Trails
//
//  Created by Jack Finnis on 20/03/2023.
//

import SwiftUI
import WebKit

struct WebUIView: UIViewRepresentable {
    @ObservedObject var webVM: WebVM
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.navigationDelegate = webVM
        webVM.webView = webView
        webVM.load()
        
        let refresh = UIRefreshControl()
        refresh.addTarget(webVM, action: #selector(WebVM.load), for: .valueChanged)
        webView.scrollView.refreshControl = refresh
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {}
}
