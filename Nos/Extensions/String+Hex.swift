//
//  String+Hex.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/7/23.
//

import Foundation
import CryptoKit

extension String {
    
    var hexDecoded: Data? {
        // https://stackoverflow.com/a/62517446/982195
        let stringArray = Array(self)
        var data: Data = Data()
        for i in stride(from: 0, to: count, by: 2) {
            let pair: String = String(stringArray[i]) + String(stringArray[i+1])
            if let byteNum = UInt8(pair, radix: 16) {
                let byte = Data([byteNum])
                data.append(byte)
            } else {
                fatalError()
            }
        }
        return data
    }
}
