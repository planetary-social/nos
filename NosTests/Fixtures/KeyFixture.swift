//
//  KeyFixture.swift
//  NosTests
//
//  Created by Matthew Lorentz on 2/7/23.
//

import Foundation

enum KeyFixture {
    static let npub = "npub1xfesa80u4duhetursrgfde2gm8he3ua0xqq9gtujwx53483mqqqsg0cyaj"
    static let pubKeyHex = "32730e9dfcab797caf8380d096e548d9ef98f3af3000542f9271a91a9e3b0001"
    static let privateKeyHex = "69222a82c30ea0ad472745b170a560f017cb3bcc38f927a8b27e3bab3d8f0f19"
    static let nsec = "nsec1dy3z4qkrp6s263e8gkchpftq7qtukw7v8ruj029j0ca6k0v0puvs2e22yy"
    static let keyPair = KeyPair(privateKeyHex: privateKeyHex)!
    
    static let alice = KeyPair(nsec: "nsec1x0md460pkpmuwu5auvzhtfnx3vahkxu83n9w26m5dy9243q6mgls0zsffn")!
    static let bob = KeyPair(nsec: "nsec1kvlwl8reastryhd75tsj879da6mmk744kl56l7q0sl237x8dqy9qwqqz4g")!
    static let eve = KeyPair(nsec: "nsec16mw0dqelfjumkq3xxqh0zkfkzpyk06mk37a752x35wts7m30y6lsecl6zr")!
    static let emptyProfile = KeyPair(nsec: "nsec1kqzd5ctfh4j8hqvs3076zgruylz0das00wwfed67dzeevjcqls9s2ate2u")!
}
