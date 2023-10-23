//
//  BigDecimal.swift
//  GIDNonCustodianWallet
//
//  Created by Marcel on 27/10/2023.
//
//

import Foundation

/// A wrapper for the BigNumber.js BigNumber representation.
/// https://mikemcl.github.io/bignumber.js
public struct BigDecimal {

    /// BigNumber as string. Nil otherwise
    public let amount: String?
    public var hex: String? {
        guard let hexString = Web3Utils.shared.hex(from: self) else {
            return nil
        }
        return hexString
    }

    // MARK: - Init

    public init(_ uint: UInt64) {
        amount = Web3Utils.shared.parseToBigInt(from: (try? String(uint)) ?? "")
    }

    public init(_ stringValue: String) {
        amount = Web3Utils.shared.parseToBigInt(from: stringValue)
    }

    public init(hexString: String) {
        amount = Web3Utils.shared.parseToBigInt(from: hexString)
    }

    // MARK: - Interface

    func isValid() -> Bool {
        amount != nil
    }
}

// MARK: - Comparable

extension BigDecimal: Comparable {

    public static func < (lhs: BigDecimal, rhs: BigDecimal) -> Bool {
        Web3Utils.shared.isLhs(lhs, lessThan: rhs)
    }
}

// MARK: - AdditiveArithmetic

extension BigDecimal: AdditiveArithmetic {

    public static var zero: BigDecimal {
        BigDecimal("0")
    }

    public static func + (lhs: BigDecimal, rhs: BigDecimal) -> BigDecimal {
        Web3Utils.shared.add(lhs: lhs, rhs: rhs)
    }

    public static func - (lhs: BigDecimal, rhs: BigDecimal) -> BigDecimal {
        Web3Utils.shared.subtract(lhs: lhs, with: rhs)
    }
}

// MARK: - Multiply

extension BigDecimal {

    public static func * (lhs: BigDecimal, rhs: BigDecimal) -> BigDecimal {
        Web3Utils.shared.multiply(lhs: lhs, with: rhs)
    }
}
