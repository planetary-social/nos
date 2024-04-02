import UIKit
import Logger

extension UIImage {
    
    /// Initializes an image in memory from the file at the given URL.
    convenience init?(fileURL: URL) {
        do {
            let data = try Data(contentsOf: fileURL)
            self.init(data: data)
        } catch {
            Log.error("Error loading image from URL: \(error)")
            return nil
        }
    }
}
