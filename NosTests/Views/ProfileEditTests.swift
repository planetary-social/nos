import Foundation
import XCTest
import Dependencies
import SwiftUI
import ViewInspector
import Combine
import CoreData
@testable import Nos

struct ProfileEditTestView: View {
    @ObservedObject var author: Nos.Author // Explicitly use Nos.Author
    internal let inspection = Inspection<Self>()

    var body: some View {
        ProfileEditView(author: author)
            .onReceive(inspection.notice) { self.inspection.visit(self, $0) }
    }
}

final class ProfileEditViewTests: CoreDataTestCase {

    @MainActor func testSettingAndSavingPronouns() throws {
        // Step 1: Arrange - Create an Author in the Core Data context
        let viewContext = persistenceController.viewContext
        let author = try Nos.Author.findOrCreate(by: "testAuthor", context: viewContext) // Explicitly use Nos.Author
        author.displayName = "Test Author"

        let pronouns = "they/them"

        // Step 2: Act - Create the ProfileEditTestView and simulate UI interaction
        let view = ProfileEditTestView(author: author)
        ViewHosting.host(view: view.environment(\.managedObjectContext, viewContext))

        // Step 3: Simulate updating the pronouns field in the UI
        let expectPronounsUpdate = view.inspection.inspect { view in
            let textField = try view.find(ViewType.TextField.self, where: { label in
                try label.labelView().text().string() == "Pronouns"
            })
            try textField.setInput(pronouns)

            // Verify the pronouns are set correctly in the UI
            XCTAssertEqual(try textField.input(), pronouns)
        }
        wait(for: [expectPronounsUpdate], timeout: 0.1)

        // Step 4: Save the changes and verify Core Data updates
        try viewContext.save()

        // Step 5: Fetch the author again and verify pronouns are saved
        let fetchedAuthor = try XCTUnwrap(Nos.Author.find(by: "testAuthor", context: viewContext)) // Explicitly use Nos.Author
        XCTAssertEqual(fetchedAuthor.pronouns, pronouns, "The pronouns should match the value set and saved in the UI.")
    }
}
