import Foundation

/// Use this enum to change how a card (NoteCard) is displayed
enum CardStyle {
    /// A compact card is meant to be displayed in a one column list layout
    case compact

    /// A golden card is meant to be displayed in multi column grid layout
    case golden
    
    /// A picture-first card optimized for displaying NIP-68 picture posts
    case pictureFirst
}
