import Foundation
import CryptoKit

extension String {
    
    var hexDecoded: Data? {
        guard self.count.isMultiple(of: 2) else { return nil }
        
        // https://stackoverflow.com/a/62517446/982195
        let stringArray = Array(self)
        var data = Data()
        for i in stride(from: 0, to: count, by: 2) {
            let pair = String(stringArray[i]) + String(stringArray[i + 1])
            if let byteNum = UInt8(pair, radix: 16) {
                let byte = Data([byteNum])
                data.append(byte)
            } else {
                return nil
            }
        }
        return data
    }
    
    var isValidHexadecimal: Bool {
        let regex = "^[0-9a-fA-F]+$"
        return range(of: regex, options: .regularExpression) != nil
    }
}
