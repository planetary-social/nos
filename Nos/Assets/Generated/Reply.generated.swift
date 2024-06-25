import Foundation

extension String {
    /// A type that represents localized strings from the ‘Reply‘
    /// strings table.
    ///
    /// Do not initialize instances of this type yourself, instead use one of the static
    /// methods or properties that have been generated automatically.
    ///
    /// ## Usage
    ///
    /// ### Foundation
    ///
    /// In Foundation, you can resolve the localized string using the system language
    /// with the `String`.``Swift/String/init(reply:locale:)``
    /// intializer:
    ///
    /// ```swift
    /// // Accessing the localized value directly
    /// let value = String(reply: .mentionedYou)
    /// value // "mentioned you:"
    /// ```
    ///
    /// Starting in iOS 16/macOS 13/tvOS 16/watchOS 9, `LocalizedStringResource` can also
    /// be used:
    ///
    /// ```swift
    /// var resource = LocalizedStringResource(reply: .mentionedYou)
    /// resource.locale = Locale(identifier: "fr") // customise language
    /// let value = String(localized: resource)    // defer lookup
    /// ```
    ///
    /// ### SwiftUI
    ///
    /// In SwiftUI, it is recommended to use `Text`.``SwiftUI/Text/init(reply:)``
    /// or `LocalizedStringKey`.``SwiftUI/LocalizedStringKey/reply(_:)``
    /// in order for localized values to be resolved within the SwiftUI environment:
    ///
    /// ```swift
    /// var body: some View {
    ///     List {
    ///         Text(reply: .listContent)
    ///     }
    ///     .navigationTitle(.reply(.navigationTitle))
    ///     .environment(\.locale, Locale(identifier: "fr"))
    /// }
    /// ```
    ///
    /// - SeeAlso: [XCStrings Tool Documentation - Using the generated source code](https://swiftpackageindex.com/liamnichols/xcstrings-tool/0.5.1/documentation/documentation/using-the-generated-source-code)
    internal struct Reply: Sendable {
        enum BundleDescription: Sendable {
            case main
            case atURL(URL)
            case forClass(AnyClass)

            #if !SWIFT_PACKAGE
            private class BundleLocator {
            }
            #endif

            static var current: BundleDescription {
                #if SWIFT_PACKAGE
                .atURL(Bundle.module.bundleURL)
                #else
                .forClass(BundleLocator.self)
                #endif
            }
        }

        enum Argument: Sendable {
            case int(Int)
            case uint(UInt)
            case float(Float)
            case double(Double)
            case object(String)

            var value: any CVarArg {
                switch self {
                case .int(let value):
                    value
                case .uint(let value):
                    value
                case .float(let value):
                    value
                case .double(let value):
                    value
                case .object(let value):
                    value
                }
            }
        }

        let key: StaticString
        let arguments: [Argument]
        let table: String?
        let bundle: BundleDescription

        fileprivate init(
            key: StaticString,
            arguments: [Argument],
            table: String?,
            bundle: BundleDescription
        ) {
            self.key = key
            self.arguments = arguments
            self.table = table
            self.bundle = bundle
        }

        /// ### Source Localization
        ///
        /// ```
        /// mentioned you:
        /// ```
        internal static var mentionedYou: Reply {
            Reply(
                key: "mentionedYou",
                arguments: [],
                table: "Reply",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Post a reply
        /// ```
        internal static var postAReply: Reply {
            Reply(
                key: "postAReply",
                arguments: [],
                table: "Reply",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// posted
        /// ```
        internal static var posted: Reply {
            Reply(
                key: "posted",
                arguments: [],
                table: "Reply",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// replied
        /// ```
        internal static var replied: Reply {
            Reply(
                key: "replied",
                arguments: [],
                table: "Reply",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// replied to your note:
        /// ```
        internal static var repliedToYourNote: Reply {
            Reply(
                key: "repliedToYourNote",
                arguments: [],
                table: "Reply",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// %lld replies
        /// ```
        internal static func replies(_ arg1: Int) -> Reply {
            Reply(
                key: "replies",
                arguments: [
                    .int(arg1)
                ],
                table: "Reply",
                bundle: .current
            )
        }

        @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
        fileprivate var defaultValue: String.LocalizationValue {
            var stringInterpolation = String.LocalizationValue.StringInterpolation(literalCapacity: 0, interpolationCount: arguments.count)
            for argument in arguments {
                switch argument {
                case .int(let value):
                    stringInterpolation.appendInterpolation(value)
                case .uint(let value):
                    stringInterpolation.appendInterpolation(value)
                case .float(let value):
                    stringInterpolation.appendInterpolation(value)
                case .double(let value):
                    stringInterpolation.appendInterpolation(value)
                case .object(let value):
                    stringInterpolation.appendInterpolation(value)
                }
            }
            let makeDefaultValue = String.LocalizationValue.init(stringInterpolation:)
            return makeDefaultValue(stringInterpolation)
        }
    }

    internal init(reply: Reply, locale: Locale? = nil) {
        let bundle: Bundle = .from(description: reply.bundle) ?? .main
        let key = String(describing: reply.key)
        self.init(
            format: bundle.localizedString(forKey: key, value: nil, table: reply.table),
            locale: locale,
            arguments: reply.arguments.map(\.value)
        )
    }
}

extension Bundle {
    static func from(description: String.Reply.BundleDescription) -> Bundle? {
        switch description {
        case .main:
            Bundle.main
        case .atURL(let url):
            Bundle(url: url)
        case .forClass(let anyClass):
            Bundle(for: anyClass)
        }
    }
}

@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
private extension LocalizedStringResource.BundleDescription {
    static func from(description: String.Reply.BundleDescription) -> Self {
        switch description {
        case .main:
            .main
        case .atURL(let url):
            .atURL(url)
        case .forClass(let anyClass):
            .forClass(anyClass)
        }
    }
}

@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
extension LocalizedStringResource {
    /// Constant values for the Reply Strings Catalog
    ///
    /// ```swift
    /// // Accessing the localized value directly
    /// let value = String(localized: .reply.mentionedYou)
    /// value // "mentioned you:"
    ///
    /// // Working with SwiftUI
    /// Text(.reply.mentionedYou)
    /// ```
    ///
    /// - Note: Using ``LocalizedStringResource.Reply`` requires iOS 16/macOS 13 or later. See ``String.Reply`` for a backwards compatible API.
    internal struct Reply: Sendable {
        /// ### Source Localization
        ///
        /// ```
        /// mentioned you:
        /// ```
        @available(*, deprecated, message: "Use `String.Reply.mentionedYou` instead. This property will be removed in the future.")
        internal var mentionedYou: LocalizedStringResource {
            LocalizedStringResource(reply: .mentionedYou)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Post a reply
        /// ```
        @available(*, deprecated, message: "Use `String.Reply.postAReply` instead. This property will be removed in the future.")
        internal var postAReply: LocalizedStringResource {
            LocalizedStringResource(reply: .postAReply)
        }

        /// ### Source Localization
        ///
        /// ```
        /// posted
        /// ```
        @available(*, deprecated, message: "Use `String.Reply.posted` instead. This property will be removed in the future.")
        internal var posted: LocalizedStringResource {
            LocalizedStringResource(reply: .posted)
        }

        /// ### Source Localization
        ///
        /// ```
        /// replied
        /// ```
        @available(*, deprecated, message: "Use `String.Reply.replied` instead. This property will be removed in the future.")
        internal var replied: LocalizedStringResource {
            LocalizedStringResource(reply: .replied)
        }

        /// ### Source Localization
        ///
        /// ```
        /// replied to your note:
        /// ```
        @available(*, deprecated, message: "Use `String.Reply.repliedToYourNote` instead. This property will be removed in the future.")
        internal var repliedToYourNote: LocalizedStringResource {
            LocalizedStringResource(reply: .repliedToYourNote)
        }

        /// ### Source Localization
        ///
        /// ```
        /// %lld replies
        /// ```
        @available(*, deprecated, message: "Use `String.Reply.replies(_:)` instead. This method will be removed in the future.")
        internal func replies(_ arg1: Int) -> LocalizedStringResource {
            LocalizedStringResource(reply: .replies(arg1))
        }
    }

    @available(*, deprecated, message: "Use the `reply(_:)` static method instead. This property will be removed in the future.") internal static let reply = Reply()

    internal init(reply: String.Reply) {
        self.init(
            reply.key,
            defaultValue: reply.defaultValue,
            table: reply.table,
            bundle: .from(description: reply.bundle)
        )
    }

    /// Creates a `LocalizedStringResource` that represents a localized value in the ‘Reply‘ strings table.
    internal static func reply(_ reply: String.Reply) -> LocalizedStringResource {
        LocalizedStringResource(reply: reply)
    }
}

#if canImport(SwiftUI)
import SwiftUI

@available(macOS 10.5, iOS 13, tvOS 13, watchOS 6, *)
extension Text {
    /// Creates a text view that displays a localized string defined in the ‘Reply‘ strings table.
    internal init(reply: String.Reply) {
        if #available(macOS 13, iOS 16, tvOS 16, watchOS 9, *) {
            self.init(LocalizedStringResource(reply: reply))
            return
        }

        var stringInterpolation = LocalizedStringKey.StringInterpolation(literalCapacity: 0, interpolationCount: reply.arguments.count)
        for argument in reply.arguments {
            switch argument {
            case .int(let value):
                stringInterpolation.appendInterpolation(value)
            case .uint(let value):
                stringInterpolation.appendInterpolation(value)
            case .float(let value):
                stringInterpolation.appendInterpolation(value)
            case .double(let value):
                stringInterpolation.appendInterpolation(value)
            case .object(let value):
                stringInterpolation.appendInterpolation(value)
            }
        }
        let makeKey = LocalizedStringKey.init(stringInterpolation:)

        var key = makeKey(stringInterpolation)
        key.overrideKeyForLookup(using: reply.key)

        self.init(key, tableName: reply.table, bundle: .from(description: reply.bundle))
    }
}

@available(macOS 10.5, iOS 13, tvOS 13, watchOS 6, *)
extension LocalizedStringKey {
    /// Creates a localized string key that represents a localized value in the ‘Reply‘ strings table.
    @available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
    internal init(reply: String.Reply) {
        var stringInterpolation = LocalizedStringKey.StringInterpolation(literalCapacity: 0, interpolationCount: 1)

        if #available(macOS 13, iOS 16, tvOS 16, watchOS 9, *) {
            stringInterpolation.appendInterpolation(LocalizedStringResource(reply: reply))
        } else {
            stringInterpolation.appendInterpolation(Text(reply: reply))
        }

        let makeKey = LocalizedStringKey.init(stringInterpolation:)
        self = makeKey(stringInterpolation)
    }

    /// Creates a `LocalizedStringKey` that represents a localized value in the ‘Reply‘ strings table.
    @available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
    internal static func reply(_ reply: String.Reply) -> LocalizedStringKey {
        LocalizedStringKey(reply: reply)
    }

    /// Updates the underlying `key` used when performing localization lookups.
    ///
    /// By default, an instance of `LocalizedStringKey` can only be created
    /// using string interpolation, so if arguments are included, the format
    /// specifiers make up part of the key.
    ///
    /// This method allows you to change the key after initialization in order
    /// to match the value that might be defined in the strings table.
    fileprivate mutating func overrideKeyForLookup(using key: StaticString) {
        withUnsafeMutablePointer(to: &self) { pointer in
            let raw = UnsafeMutableRawPointer(pointer)
            let bound = raw.assumingMemoryBound(to: String.self)
            bound.pointee = String(describing: key)
        }
    }
}
#endif
