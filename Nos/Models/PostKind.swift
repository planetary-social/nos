import Foundation
import SwiftUI

/// Represents different kinds of posts that can be created
enum PostKind: String, CaseIterable, Identifiable {
    case textNote      // Kind 1
    case picturePost   // Kind 20
    case videoPost     // Kind 21
    case shortVideo    // Kind 22
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .textNote:
            return String(localized: "textNote")
        case .picturePost:
            return String(localized: "picturePost")
        case .videoPost:
            return String(localized: "videoPost")
        case .shortVideo:
            return String(localized: "shortVideo")
        }
    }
    
    var icon: String {
        switch self {
        case .textNote:
            return "text.bubble"
        case .picturePost:
            return "photo"
        case .videoPost:
            return "video"
        case .shortVideo:
            return "video.badge.plus"
        }
    }
    
    var description: String {
        switch self {
        case .textNote:
            return String(localized: "textNoteDescription")
        case .picturePost:
            return String(localized: "picturePostDescription")
        case .videoPost:
            return String(localized: "videoPostDescription")
        case .shortVideo:
            return String(localized: "shortVideoDescription")
        }
    }
    
    var nostrKind: Int {
        switch self {
        case .textNote:
            return 1
        case .picturePost:
            return 20
        case .videoPost:
            return 21
        case .shortVideo:
            return 22
        }
    }
    
    var requiresTitle: Bool {
        switch self {
        case .textNote:
            return false
        case .picturePost, .videoPost, .shortVideo:
            return true
        }
    }
}