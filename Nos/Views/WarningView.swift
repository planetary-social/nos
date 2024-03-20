import SwiftUI

/// A view that puts a note behind a content warning if appropriate.
struct WarningView: View {
    
    @Bindable var controller: NoteWarningController
    
    var body: some View {
        if !controller.showWarning {
            EmptyView()
        } else if !controller.noteReports.isEmpty || !controller.authorReports.isEmpty {
            OverlayContentReportView(controller: controller)
        } else if controller.outOfNetwork {
            OutOfNetworkView(controller: controller)
        }
    }
}

struct OutOfNetworkView: View {
    
    @Bindable var controller: NoteWarningController
    
    @State private var isTextBoxShown = false
    @State private var isOverlayHelpTextBoxShown = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                Button(action: {
                    self.isOverlayHelpTextBoxShown.toggle()
                }, label: {
                    (isTextBoxShown ? Image.x : Image.info)
                        .resizable()
                        .frame(width: 24, height: 24)
                })
                .padding(.trailing, 24)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, 24)
            
            // Center align the content
            VStack(alignment: .center) {
                Spacer() // pushes content to the center
                
                if self.isOverlayHelpTextBoxShown {
                    Text(.localizable.outsideNetworkExplanation)
                        .font(.body)
                        .foregroundColor(.primaryTxt)
                        .padding(.horizontal, 24)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(.localizable.outsideNetwork)
                        .font(.body)
                        .foregroundColor(.primaryTxt)
                        .padding(.horizontal, 24)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                SecondaryActionButton(title: .localizable.viewThisPostAnyway) {
                    withAnimation {
                        controller.userHidWarning = true
                    }
                }
                .padding(.top, 10) // Move the button closer to the text
                
                Spacer() // pushes content to the center
            }
            .frame(maxWidth: .infinity) // Allow the VStack to take full width
            Spacer(minLength: 30) // Ensure there's some spacing at the bottom
        }
    }
}

struct OverlayContentReportView: View {
    
    @Bindable var controller: NoteWarningController
    
    @State private var isTextBoxShown = false
    @State var isOverlayHelpTextBoxShown = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                Button(action: {
                    withAnimation {
                        self.isOverlayHelpTextBoxShown.toggle()
                    }
                }, label: {
                    (isTextBoxShown ? Image.x : Image.info)
                        .resizable()
                        .frame(width: 24, height: 24)
                })
                .padding(.trailing, 24)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, 24)
            
            // Center align the content
            VStack(alignment: .center) {
                Spacer() // pushes content to the center
                
                // TextBox or Image based on isTextBoxShown
                if self.isOverlayHelpTextBoxShown {
                    Text(.localizable.contentWarningExplanation)
                        .font(.body)
                        .foregroundColor(.secondaryTxt)
                        .padding(.horizontal, 24)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)
                } else {
                    
                    Image.warningEye
                        .scaledToFit()
                        .frame(width: 48, height: 48) // Set the width and height to 48
                        .padding(.bottom, 20)
                    if controller.authorReports.count > 0 {
                        ContentWarningMessage(reports: controller.authorReports, type: "author")
                    } else if controller.noteReports.count > 0 {
                        ContentWarningMessage(reports: controller.noteReports, type: "note")
                    }
                }
                SecondaryActionButton(title: .localizable.viewThisPostAnyway) {
                    withAnimation {
                        controller.userHidWarning = true
                    }
                }
                .padding(.top, 10) // Move the button closer to the text
                
                Spacer() // pushes content to the center
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            Spacer(minLength: 30) // Ensure there's some spacing at the bottom
            
        }
    }
}

struct ContentWarningMessage: View {
    var reports: [Event]
    var type: String
    
    // Assuming each 'Event' has an 'Author' and we can get an array of 'Author' names
    private var authorNames: [String] {
        // Extracting author names. Adjust according to your actual data structure.
        reports.compactMap { $0.author?.name }
    }
    
    // Assuming there's a property or method 'safeName' in 'Author' that safely returns the author's name.
    private var firstAuthorSafeName: String {
        // Getting the safe name of the first author. Adjust according to your actual data structure.
        reports.first?.author?.safeName ?? String(localized: .localizable.unknownAuthor)
    }
    
    private var reason: String {
        // Extract content from reports and remove empty content
        let contents = reports.compactMap { $0.content }.filter({ !$0.isEmpty })

        // Convert set of unique reasons to array and remove any empty reasons
        let reasons = uniqueReasons.filter { !$0.isEmpty }
        
        // Combine both arrays
        let combined = contents + reasons
        
        // Join them with comma separator
        return combined.joined(separator: ", ")
    }
    
    private var uniqueReasons: Set<String> {
        var reasons = [String]()
        for report in reports {
            guard let reportTags = report.allTags as? [[String]] else {
                print("Error: Cannot convert allTags to [[String]]")
                continue
            }
            for tag in reportTags where tag.count >= 2 {
                let reasonCode = tag[1]
                var reason = reasonCode
                if reasonCode.hasPrefix("MOD>") {
                    let codeSuffix = String(reasonCode.dropFirst(4)) // Drop "MOD>" prefix
                    if let reportCategory = ReportCategory.findCategory(from: codeSuffix) {
                        reason = reportCategory.displayName
                    }
                } else if tag[0] == "report" {
                    reasons.append(reason)
                } else if tag.count == 3 && !reasonCode.hasPrefix("MOD>") {
                    reasons.append(tag[2])
                }
            }
        }
        return Set(reasons)
    }
    
    var message: LocalizedStringResource {
        if type == "author" {
            if authorNames.count > 1 {
                return .localizable.userReportedByOneAndMore(firstAuthorSafeName, authorNames.count - 1, reason)
            } else {
                return .localizable.userReportedByOne(firstAuthorSafeName, reason)
            }
        } else if type == "note" {
            if authorNames.count > 1 {
                return .localizable.noteReportedByOneAndMore(firstAuthorSafeName, authorNames.count - 1, reason)
            } else {
                return .localizable.noteReportedByOne(firstAuthorSafeName, reason)
            }
        }
        
        return .localizable.error
    }
    
    var body: some View {
        Text(message)
            .font(.body)
            .foregroundColor(.primaryTxt)
            .padding(.horizontal, 25)
    }
}

#Preview {
    var previewData = PreviewData()
    
    return VStack {
        ContentWarningMessage(reports: [previewData.shortNoteReportOne], type: "author")
        ContentWarningMessage(reports: [previewData.shortNoteReportOne, previewData.shortNoteReportTwo], type: "author")
        ContentWarningMessage(
            reports: [
                previewData.shortNoteReportOne,
                previewData.shortNoteReportTwo,
                previewData.shortNoteReportThree
            ],
            type: "author"
        )
        ContentWarningMessage(reports: [previewData.shortNoteReportOne], type: "note")
        ContentWarningMessage(reports: [previewData.shortNoteReportOne, previewData.shortNoteReportTwo], type: "note")
        ContentWarningMessage(
            reports: [
                previewData.shortNoteReportOne,
                previewData.shortNoteReportTwo,
                previewData.shortNoteReportThree
            ],
            type: "note"
        )
    }
    .inject(previewData: previewData)
}
