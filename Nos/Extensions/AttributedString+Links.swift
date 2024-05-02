import Foundation

extension AttributedString {

    /// Return all links found in the AttributedString instance.
    var links: [(key: String, value: URL)] {
        runs.compactMap {
            guard let link = $0.link else {
                return nil
            }
            return (key: String(self[$0.range].characters), value: link)
        }
    }
}
