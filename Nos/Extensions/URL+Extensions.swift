//
//  URL+Extensions.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/15/23.
//

import Foundation

extension URL {
    
    var isImage: Bool {
        let imageExtensions = ["png", "jpg", "jpeg", "gif"]
        return imageExtensions.contains(pathExtension)
    }
    
    func strippingTrailingSlash() -> String {
        var string = absoluteString
        if string.last == "/" {
            string.removeLast()
        }
        return string
    }
    
    var truncatedMarkdownLink: String {
        // if there's no scheme, it may be a URL like "www.nostr.com", which we still want to truncate
        guard scheme != nil else {
            let truncated: String
            if absoluteString.hasPrefix("www.") {
                truncated = String(absoluteString.dropFirst(4))
            } else {
                truncated = absoluteString
            }
            if truncated.contains(/\//) {
                let host = truncated.replacing(/\/.*/, with: "")
                return "[\(host)...](\(absoluteString))"
            } else {
                return "[\(truncated)](\(absoluteString))"
            }
        }

        guard var host = host() else {
            return "[\(absoluteString)](\(absoluteString))"
        }
        
        if host.hasPrefix("www.") {
            host = String(host.dropFirst(4))
        }
        
        if path().isEmpty {
            return "[\(host)](\(absoluteString))"
        } else {
            return "[\(host)...](\(absoluteString))"
        }
    }
}
