//
//  WebVM.swift
//  News
//
//  Created by Jack Finnis on 13/01/2023.
//

import WebKit

class WebVM: NSObject, ObservableObject {
    let url: URL
    
    @Published var loading = false
    @Published var loaded = false
    @Published var error = false
    
    var webView: WKWebView?
    
    init(url: URL) {
        self.url = url
    }
    
    @objc
    func load() {
        loading = true
        error = false
        webView?.load(URLRequest(url: url))
    }
    
    func finished() {
        loading = false
        webView?.scrollView.refreshControl?.endRefreshing()
    }
}

extension WebVM: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loaded = true
        finished()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.error = true
        finished()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.error = true
        finished()
    }
}
