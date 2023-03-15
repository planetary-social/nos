//
//  URL+MimeTypes.swift
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
}
