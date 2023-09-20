//
//  ExportStrings.swift
//  Nos
//
//  Created by Martin Dutra on 23/3/23.
//
//  This file is executed during the Run Phase in a Run Script action
//  it is not to be included in an app target.

typealias TranslationKey = String
typealias Translation = String

extension Localized {
    static func writeFiles(to path: String, locale primaryLocale: String = "en") {
        let stringsFileName = "Generated.strings"
        let directory = NSURL(fileURLWithPath: FileManager().currentDirectoryPath + path, isDirectory: true)

        guard let primaryLocation = directory.appendingPathComponent("\(primaryLocale).lproj/\(stringsFileName)") else {
            return
        }

        let newPrimaryLocaleStrings = localizableTypes.map { $0.exportForStringsFile() }.joined(separator: "\n\n")

        let primaryText = "// This file is auto-generated at build time and should not be modified by hand\n\n"
            + newPrimaryLocaleStrings

        write(text: primaryText, file: primaryLocation)
    }

    static func write(text: String, file: URL) {
        try? FileManager().createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? text.write(to: file, atomically: true, encoding: .utf8)
    }
}

/// Converts a Generated.strings file into a dictionary of translation keys and translation strings.
func dictionary(fromGeneratedStrings generatedStrings: String) -> [TranslationKey: Translation] {
    var dict = [TranslationKey: Translation]()

    for line in generatedStrings.components(separatedBy: "\n") {
        let components = line.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: true)
        guard components.count == 2 else {
            // comment or blank line
            continue
        }

        let trimmedComponents = components.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let key = trimmedComponents[0]
        let translation = trimmedComponents[1]
        dict[key] = translation
    }

    return dict
}

Localized.writeFiles(to: "/Nos/Assets/Localization", locale: "en")
