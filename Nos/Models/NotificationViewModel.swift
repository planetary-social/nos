//
//  NotificationViewModel.swift
//  Nos
//
//  Created by Matthew Lorentz on 7/5/23.
//

import Foundation
import CoreData
import UIKit

/// A model that turns an Event into something that can be displayed in a NotificationCard or via NotificationCenter
///
/// The view model is designed to be initialized synchronously so that it can be used
/// in the .init method of a View. Because of this you must call the async function
/// `loadContent()` to populate the `content` variable because it relies on some
///  database queries.
class NotificationViewModel: ObservableObject, Identifiable {
    let noteID: HexadecimalString
    let authorProfilePhotoURL: URL?
    let actionText: AttributedString
    @Published var content: AttributedString?
    let date: Date
    
    var id: HexadecimalString {
        noteID
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
            identifier: noteID, 
            content: content, 
            trigger: trigger
        )
    }
    
    convenience init?(coreDataModel: NosNotification, context: NSManagedObjectContext) {
        guard let eventID = coreDataModel.eventID,
            let note = Event.find(by: eventID, context: context),
            let user = coreDataModel.user else {
            return nil
        }
        
        self.init(note: note, user: user)
    }
    
    init(note: Event, user: Author) {
        self.noteID = note.identifier ?? ""
        self.date = note.createdAt ?? .distantPast
        self.authorProfilePhotoURL = note.author?.profilePhotoURL

        // Compute action text
        var actionText: AttributedString
        var authorName = AttributedString("\(note.author?.safeName ?? String(localized: .localizable.someone)) ")
        var range = Range(uncheckedBounds: (authorName.startIndex, authorName.endIndex))
        authorName[range].font = .boldSystemFont(ofSize: 17)
        
        if note.isReply(to: user) {
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
        content = await Event.attributedContent(noteID: id, context: context)
        return content
    }
}
