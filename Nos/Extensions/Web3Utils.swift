//
//  Web3Utils.swift
//  DAppExample
//
//  Created by Marcel Salej on 02/10/2023.
//

import WebKit
import JavaScriptCore

/// This class uses a javascript library to perform big number conversions. https://mikemcl.github.io/bignumber.js/
/// The reason we decided for this library is because it is used by 1.1M repositories and has 5.9k stars.
public final class Web3Utils {

    // MARK: - Properties

    public static let shared = Web3Utils()
    let jsContext = JSContext()!

    // MARK: - Init

    private init() {
        injectJavaScriptCode(into: jsContext)
    }

    // MARK: - Setup

    /// Adds the javascript code to the given context.
    /// - Parameter context: the javsacript context
    private func injectJavaScriptCode(into context: JSContext) {
        guard
            let bigNumberJS = Bundle.main.url(forResource: "bignumber", withExtension: "js"),
            let bigNumberContents = try? String(contentsOf: bigNumberJS)
        else {
            fatalError("Missing javascript file bignumber.js")
        }

        context.evaluateScript(bigNumberContents)
        context.evaluateScript(weiConversionsJS)
        context.evaluateScript(erc20tokenJS)
        context.evaluateScript(bigUintOperationsJS)
    }
}

extension Web3Utils {

    // MARK: - Operations

    public func add(lhs: BigDecimal, rhs: BigDecimal) -> BigDecimal {
        guard let jsFunction = jsContext.objectForKeyedSubscript("add"),
            let valueString = jsFunction.call(withArguments: [lhs.amount!, rhs.amount!]).toString(),
            valueString != "NaN" else {
            fatalError("Web3Utils error in JavaScript.")
        }
        return BigDecimal(valueString)
    }

    public func subtract(lhs: BigDecimal, with rhs: BigDecimal) -> BigDecimal {
        guard let jsFunction = jsContext.objectForKeyedSubscript("subtract"),
            let valueString = jsFunction.call(withArguments: [lhs.amount!, rhs.amount!]).toString(),
            valueString != "NaN" else {
            fatalError("NcwWeb3Utils error in JavaScript.")
        }
        return BigDecimal(valueString)
    }

    public func multiply(lhs: BigDecimal, with rhs: BigDecimal) -> BigDecimal {
        guard let jsFunction = jsContext.objectForKeyedSubscript("multiply"),
            let valueString = jsFunction.call(withArguments: [lhs.amount!, rhs.amount!]).toString(),
            valueString != "NaN" else {
            fatalError("NcwWeb3Utils error in JavaScript.")
        }
        return BigDecimal(valueString)
    }

    // MARK: - Parsing

    public func isLhs(_ lhs: BigDecimal, lessThan rhs: BigDecimal) -> Bool {
        guard let jsFunction = jsContext.objectForKeyedSubscript("isLhs"),
            let valueString = jsFunction.call(withArguments: [lhs.amount!, rhs.amount!]).toString() else {
            fatalError("NcwWeb3Utils error in JavaScript.")
        }
        return Bool(valueString == "true")
    }

    public func parseToBigInt(from string: String) -> String? {
        guard let jsFunction = jsContext.objectForKeyedSubscript("parseToBigUInt"),
            let valueString = jsFunction.call(withArguments: [string]).toString(),
            valueString != "NaN",
            !string.isEmpty else {
            return nil
        }
        return valueString
    }

    public func hex(from number: BigDecimal) -> String? {
        guard let value = number.amount,
            let jsFunction = jsContext.objectForKeyedSubscript("hex"),
            let valueString = jsFunction.call(withArguments: [value]).toString(),
            valueString != "NaN" else {
            return nil
        }
        if valueString.starts(with: "0x") {
            return valueString 
        } else {
            return "0x" + valueString
        }
    }

    // MARK: - JavaScript

    var bigUintOperationsJS: String {
    """
        function add(lhs, rhs) {
            fmt = {
            prefix: '',
            decimalSeparator: '.',
            groupSeparator: '',
            groupSize: '',
            secondaryGroupSize: 0,
            fractionGroupSeparator: '',
            fractionGroupSize: 18,
            suffix: ''
            }
            return BigNumber(lhs).plus(BigNumber(rhs)).toFormat(fmt);
        }
        function subtract(lhs, rhs) {
            fmt = {
            prefix: '',
            decimalSeparator: '.',
            groupSeparator: '',
            groupSize: '',
            secondaryGroupSize: 0,
            fractionGroupSeparator: '',
            fractionGroupSize: 18,
            suffix: ''
            }
            return BigNumber(lhs).minus(BigNumber(rhs)).toFormat(fmt);
        }
        function multiply(lhs, rhs) {
            fmt = {
            prefix: '',
            decimalSeparator: '.',
            groupSeparator: '',
            groupSize: '',
            secondaryGroupSize: 0,
            fractionGroupSeparator: '',
            fractionGroupSize: 18,
            suffix: ''
            }
            return BigNumber(lhs).multipliedBy(BigNumber(rhs)).toFormat(fmt);
        }
        function isLhs(lhs, rhs) {
            return BigNumber(lhs).isLessThan(BigNumber(rhs));
        }
        function parseToBigUInt(stringValue) {
            fmt = {
            prefix: '',
            decimalSeparator: '.',
            groupSeparator: '',
            groupSize: '',
            secondaryGroupSize: 0,
            fractionGroupSeparator: '',
            fractionGroupSize: 18,
            suffix: ''
            }
            return BigNumber(stringValue).toFormat(fmt);
        }
        function hex(bigNumberValue) {
            return BigNumber(bigNumberValue).toString(16);
        }
    """
    }
}

extension Web3Utils {

    public func tokensAmount(fullValueNumber: BigDecimal, currencyBase: Double) -> Decimal? {
        guard let fullValue = fullValueNumber.amount,
            let jsFunction = jsContext.objectForKeyedSubscript("tokenAmount"),
            let valueString = jsFunction.call(withArguments: ["\(fullValue)", "\(currencyBase)"]).toString(),
            valueString != "NaN" else {
            return nil
        }
        return Decimal(string: valueString)
    }

    // MARK: - JavaScript

    var erc20tokenJS: String {
    """
        function tokenAmount(fullValue, precision) {
            BigNumber.set({ DECIMAL_PLACES: 30, ROUNDING_MODE: 4 })
            var fullValue = BigNumber(fullValue)
            var precision = BigNumber(precision)
            return fullValue.dividedBy(precision).toFormat();
        }
    """
    }
}

extension Web3Utils {

    public func etherFrom(wei: Wei) -> Decimal? {
        guard let amount = wei.value.amount,
            let jsFunction = jsContext.objectForKeyedSubscript("ethFromWei"),
            let valueString = jsFunction.call(withArguments: [amount]).toString(),
            valueString != "NaN" else {
            return nil
        }
        return Decimal(string: valueString)
    }

    public func gweiFrom(wei: Wei) -> Decimal? {
        guard let amount = wei.value.amount,
            let jsFunction = jsContext.objectForKeyedSubscript("gweiFromWei"),
            let valueString = jsFunction.call(withArguments: [amount]).toString(),
            valueString != "NaN" else {
            return nil
        }
        return Decimal(string: valueString)
    }

    public func weiFrom(ether: Decimal) -> BigDecimal? {
        guard let jsFunction = jsContext.objectForKeyedSubscript("weiFromEth"),
            let valueString = jsFunction.call(withArguments: [NSDecimalNumber(decimal: ether).stringValue]).toString(),
            valueString != "NaN" else {
            return nil
        }
        return BigDecimal(valueString)
    }

    public func weiFrom(gwei: Decimal) -> BigDecimal? {
        guard let jsFunction = jsContext.objectForKeyedSubscript("weiFromGwei"),
            let valueString = jsFunction.call(withArguments: [NSDecimalNumber(decimal: gwei).stringValue]).toString(),
            valueString != "NaN" else {
            return nil
        }
        return BigDecimal(valueString)
    }

    public func weiFrom(hex: String) -> BigDecimal {
        BigDecimal(hexString: hex)
    }

    // MARK: - JavaScript

    var weiConversionsJS: String {
    """
        function ethFromWei(wei) {
            BigNumber.set({ DECIMAL_PLACES: 18, ROUNDING_MODE: 4 })
            fmt = {
            prefix: '',
            decimalSeparator: '.',
            groupSeparator: ',',
            groupSize: '',
            secondaryGroupSize: 0,
            fractionGroupSeparator: ' ',
            fractionGroupSize: 18,
            suffix: ''
            }
            var weiNumber = BigNumber(wei)
            return weiNumber.dividedBy(\(Wei.Unit.wei.value)).decimalPlaces(18, 1).toFormat(fmt);
        }

        function gweiFromWei(wei) {
            BigNumber.set({ DECIMAL_PLACES: 9, ROUNDING_MODE: 4 })
            fmt = {
            prefix: '',
            decimalSeparator: '.',
            groupSeparator: ',',
            groupSize: '',
            secondaryGroupSize: 0,
            fractionGroupSeparator: ' ',
            fractionGroupSize: 9,
            suffix: ''
            }
            var weiNumber = BigNumber(wei)
            return weiNumber.dividedBy(\(Wei.Unit.gwei.value)).decimalPlaces(9, 1).toFormat(fmt);
        }

        function weiFromEth(eth) {
            BigNumber.set({ DECIMAL_PLACES: 0, ROUNDING_MODE: 4 })
            // wei units have no fractions. Format accordingly
            fmt = {
            prefix: '',
            decimalSeparator: '',
            groupSeparator: '',
            groupSize: 0,
            secondaryGroupSize: 0
            }
            var ethAsBigNumber = BigNumber(eth)
            return ethAsBigNumber.multipliedBy(\(Wei.Unit.wei.value)).decimalPlaces(0, 1).toFormat(fmt);
        }

        function weiFromGwei(gwei) {
            BigNumber.set({ DECIMAL_PLACES: 0, ROUNDING_MODE: 4 })
            // wei units have no fractions. Format accordingly
            fmt = {
            prefix: '',
            decimalSeparator: '',
            groupSeparator: '',
            groupSize: 0,
            secondaryGroupSize: 0
            }
            var gweiAsBigNumber = BigNumber(gwei)
            return gweiAsBigNumber.multipliedBy(\(Wei.Unit.gwei.value)).decimalPlaces(0, 1).toFormat(fmt);
        }

        function weiFromHex(hex) {
            return BigNumber(hex).toFormat();
        }
    """
    }
}
