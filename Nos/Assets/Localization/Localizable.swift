import Foundation

let testingLocalization = ProcessInfo.processInfo.environment["TESTING_LOCALIZATION"]

/// A protocol for strings that are translated into multiple languages. See `Localized` for concrete implementation and
/// usage docs.
protocol Localizable {
    
    var template: String { get }

    /// optionally override this to provide your own key
    var key: String { get }

    /// optionally override this to provide your own namespace key
    /// defaults to the type name of the enum
    static var namespace: String { get }

    static func exportForStringsFile() -> String
}

extension Localizable {

    var key: String {
        "\(Self.namespace).\(String(describing: self))"
    }
    
    // You can modify this to perform localization, or overrides based on server or other config
    var string: String {
        let bundle = Bundle(for: CurrentBundle.self)
        var string: String
        if testingLocalization != nil {
            string = NSLocalizedString(key, tableName: "Generated", bundle: bundle, comment: "")
        } else {
            string = NSLocalizedString(key, tableName: "Generated", bundle: bundle, value: "not_found", comment: "")
        }
        if string == "not_found" {
            if let path = bundle.path(forResource: "en", ofType: "lproj"), let bundle = Bundle(path: path) {
                return bundle.localizedString(forKey: key, value: nil, table: "Generated")
            } else {
                return string
            }
        } else {
            return string
        }
    }
    
    static var namespace: String {
        String(describing: self)
    }
    
    // escape newlines in templates, used when exporting templates for Localizable.strings
    var escapedTemplate: String {
        template.replacingOccurrences(of: "\n", with: "\\n")
    }
}

extension Localizable {
    var description: String {
        string
    }
}

extension Localizable where Self: RawRepresentable, Self.RawValue == String {
    var template: String {
        rawValue
    }
}

extension Localizable where Self: CaseIterable {
    static func exportForStringsFile() -> String {
        let list = allCases.map { text in
            "\"\(text.key)\" = \"\(text.escapedTemplate)\";"
        }
        return list.joined(separator: "\n")
    }
}

fileprivate class CurrentBundle {}
