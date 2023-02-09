//
//  Data+Encoding.swift
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
    
    /// Converts base two bytes to base 5
    var base5: Data {
        var outputSize = (count * 8) / 5
        if ((count * 8) % 5) != 0 {
            outputSize += 1
        }
        var outputArray: [UInt8] = []
        for i in (0..<outputSize) {
            let quotient = (i * 5) / 8
            let remainder = (i * 5) % 8
            var element = self[quotient] << remainder
            element >>= 3
            
            if (remainder > 3) && (i + 1 < outputSize) {
                element = element | (self[quotient + 1] >> (8 - remainder + 3))
            }
            
            outputArray.append(element)
        }
        
        return Data(outputArray)
    }
    
    var base8FromBase5: Data? {
        let destinationBase = 8
        let startingBase = 5
        let maxValueMask: UInt32 = ((UInt32(1)) << 8) - 1;
        var val: UInt32 = 0
        var bits: Int = 0
        var output = Data()
        
        for i in (0..<count) {
            val = (val << startingBase) | UInt32(self[i])
            bits += startingBase;
            while bits >= destinationBase {
                bits -= destinationBase;
                output.append(UInt8((val >> bits) & maxValueMask))
            }
        }
        
        if 0 != ((val << (destinationBase - bits)) & maxValueMask) || bits >= startingBase {
            return nil
        }
        
        return output
    }
}
