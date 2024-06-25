import Foundation

extension String {
    /// A type that represents localized strings from the ‘Moderation‘
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
    /// with the `String`.``Swift/String/init(moderation:locale:)``
    /// intializer:
    ///
    /// ```swift
    /// // Accessing the localized value directly
    /// let value = String(moderation: .bisexualPorn)
    /// value // "Bisexual porn"
    /// ```
    ///
    /// Starting in iOS 16/macOS 13/tvOS 16/watchOS 9, `LocalizedStringResource` can also
    /// be used:
    ///
    /// ```swift
    /// var resource = LocalizedStringResource(moderation: .bisexualPorn)
    /// resource.locale = Locale(identifier: "fr") // customise language
    /// let value = String(localized: resource)    // defer lookup
    /// ```
    ///
    /// ### SwiftUI
    ///
    /// In SwiftUI, it is recommended to use `Text`.``SwiftUI/Text/init(moderation:)``
    /// or `LocalizedStringKey`.``SwiftUI/LocalizedStringKey/moderation(_:)``
    /// in order for localized values to be resolved within the SwiftUI environment:
    ///
    /// ```swift
    /// var body: some View {
    ///     List {
    ///         Text(moderation: .listContent)
    ///     }
    ///     .navigationTitle(.moderation(.navigationTitle))
    ///     .environment(\.locale, Locale(identifier: "fr"))
    /// }
    /// ```
    ///
    /// - SeeAlso: [XCStrings Tool Documentation - Using the generated source code](https://swiftpackageindex.com/liamnichols/xcstrings-tool/0.5.1/documentation/documentation/using-the-generated-source-code)
    internal struct Moderation: Sendable {
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
        /// Bisexual porn
        /// ```
        internal static var bisexualPorn: Moderation {
            Moderation(
                key: "bisexualPorn",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Bodily Harm
        /// ```
        internal static var bodilyHarm: Moderation {
            Moderation(
                key: "bodilyHarm",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Casual nudity
        /// ```
        internal static var casualNudity: Moderation {
            Moderation(
                key: "casualNudity",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Child Sexual Abuse
        /// ```
        internal static var childSexualAbuse: Moderation {
            Moderation(
                key: "childSexualAbuse",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Coarse Language or Intolerance
        /// ```
        internal static var coarseLanguage: Moderation {
            Moderation(
                key: "coarseLanguage",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Copyright Violation
        /// ```
        internal static var copyrightViolation: Moderation {
            Moderation(
                key: "copyrightViolation",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Drug-related crime
        /// ```
        internal static var drugRelatedCrime: Moderation {
            Moderation(
                key: "drugRelatedCrime",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Erotica
        /// ```
        internal static var erotica: Moderation {
            Moderation(
                key: "erotica",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Financial Harm
        /// ```
        internal static var financialHarm: Moderation {
            Moderation(
                key: "financialHarm",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Fraud & Scams
        /// ```
        internal static var fraudAndScams: Moderation {
            Moderation(
                key: "fraudAndScams",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Gay male porn
        /// ```
        internal static var gayMalePorn: Moderation {
            Moderation(
                key: "gayMalePorn",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Gender-fluid / non-binary porn
        /// ```
        internal static var genderFluidNonBinaryPorn: Moderation {
            Moderation(
                key: "genderFluidNonBinaryPorn",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Harassment
        /// ```
        internal static var harassment: Moderation {
            Moderation(
                key: "harassment",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Harassment, Stalking, or Doxxing
        /// ```
        internal static var harassmentStalkingOrDoxxing: Moderation {
            Moderation(
                key: "harassmentStalkingOrDoxxing",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Heterosexual Porn
        /// ```
        internal static var heterosexualPorn: Moderation {
            Moderation(
                key: "heterosexualPorn",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Illegal
        /// ```
        internal static var illegal: Moderation {
            Moderation(
                key: "illegal",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Impersonation
        /// ```
        internal static var impersonation: Moderation {
            Moderation(
                key: "impersonation",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Intolerance & Hate
        /// ```
        internal static var intoleranceAndHate: Moderation {
            Moderation(
                key: "intoleranceAndHate",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Lesbian porn
        /// ```
        internal static var lesbianPorn: Moderation {
            Moderation(
                key: "lesbianPorn",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Likely to cause harm
        /// ```
        internal static var likelyToCauseHarm: Moderation {
            Moderation(
                key: "likelyToCauseHarm",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Malware
        /// ```
        internal static var malware: Moderation {
            Moderation(
                key: "malware",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// NSFW
        /// ```
        internal static var nsfw: Moderation {
            Moderation(
                key: "nsfw",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Nudity or Sexual Content
        /// ```
        internal static var nudityAndSex: Moderation {
            Moderation(
                key: "nudityAndSex",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Other
        /// ```
        internal static var other: Moderation {
            Moderation(
                key: "other",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Pornography
        /// ```
        internal static var pornography: Moderation {
            Moderation(
                key: "pornography",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Prostitution
        /// ```
        internal static var prostitution: Moderation {
            Moderation(
                key: "prostitution",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Sex
        /// ```
        internal static var sex: Moderation {
            Moderation(
                key: "sex",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Spam
        /// ```
        internal static var spam: Moderation {
            Moderation(
                key: "spam",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Transsexual porn
        /// ```
        internal static var transsexualPorn: Moderation {
            Moderation(
                key: "transsexualPorn",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Violence
        /// ```
        internal static var violence: Moderation {
            Moderation(
                key: "violence",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Violence towards a human being
        /// ```
        internal static var violenceTowardsAHumanBeing: Moderation {
            Moderation(
                key: "violenceTowardsAHumanBeing",
                arguments: [],
                table: "Moderation",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Violence towards a sentient animal
        /// ```
        internal static var violenceTowardsASentientAnimal: Moderation {
            Moderation(
                key: "violenceTowardsASentientAnimal",
                arguments: [],
                table: "Moderation",
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

    internal init(moderation: Moderation, locale: Locale? = nil) {
        let bundle: Bundle = .from(description: moderation.bundle) ?? .main
        let key = String(describing: moderation.key)
        self.init(
            format: bundle.localizedString(forKey: key, value: nil, table: moderation.table),
            locale: locale,
            arguments: moderation.arguments.map(\.value)
        )
    }
}

extension Bundle {
    static func from(description: String.Moderation.BundleDescription) -> Bundle? {
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
    static func from(description: String.Moderation.BundleDescription) -> Self {
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
    /// Constant values for the Moderation Strings Catalog
    ///
    /// ```swift
    /// // Accessing the localized value directly
    /// let value = String(localized: .moderation.bisexualPorn)
    /// value // "Bisexual porn"
    ///
    /// // Working with SwiftUI
    /// Text(.moderation.bisexualPorn)
    /// ```
    ///
    /// - Note: Using ``LocalizedStringResource.Moderation`` requires iOS 16/macOS 13 or later. See ``String.Moderation`` for a backwards compatible API.
    internal struct Moderation: Sendable {
        /// ### Source Localization
        ///
        /// ```
        /// Bisexual porn
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.bisexualPorn` instead. This property will be removed in the future.")
        internal var bisexualPorn: LocalizedStringResource {
            LocalizedStringResource(moderation: .bisexualPorn)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Bodily Harm
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.bodilyHarm` instead. This property will be removed in the future.")
        internal var bodilyHarm: LocalizedStringResource {
            LocalizedStringResource(moderation: .bodilyHarm)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Casual nudity
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.casualNudity` instead. This property will be removed in the future.")
        internal var casualNudity: LocalizedStringResource {
            LocalizedStringResource(moderation: .casualNudity)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Child Sexual Abuse
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.childSexualAbuse` instead. This property will be removed in the future.")
        internal var childSexualAbuse: LocalizedStringResource {
            LocalizedStringResource(moderation: .childSexualAbuse)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Coarse Language or Intolerance
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.coarseLanguage` instead. This property will be removed in the future.")
        internal var coarseLanguage: LocalizedStringResource {
            LocalizedStringResource(moderation: .coarseLanguage)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Copyright Violation
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.copyrightViolation` instead. This property will be removed in the future.")
        internal var copyrightViolation: LocalizedStringResource {
            LocalizedStringResource(moderation: .copyrightViolation)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Drug-related crime
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.drugRelatedCrime` instead. This property will be removed in the future.")
        internal var drugRelatedCrime: LocalizedStringResource {
            LocalizedStringResource(moderation: .drugRelatedCrime)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Erotica
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.erotica` instead. This property will be removed in the future.")
        internal var erotica: LocalizedStringResource {
            LocalizedStringResource(moderation: .erotica)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Financial Harm
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.financialHarm` instead. This property will be removed in the future.")
        internal var financialHarm: LocalizedStringResource {
            LocalizedStringResource(moderation: .financialHarm)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Fraud & Scams
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.fraudAndScams` instead. This property will be removed in the future.")
        internal var fraudAndScams: LocalizedStringResource {
            LocalizedStringResource(moderation: .fraudAndScams)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Gay male porn
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.gayMalePorn` instead. This property will be removed in the future.")
        internal var gayMalePorn: LocalizedStringResource {
            LocalizedStringResource(moderation: .gayMalePorn)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Gender-fluid / non-binary porn
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.genderFluidNonBinaryPorn` instead. This property will be removed in the future.")
        internal var genderFluidNonBinaryPorn: LocalizedStringResource {
            LocalizedStringResource(moderation: .genderFluidNonBinaryPorn)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Harassment
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.harassment` instead. This property will be removed in the future.")
        internal var harassment: LocalizedStringResource {
            LocalizedStringResource(moderation: .harassment)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Harassment, Stalking, or Doxxing
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.harassmentStalkingOrDoxxing` instead. This property will be removed in the future.")
        internal var harassmentStalkingOrDoxxing: LocalizedStringResource {
            LocalizedStringResource(moderation: .harassmentStalkingOrDoxxing)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Heterosexual Porn
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.heterosexualPorn` instead. This property will be removed in the future.")
        internal var heterosexualPorn: LocalizedStringResource {
            LocalizedStringResource(moderation: .heterosexualPorn)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Illegal
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.illegal` instead. This property will be removed in the future.")
        internal var illegal: LocalizedStringResource {
            LocalizedStringResource(moderation: .illegal)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Impersonation
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.impersonation` instead. This property will be removed in the future.")
        internal var impersonation: LocalizedStringResource {
            LocalizedStringResource(moderation: .impersonation)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Intolerance & Hate
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.intoleranceAndHate` instead. This property will be removed in the future.")
        internal var intoleranceAndHate: LocalizedStringResource {
            LocalizedStringResource(moderation: .intoleranceAndHate)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Lesbian porn
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.lesbianPorn` instead. This property will be removed in the future.")
        internal var lesbianPorn: LocalizedStringResource {
            LocalizedStringResource(moderation: .lesbianPorn)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Likely to cause harm
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.likelyToCauseHarm` instead. This property will be removed in the future.")
        internal var likelyToCauseHarm: LocalizedStringResource {
            LocalizedStringResource(moderation: .likelyToCauseHarm)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Malware
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.malware` instead. This property will be removed in the future.")
        internal var malware: LocalizedStringResource {
            LocalizedStringResource(moderation: .malware)
        }

        /// ### Source Localization
        ///
        /// ```
        /// NSFW
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.nsfw` instead. This property will be removed in the future.")
        internal var nsfw: LocalizedStringResource {
            LocalizedStringResource(moderation: .nsfw)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Nudity or Sexual Content
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.nudityAndSex` instead. This property will be removed in the future.")
        internal var nudityAndSex: LocalizedStringResource {
            LocalizedStringResource(moderation: .nudityAndSex)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Other
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.other` instead. This property will be removed in the future.")
        internal var other: LocalizedStringResource {
            LocalizedStringResource(moderation: .other)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Pornography
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.pornography` instead. This property will be removed in the future.")
        internal var pornography: LocalizedStringResource {
            LocalizedStringResource(moderation: .pornography)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Prostitution
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.prostitution` instead. This property will be removed in the future.")
        internal var prostitution: LocalizedStringResource {
            LocalizedStringResource(moderation: .prostitution)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Sex
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.sex` instead. This property will be removed in the future.")
        internal var sex: LocalizedStringResource {
            LocalizedStringResource(moderation: .sex)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Spam
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.spam` instead. This property will be removed in the future.")
        internal var spam: LocalizedStringResource {
            LocalizedStringResource(moderation: .spam)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Transsexual porn
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.transsexualPorn` instead. This property will be removed in the future.")
        internal var transsexualPorn: LocalizedStringResource {
            LocalizedStringResource(moderation: .transsexualPorn)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Violence
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.violence` instead. This property will be removed in the future.")
        internal var violence: LocalizedStringResource {
            LocalizedStringResource(moderation: .violence)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Violence towards a human being
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.violenceTowardsAHumanBeing` instead. This property will be removed in the future.")
        internal var violenceTowardsAHumanBeing: LocalizedStringResource {
            LocalizedStringResource(moderation: .violenceTowardsAHumanBeing)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Violence towards a sentient animal
        /// ```
        @available(*, deprecated, message: "Use `String.Moderation.violenceTowardsASentientAnimal` instead. This property will be removed in the future.")
        internal var violenceTowardsASentientAnimal: LocalizedStringResource {
            LocalizedStringResource(moderation: .violenceTowardsASentientAnimal)
        }
    }

    @available(*, deprecated, message: "Use the `moderation(_:)` static method instead. This property will be removed in the future.") internal static let moderation = Moderation()

    internal init(moderation: String.Moderation) {
        self.init(
            moderation.key,
            defaultValue: moderation.defaultValue,
            table: moderation.table,
            bundle: .from(description: moderation.bundle)
        )
    }

    /// Creates a `LocalizedStringResource` that represents a localized value in the ‘Moderation‘ strings table.
    internal static func moderation(_ moderation: String.Moderation) -> LocalizedStringResource {
        LocalizedStringResource(moderation: moderation)
    }
}

#if canImport(SwiftUI)
import SwiftUI

@available(macOS 10.5, iOS 13, tvOS 13, watchOS 6, *)
extension Text {
    /// Creates a text view that displays a localized string defined in the ‘Moderation‘ strings table.
    internal init(moderation: String.Moderation) {
        if #available(macOS 13, iOS 16, tvOS 16, watchOS 9, *) {
            self.init(LocalizedStringResource(moderation: moderation))
            return
        }

        var stringInterpolation = LocalizedStringKey.StringInterpolation(literalCapacity: 0, interpolationCount: moderation.arguments.count)
        for argument in moderation.arguments {
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
        key.overrideKeyForLookup(using: moderation.key)

        self.init(key, tableName: moderation.table, bundle: .from(description: moderation.bundle))
    }
}

@available(macOS 10.5, iOS 13, tvOS 13, watchOS 6, *)
extension LocalizedStringKey {
    /// Creates a localized string key that represents a localized value in the ‘Moderation‘ strings table.
    @available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
    internal init(moderation: String.Moderation) {
        var stringInterpolation = LocalizedStringKey.StringInterpolation(literalCapacity: 0, interpolationCount: 1)

        if #available(macOS 13, iOS 16, tvOS 16, watchOS 9, *) {
            stringInterpolation.appendInterpolation(LocalizedStringResource(moderation: moderation))
        } else {
            stringInterpolation.appendInterpolation(Text(moderation: moderation))
        }

        let makeKey = LocalizedStringKey.init(stringInterpolation:)
        self = makeKey(stringInterpolation)
    }

    /// Creates a `LocalizedStringKey` that represents a localized value in the ‘Moderation‘ strings table.
    @available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
    internal static func moderation(_ moderation: String.Moderation) -> LocalizedStringKey {
        LocalizedStringKey(moderation: moderation)
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
