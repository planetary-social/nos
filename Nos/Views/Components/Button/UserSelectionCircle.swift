import SwiftUI

/// A circular image view that is either a purple checkmark or an orange user-plus based
/// on the `selected` property.
///
/// This is useful to indicate "selected" or "included" state of the contextual item, such
/// as a user being followed or not or being in an ``AuthorList`` or not.
struct UserSelectionCircle: View {
    let diameter: CGFloat
    let selected: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .frame(width: diameter)
                .foregroundStyle(
                    selected ? LinearGradient.verticalAccentSecondary : LinearGradient.verticalAccentPrimary
                )
                .background(
                    Circle()
                        .frame(width: diameter)
                        .offset(y: 1)
                        .foregroundStyle(
                            selected ? Color.actionSecondaryBackground : Color.actionPrimaryBackground
                        )
                )
            
            if selected {
                Image.followingIcon
                    .padding(.top, 3) // the icon file isn't square so we need to shift it down
            } else {
                Image.followIcon
            }
        }
    }
}
