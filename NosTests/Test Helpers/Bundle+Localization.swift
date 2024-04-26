import Foundation

// This is some AI generated code that allows us to set a specific locale in unit tests so we can do things like 
// assert on English strings no matter what locale the simulator/host is set to.

extension Bundle {
    static func setLanguage(_ language: Locale) {
        // Set the bundle's preferred localization for testing
        let testBundle = Bundle(for: ContentWarningControllerTests.self)
        testBundle.setPreferredLocalization(language)
    }
}

extension Bundle {
    func setPreferredLocalization(_ language: Locale) {
        guard = path(forResource: language.language.languageCode?.identifier, ofType: "lproj") != nil else { return }
        object_setClass(self, MockBundle.self)
        UserDefaults.standard.set([language.language.languageCode!.identifier], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }
}

class MockBundle: Bundle {
    // swiftlint:disable:next unneeded_override
    override func path(forResource name: String?, ofType type: String?) -> String? {
        super.path(forResource: name, ofType: type)
    }
}
