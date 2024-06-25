import Foundation

extension String {
    /// A type that represents localized strings from the ‘ImagePicker‘
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
    /// with the `String`.``Swift/String/init(imagePicker:locale:)``
    /// intializer:
    ///
    /// ```swift
    /// // Accessing the localized value directly
    /// let value = String(imagePicker: .camera)
    /// value // "Camera"
    /// ```
    ///
    /// Starting in iOS 16/macOS 13/tvOS 16/watchOS 9, `LocalizedStringResource` can also
    /// be used:
    ///
    /// ```swift
    /// var resource = LocalizedStringResource(imagePicker: .camera)
    /// resource.locale = Locale(identifier: "fr") // customise language
    /// let value = String(localized: resource)    // defer lookup
    /// ```
    ///
    /// ### SwiftUI
    ///
    /// In SwiftUI, it is recommended to use `Text`.``SwiftUI/Text/init(imagePicker:)``
    /// or `LocalizedStringKey`.``SwiftUI/LocalizedStringKey/imagePicker(_:)``
    /// in order for localized values to be resolved within the SwiftUI environment:
    ///
    /// ```swift
    /// var body: some View {
    ///     List {
    ///         Text(imagePicker: .listContent)
    ///     }
    ///     .navigationTitle(.imagePicker(.navigationTitle))
    ///     .environment(\.locale, Locale(identifier: "fr"))
    /// }
    /// ```
    ///
    /// - SeeAlso: [XCStrings Tool Documentation - Using the generated source code](https://swiftpackageindex.com/liamnichols/xcstrings-tool/0.5.1/documentation/documentation/using-the-generated-source-code)
    internal struct ImagePicker: Sendable {
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
        /// Camera
        /// ```
        internal static var camera: ImagePicker {
            ImagePicker(
                key: "camera",
                arguments: [],
                table: "ImagePicker",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Camera is not available on this device
        /// ```
        internal static var cameraNotAvailable: ImagePicker {
            ImagePicker(
                key: "cameraNotAvailable",
                arguments: [],
                table: "ImagePicker",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Error uploading the file
        /// ```
        internal static var errorUploadingFile: ImagePicker {
            ImagePicker(
                key: "errorUploadingFile",
                arguments: [],
                table: "ImagePicker",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// An error was encountered when uploading the file you provided. Please try again.
        /// ```
        internal static var errorUploadingFileMessage: ImagePicker {
            ImagePicker(
                key: "errorUploadingFileMessage",
                arguments: [],
                table: "ImagePicker",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// An error was encountered when uploading the file you provided. The message was: "%@"
        /// ```
        internal static func errorUploadingFileWithMessage(_ arg1: String) -> ImagePicker {
            ImagePicker(
                key: "errorUploadingFileWithMessage",
                arguments: [
                    .object(arg1)
                ],
                table: "ImagePicker",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// You can allow camera permissions by opening the Settings app.
        /// ```
        internal static var openSettingsMessage: ImagePicker {
            ImagePicker(
                key: "openSettingsMessage",
                arguments: [],
                table: "ImagePicker",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Permissions required for %@
        /// ```
        internal static func permissionsRequired(_ arg1: String) -> ImagePicker {
            ImagePicker(
                key: "permissionsRequired",
                arguments: [
                    .object(arg1)
                ],
                table: "ImagePicker",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Photo Library
        /// ```
        internal static var photoLibrary: ImagePicker {
            ImagePicker(
                key: "photoLibrary",
                arguments: [],
                table: "ImagePicker",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Select from Photo Library
        /// ```
        internal static var selectFrom: ImagePicker {
            ImagePicker(
                key: "selectFrom",
                arguments: [],
                table: "ImagePicker",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Take photo or video
        /// ```
        internal static var takePhoto: ImagePicker {
            ImagePicker(
                key: "takePhoto",
                arguments: [],
                table: "ImagePicker",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Uploading...
        /// ```
        internal static var uploading: ImagePicker {
            ImagePicker(
                key: "uploading",
                arguments: [],
                table: "ImagePicker",
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

    internal init(imagePicker: ImagePicker, locale: Locale? = nil) {
        let bundle: Bundle = .from(description: imagePicker.bundle) ?? .main
        let key = String(describing: imagePicker.key)
        self.init(
            format: bundle.localizedString(forKey: key, value: nil, table: imagePicker.table),
            locale: locale,
            arguments: imagePicker.arguments.map(\.value)
        )
    }
}

extension Bundle {
    static func from(description: String.ImagePicker.BundleDescription) -> Bundle? {
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
    static func from(description: String.ImagePicker.BundleDescription) -> Self {
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
    /// Constant values for the ImagePicker Strings Catalog
    ///
    /// ```swift
    /// // Accessing the localized value directly
    /// let value = String(localized: .imagePicker.camera)
    /// value // "Camera"
    ///
    /// // Working with SwiftUI
    /// Text(.imagePicker.camera)
    /// ```
    ///
    /// - Note: Using ``LocalizedStringResource.ImagePicker`` requires iOS 16/macOS 13 or later. See ``String.ImagePicker`` for a backwards compatible API.
    internal struct ImagePicker: Sendable {
        /// ### Source Localization
        ///
        /// ```
        /// Camera
        /// ```
        @available(*, deprecated, message: "Use `String.ImagePicker.camera` instead. This property will be removed in the future.")
        internal var camera: LocalizedStringResource {
            LocalizedStringResource(imagePicker: .camera)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Camera is not available on this device
        /// ```
        @available(*, deprecated, message: "Use `String.ImagePicker.cameraNotAvailable` instead. This property will be removed in the future.")
        internal var cameraNotAvailable: LocalizedStringResource {
            LocalizedStringResource(imagePicker: .cameraNotAvailable)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Error uploading the file
        /// ```
        @available(*, deprecated, message: "Use `String.ImagePicker.errorUploadingFile` instead. This property will be removed in the future.")
        internal var errorUploadingFile: LocalizedStringResource {
            LocalizedStringResource(imagePicker: .errorUploadingFile)
        }

        /// ### Source Localization
        ///
        /// ```
        /// An error was encountered when uploading the file you provided. Please try again.
        /// ```
        @available(*, deprecated, message: "Use `String.ImagePicker.errorUploadingFileMessage` instead. This property will be removed in the future.")
        internal var errorUploadingFileMessage: LocalizedStringResource {
            LocalizedStringResource(imagePicker: .errorUploadingFileMessage)
        }

        /// ### Source Localization
        ///
        /// ```
        /// An error was encountered when uploading the file you provided. The message was: "%@"
        /// ```
        @available(*, deprecated, message: "Use `String.ImagePicker.errorUploadingFileWithMessage(_:)` instead. This method will be removed in the future.")
        internal func errorUploadingFileWithMessage(_ arg1: String) -> LocalizedStringResource {
            LocalizedStringResource(imagePicker: .errorUploadingFileWithMessage(arg1))
        }

        /// ### Source Localization
        ///
        /// ```
        /// You can allow camera permissions by opening the Settings app.
        /// ```
        @available(*, deprecated, message: "Use `String.ImagePicker.openSettingsMessage` instead. This property will be removed in the future.")
        internal var openSettingsMessage: LocalizedStringResource {
            LocalizedStringResource(imagePicker: .openSettingsMessage)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Permissions required for %@
        /// ```
        @available(*, deprecated, message: "Use `String.ImagePicker.permissionsRequired(_:)` instead. This method will be removed in the future.")
        internal func permissionsRequired(_ arg1: String) -> LocalizedStringResource {
            LocalizedStringResource(imagePicker: .permissionsRequired(arg1))
        }

        /// ### Source Localization
        ///
        /// ```
        /// Photo Library
        /// ```
        @available(*, deprecated, message: "Use `String.ImagePicker.photoLibrary` instead. This property will be removed in the future.")
        internal var photoLibrary: LocalizedStringResource {
            LocalizedStringResource(imagePicker: .photoLibrary)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Select from Photo Library
        /// ```
        @available(*, deprecated, message: "Use `String.ImagePicker.selectFrom` instead. This property will be removed in the future.")
        internal var selectFrom: LocalizedStringResource {
            LocalizedStringResource(imagePicker: .selectFrom)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Take photo or video
        /// ```
        @available(*, deprecated, message: "Use `String.ImagePicker.takePhoto` instead. This property will be removed in the future.")
        internal var takePhoto: LocalizedStringResource {
            LocalizedStringResource(imagePicker: .takePhoto)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Uploading...
        /// ```
        @available(*, deprecated, message: "Use `String.ImagePicker.uploading` instead. This property will be removed in the future.")
        internal var uploading: LocalizedStringResource {
            LocalizedStringResource(imagePicker: .uploading)
        }
    }

    @available(*, deprecated, message: "Use the `imagePicker(_:)` static method instead. This property will be removed in the future.") internal static let imagePicker = ImagePicker()

    internal init(imagePicker: String.ImagePicker) {
        self.init(
            imagePicker.key,
            defaultValue: imagePicker.defaultValue,
            table: imagePicker.table,
            bundle: .from(description: imagePicker.bundle)
        )
    }

    /// Creates a `LocalizedStringResource` that represents a localized value in the ‘ImagePicker‘ strings table.
    internal static func imagePicker(_ imagePicker: String.ImagePicker) -> LocalizedStringResource {
        LocalizedStringResource(imagePicker: imagePicker)
    }
}

#if canImport(SwiftUI)
import SwiftUI

@available(macOS 10.5, iOS 13, tvOS 13, watchOS 6, *)
extension Text {
    /// Creates a text view that displays a localized string defined in the ‘ImagePicker‘ strings table.
    internal init(imagePicker: String.ImagePicker) {
        if #available(macOS 13, iOS 16, tvOS 16, watchOS 9, *) {
            self.init(LocalizedStringResource(imagePicker: imagePicker))
            return
        }

        var stringInterpolation = LocalizedStringKey.StringInterpolation(literalCapacity: 0, interpolationCount: imagePicker.arguments.count)
        for argument in imagePicker.arguments {
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
        key.overrideKeyForLookup(using: imagePicker.key)

        self.init(key, tableName: imagePicker.table, bundle: .from(description: imagePicker.bundle))
    }
}

@available(macOS 10.5, iOS 13, tvOS 13, watchOS 6, *)
extension LocalizedStringKey {
    /// Creates a localized string key that represents a localized value in the ‘ImagePicker‘ strings table.
    @available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
    internal init(imagePicker: String.ImagePicker) {
        var stringInterpolation = LocalizedStringKey.StringInterpolation(literalCapacity: 0, interpolationCount: 1)

        if #available(macOS 13, iOS 16, tvOS 16, watchOS 9, *) {
            stringInterpolation.appendInterpolation(LocalizedStringResource(imagePicker: imagePicker))
        } else {
            stringInterpolation.appendInterpolation(Text(imagePicker: imagePicker))
        }

        let makeKey = LocalizedStringKey.init(stringInterpolation:)
        self = makeKey(stringInterpolation)
    }

    /// Creates a `LocalizedStringKey` that represents a localized value in the ‘ImagePicker‘ strings table.
    @available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
    internal static func imagePicker(_ imagePicker: String.ImagePicker) -> LocalizedStringKey {
        LocalizedStringKey(imagePicker: imagePicker)
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
