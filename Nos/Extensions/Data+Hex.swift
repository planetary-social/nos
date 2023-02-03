//
//  Data+Hex.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/3/23.
//

import Foundation

extension Data {
    var hexString: String {
        let hexDigits = Array("0123456789abcdef".utf16)
        var hexChars = [UTF16.CodeUnit]()
        hexChars.reserveCapacity(bytes.count * 2)
    
        for byte in self {
        let (index1, index2) = Int(byte).quotientAndRemainder(dividingBy: 16)
            hexChars.append(hexDigits[index1])
            hexChars.append(hexDigits[index2])
        }
    
        return String(utf16CodeUnits: hexChars, count: hexChars.count)
    }
}
