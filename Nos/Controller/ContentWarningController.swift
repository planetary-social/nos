import SwiftUI

enum ContentWarningType {
    case author
    case note
}

/// A class that takes a collection of content reports and generates a content warning string that can be 
/// displayed to the user.
@Observable class ContentWarningController {
    
    var reports: [Event]
    var type: ContentWarningType
    
    init(reports: [Event] = [Event](), type: ContentWarningType = .note) {
        self.reports = reports
        self.type = type
    }
    
    /// A warning that is generated based on the given `reports` and `types` explaining what this content was reported
    /// for and by whom.
    var localizedContentWarning: LocalizedStringResource {
        guard !reports.isEmpty else {
            return .localizable.anErrorOccurred
        }
        
        switch type {
        case .author:
            if authorNames.count > 1 {
                return .localizable.userReportedByOneAndMore(firstAuthorSafeName, authorNames.count - 1, reason)
            } else {
                return .localizable.userReportedByOne(firstAuthorSafeName, reason)
            }
        case .note:
            if authorNames.count > 1 {
                return .localizable.noteReportedByOneAndMore(firstAuthorSafeName, authorNames.count - 1, reason)
            } else {
                return .localizable.noteReportedByOne(firstAuthorSafeName, reason)
            }
        }
    }
    
    /// The names of the authors who made reports
    private var authorNames: [String] {
        Array(Set(reports.compactMap { $0.author?.name })).sorted()
    }
    
    /// The name of the first author in the list of reports
    private var firstAuthorSafeName: String {
        authorNames.first ?? String(localized: "unknownAuthor")
    }
    
    /// The string explaining the reason(s) for the reports.
    private var reason: String {
        let reasons = uniqueReasons
            .filter { !$0.isEmpty }
            .sorted()
            .joined(separator: ", ")
        if reasons.isEmpty {
            return String(localized: "error")
        } else {
            return reasons
        }
    }
    
    /// A set of all the reasons from all reports
    private var uniqueReasons: Set<String> {
        var reasons = [String]()
        for report in reports {
            if let reason = reasonString(from: report) {
                reasons.append(reason)
            }
        }
        return Set(reasons.map { $0.lowercased() })
    }
    
    /// Extracts a human readable string explaining the reason for the given report `Event`.
    private func reasonString(from report: Event) -> String? {
        if let reportTags = report.allTags as? [[String]] {
            // Look for NIP-32 moderation tags
            for tag in reportTags where tag.count >= 2 {
                let reasonCode = tag[1]
                if reasonCode.hasPrefix("MOD>") {
                    let codeSuffix = String(reasonCode.dropFirst(4)) // Drop "MOD>" prefix
                    if let reportCategory = ReportCategory.findCategory(from: codeSuffix) {
                        return reportCategory.displayName
                    }
                } 
            }
            
            // Look for report type
            for tag in reportTags where tag.count >= 2 {
                var tagType: String
                switch type {
                case .author:
                    tagType = "p"
                case .note:
                    tagType = "e"
                }
                if tag[safe: 0] == tagType, tag.count >= 3 {
                    return tag[2]
                } 
            }
        }
        
        // fall back to `content`
        if let contentReason = report.content, contentReason.isEmpty == false {
            return contentReason
        } else {
            return nil
        }
    }
}
