//
//  WebVM.swift
//  News
//
//  Created by Jack Finnis on 13/01/2023.
//

import WebKit

class WebVM: NSObject, ObservableObject {
    @Published var loading = false
    @Published var error = false
    
    var webView: WKWebView?
    
    func load(url: URL) {
        loading = true
        error = false
        webView?.load(URLRequest(url: url))
    }
}

extension WebVM: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loading = false
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loading = false
        self.error = true
        Haptics.error()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        loading = false
        self.error = true
        Haptics.error()
    }
}
