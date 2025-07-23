// ABOUTME: Color extensions for wallet-related UI components
// ABOUTME: Defines additional colors needed for Cashu wallet interface

import SwiftUI

extension Color {
    /// Background color for surface elements like cards
    static var backgroundSurface: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(white: 0.15, alpha: 1.0)
            } else {
                return UIColor(white: 0.95, alpha: 1.0)
            }
        })
    }
    
    /// Divider color for profile sections
    static var profileDivider: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(white: 1.0, alpha: 0.1)
            } else {
                return UIColor(white: 0.0, alpha: 0.1)
            }
        })
    }
    
    /// Shadow color for profile divider
    static var profileDividerShadow: Color {
        Color.black.opacity(0.05)
    }
    
    /// Overlay color for action sheets
    static var actionSheetOverlay: Color {
        Color.black.opacity(0.4)
    }
}