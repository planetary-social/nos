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
            return String(localized: "Text Note")
        case .picturePost:
            return String(localized: "Picture Post")
        case .videoPost:
            return String(localized: "Video Post")
        case .shortVideo:
            return String(localized: "Short Video")
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
            return String(localized: "Standard text note")
        case .picturePost:
            return String(localized: "Image-first post with title")
        case .videoPost:
            return String(localized: "Video post with title")
        case .shortVideo:
            return String(localized: "Short-form video")
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
    
    var eventKind: EventKind {
        switch self {
        case .textNote:
            return .text
        case .picturePost:
            return .picturePost
        case .videoPost:
            return .video
        case .shortVideo:
            return .shortVideo
        }
    }
}