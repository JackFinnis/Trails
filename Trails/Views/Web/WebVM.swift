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
    @Published var progress = 0.0
    
    var webView: WKWebView?
    var observer: NSKeyValueObservation?
    
    init(url: URL) {
        self.url = url
    }
    
    @objc
    func load() {
        webView?.load(URLRequest(url: url))
    }
    
    func finished() {
        loading = false
        webView?.scrollView.refreshControl?.endRefreshing()
    }
    
    func errorOcurred() {
        error = true
        finished()
    }
}

extension WebVM: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loading = true
        error = false
        progress = 0
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        errorOcurred()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        errorOcurred()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loaded = true
        finished()
    }
}
