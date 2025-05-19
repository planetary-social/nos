// This file provides a compatibility layer between different secp256k1 implementations
// It wraps the GigaBitcoin/secp256k1.swift library but renames the product to avoid name conflicts

import Foundation

// Re-export secp256k1 as NosSecp256k1 to avoid conflicts
@_exported import secp256k1