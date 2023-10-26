//
//  WarningView.swift
//  Nos
//
//  Created by Matthew Lorentz on 10/26/23.
//

import SwiftUI

/// A view that puts a note behind a content warning if appropriate.
struct WarningView: View {
    
    @ObservedObject var controller: NoteWarningController
    
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
    
    @ObservedObject var controller: NoteWarningController
    
    @State private var isTextBoxShown: Bool = false
    @State private var isOverlayHelpTextBoxShown: Bool = false
    
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
                    Localized.outsideNetworkExplanation.view
                        .font(.body)
                        .foregroundColor(.secondaryText)
                        .background {
                            Color.cardBackground
                                .blur(radius: 8, opaque: false)
                        }
                        .padding(.horizontal, 24)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Localized.outsideNetwork.view
                        .font(.body)
                        .foregroundColor(.secondaryText)
                        .background {
                            Color.cardBackground
                                .blur(radius: 8, opaque: false)
                        }
                        .padding(.horizontal, 24)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                SecondaryActionButton(title: Localized.viewThisPostAnyway) {
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
    
    @ObservedObject var controller: NoteWarningController
    
    @State private var isTextBoxShown: Bool = false
    @State var isOverlayHelpTextBoxShown: Bool = false
    
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
                    Localized.contentWarningExplanation.view
                        .font(.body)
                        .foregroundColor(.secondaryText)
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
                SecondaryActionButton(title: Localized.viewThisPostAnyway) {
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
        reports.first?.author?.safeName ?? "Unknown Author"
    }
    
    private var reason: String {
        // Extract content from reports and remove empty content
        let contents = reports.compactMap { (($0.content?.isEmpty) != nil) ? nil : $0.content }
        
        // Convert set of unique reasons to array and remove any empty reasons
        let reasons = uniqueReasons.filter { !$0.isEmpty }
        
        // Combine both arrays
        let combined = contents + reasons
        
        // Join them with comma separator
        return combined.joined(separator: ", ")
    }
    
    private var tags: [[String]] {
        var allTags = [[String]]()
        for report in reports {
            guard let reportTags = report.allTags as? [[String]] else {
                print("Error: Cannot convert allTags to [[String]]")
                continue
            }
            allTags.append(contentsOf: reportTags)
        }
        return allTags
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
                }
                else if tag[0] == "report" {
                    reasons.append(reason)
                } else if tag.count == 3 && !reasonCode.hasPrefix("MOD>") {
                    reasons.append(tag[2])
                }
            }
        }
        return Set(reasons)
    }
    
    var body: some View {
        if type == "author" {
            Text( Localized.userHasBeen )
                .font(.body)
                .foregroundColor(.secondaryText)
                .background {
                    Color.cardBackground
                        .blur(radius: 8, opaque: false)
                }
        } else if type == "note" {
            Text( Localized.noteHasBeen )
                .font(.body)
                .foregroundColor(.secondaryText)
                .background {
                    Color.cardBackground
                        .blur(radius: 8, opaque: false)
                }
        }
        if authorNames.count > 1 {
            Text(Localized.reportedByOneAndMore.localizedMarkdown([
                "one": firstAuthorSafeName,
                "count": "\(authorNames.count - 1)"
            ]))
            .font(.body)  // Adjust font and style as needed
            .foregroundColor(.primary)
            .padding(.leading, 25)  // Adjust padding as needed
        } else {
            Text(Localized.reportedByOne.localizedMarkdown([
                "one": firstAuthorSafeName
            ]))
            .font(.body)  // Adjust font and style as needed
            .foregroundColor(.secondaryText)
            .padding(.leading, 25)  // Adjust padding as needed
        }
        
        Text( Localized.reportedFor.localizedMarkdown(["reason": reason]) )
            .font(.body)
            .foregroundColor(.secondaryText)
            .background {
                Color.cardBackground
                    .blur(radius: 8, opaque: false)
            }
    }
}

