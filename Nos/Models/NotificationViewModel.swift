import Foundation
import CoreData
import UIKit

enum NotificationType {
    case event
    case follow
}

/// A model that turns an Event into something that can be displayed in a NotificationCard or via NotificationCenter
///
/// The view model is designed to be initialized synchronously so that it can be used
/// in the .init method of a View. Because of this you must call the async function
/// `loadContent()` to populate the `content` variable because it relies on some
///  database queries.
final class NotificationViewModel: ObservableObject, Identifiable {
    let noteID: RawNostrID?
    let authorID: RawAuthorID?
    let authorProfilePhotoURL: URL?
    let actionText: AttributedString
    let notificationType: NotificationType
    private(set) var content: AttributedString?
    let date: Date?

    var id: String {
        noteID ?? authorID ?? UUID().uuidString
    }

    /// Generates a notification request that can be sent to the UNNotificationCenter to display a banner notification.
    /// You probably want to call `loadContent(in:)` before accessing this.
    var notificationCenterRequest: UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = String(actionText.characters)
        if let attributedContent = self.content {
            content.body = String(attributedContent.characters)
        }
        content.userInfo = ["eventID": id]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        return UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )
    }

    convenience init?(coreDataModel: NosNotification, context: NSManagedObjectContext, createdAt: Date) {
        guard let user = coreDataModel.user else {
            return nil
        }

        if let eventID = coreDataModel.event?.identifier, let note = Event.find(by: eventID, context: context) {
            self.init(note: note, user: user, date: createdAt)
        } else if let follower = coreDataModel.follower {
            self.init(follower: follower, date: createdAt)
        } else {
            return nil
        }
    }

    init(follower: Author, date: Date) {
        self.authorID = follower.hexadecimalPublicKey
        self.noteID = nil
        self.authorProfilePhotoURL = follower.profilePhotoURL
        self.date = date
        self.notificationType = .follow

        // Compute action text
        var actionText: AttributedString
        var authorName = AttributedString("\(follower.safeName) ")
        var range = Range(uncheckedBounds: (authorName.startIndex, authorName.endIndex))
        authorName[range].font = .boldSystemFont(ofSize: 17)

        actionText = authorName + AttributedString(String(localized: "startedFollowingYou"))
        range = Range(uncheckedBounds: (actionText.startIndex, actionText.endIndex))
        actionText[range].foregroundColor = .primaryTxt
        self.actionText = actionText

        self.content = nil
    }

    init(note: Event, user: Author, date: Date) {
        self.noteID = note.identifier
        self.authorID = note.author?.hexadecimalPublicKey
        self.date = date
        self.authorProfilePhotoURL = note.author?.profilePhotoURL
        self.notificationType = .event

        // Compute action text
        var actionText: AttributedString
        var authorName = AttributedString("\(note.author?.safeName ?? String(localized: .localizable.someone)) ")
        var range = Range(uncheckedBounds: (authorName.startIndex, authorName.endIndex))
        authorName[range].font = .boldSystemFont(ofSize: 17)
        
        if note.isProfileZap(to: user) {
            if let tags = note.allTags as? [[String]],
                let amountTag = tags.first(where: { $0.first == "amount" }),
                let amountInMillisatsAsString = amountTag[safe: 1],
                let amountInMillisats = Int(amountInMillisatsAsString) {
                let zapText = String(localized: .reply.zappedYouSats(amountInMillisats / 1000))
                actionText = authorName + AttributedString(zapText)
            } else {
                actionText = authorName + AttributedString(String(localized: .reply.zappedYou))
            }
        } else if note.isReply(to: user) {
            actionText = authorName + AttributedString(String(localized: .reply.repliedToYourNote))
        } else if note.references(author: user) {
            actionText = authorName + AttributedString(String(localized: .reply.mentionedYou))
        } else {
            actionText = AttributedString()
        }
        
        range = Range(uncheckedBounds: (actionText.startIndex, actionText.endIndex))
        actionText[range].foregroundColor = .primaryTxt
        self.actionText = actionText
        
        content = AttributedString(note.content ?? "")
    }
    
    /// Populates the `content` variable. This is not done at init in order to keep
    /// it synchronous for use in a View.
    @MainActor @discardableResult func loadContent(in context: NSManagedObjectContext) async -> AttributedString? {
        if notificationType == .follow {
            return nil
        }
        content = await Event.attributedContent(noteID: noteID, context: context)
        return content
    }
}
