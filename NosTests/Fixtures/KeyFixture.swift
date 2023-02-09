//
//  KeyFixture.swift
//  NosTests
//
//  Created by Matthew Lorentz on 2/7/23.
//

import Foundation

struct KeyFixture {
    static let npub = "npub1xfesa80u4duhetursrgfde2gm8he3ua0xqq9gtujwx53483mqqqsg0cyaj"
    static let pubKeyHex = "32730e9dfcab797caf8380d096e548d9ef98f3af3000542f9271a91a9e3b0001"
    static let privateKeyHex = "69222a82c30ea0ad472745b170a560f017cb3bcc38f927a8b27e3bab3d8f0f19"
    static let nsec = "nsec1dy3z4qkrp6s263e8gkchpftq7qtukw7v8ruj029j0ca6k0v0puvs2e22yy"
    static let keyPair = KeyPair(privateKeyHex: privateKeyHex)!
}
