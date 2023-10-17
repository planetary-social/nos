//
//  String+Extra.swift
//  DAppExample
//
//  Created by Marcel Salej on 27/09/2023.
//

import Foundation
import SwiftUI
import CoreImage.CIFilterBuiltins
import UIKit

extension String {
    func generateQRCode() -> Image {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        let data = Data(self.utf8)
        filter.setValue(data, forKey: "inputMessage")
        let transform = CGAffineTransform(scaleX: 4, y: 4)
        if let qrCodeImage = filter.outputImage?.transformed(by: transform) {
            if let qrCodeCGImage = context.createCGImage(qrCodeImage, from: qrCodeImage.extent) {
                return Image(uiImage: UIImage(cgImage: qrCodeCGImage))
            }
        }

        return Image("")
    }

    func deleting0x() -> String {
        var string = self
        if starts(with: "0x") {
            string.removeFirst(2)
        }
        return string
    }
}
