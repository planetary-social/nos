import Foundation
import CommonCrypto

extension Data {
    var sha256: String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(count), &hash)
        }
        let hashData = Data(hash)
        return hashData.hexString
    }
}
