import Foundation

/// Wei is the smallest unit of Ethereum, like a satoshi in Bitcoin.
public struct Wei {

    @inlinable public static var zero: Self { Wei(hex: "0x0")! }

    /// String representation of wei amount.
    public let value: BigDecimal
    public let hex: String

    // MARK: - Init

    public init?(value: BigDecimal) {
        guard let hexValue = value.hex else { return nil }
        self.value = value
        hex = hexValue
    }

    public init?(hex: String) {
        guard BigDecimal(hexString: hex).isValid() else { return nil }
        self.value = BigDecimal(hexString: hex)
        self.hex = hex
    }

    public init?(ether: Decimal) {
        guard !ether.isSignMinus, 
            let weiValue = Web3Utils.shared.weiFrom(ether: ether), 
            let hexValue = weiValue.hex else { 
            return nil 
        }

        value = weiValue
        hex = hexValue
    }

    public init?(gwei: Decimal) {
        guard !gwei.isSignMinus, 
            let weiValue = Web3Utils.shared.weiFrom(gwei: gwei), 
            let hexValue = weiValue.hex else { 
            return nil 
        }

        value = weiValue
        hex = hexValue
    }
}

// MARK: - Equatable

extension Wei: Comparable {

    public static func < (lhs: Wei, rhs: Wei) -> Bool {
        lhs.value < rhs.value
    }
}

// MARK: - Units

extension Wei {

    /// This value is to be used for UI and rounded to 18 decimal precision.
    /// For accurate amount use the `value` property.
    public var ether: Decimal? {
        Web3Utils.shared.etherFrom(wei: self)
    }

    /// This value is to be used for UI and rounded to 18 decimal precision.
    /// For accurate amount use the `value` property.
    public var gwei: Decimal? {
        Web3Utils.shared.gweiFrom(wei: self)
    }
}

// MARK: - Constants

public extension Wei {

    enum Unit {
        /// 1 Gwei = 1ETH * 10^-9
        case gwei

        /// 1 Wei = 1ETH * 10^-18
        case wei

        public var value: Int {
            switch self {
            case .gwei: return 1_000_000_000
            case .wei: return 1_000_000_000_000_000_000
            }
        }
    }
}
