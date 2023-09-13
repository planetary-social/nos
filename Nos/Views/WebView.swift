//
//  WebView.swift
//  Nos
//
//  Created by Matthew Lorentz on 5/2/23.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = UIColor.appBg
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.load(URLRequest(url: url))
    }
}

struct URLView: View {
    let url: URL
    
    var body: some View {
        WebView(url: url)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { 
                    Button { 
                        UIApplication.shared.open(url)
                    } label: { 
                        Image(systemName: "safari")
                    }
                }
            }
            .background(FullscreenProgressView(isPresented: .constant(true)))
    }
}

struct WebView_Previews: PreviewProvider {
    static var previews: some View {
        URLView(url: URL(string: "https://www.example.com") ?? URL.userDirectory)
    }
}
