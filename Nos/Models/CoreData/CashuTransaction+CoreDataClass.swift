// ABOUTME: Core Data entity for tracking Cashu wallet transactions
// ABOUTME: Provides transaction history and analytics capabilities

import Foundation
import CoreData

@objc(CashuTransaction)
public class CashuTransaction: NSManagedObject {
    
    enum TransactionType: String {
        case mint = "mint"      // Lightning -> Cashu
        case melt = "melt"      // Cashu -> Lightning
        case send = "send"      // Send tokens/nutzap
        case receive = "receive" // Receive tokens/nutzap
    }
    
    enum TransactionStatus: String {
        case pending = "pending"
        case completed = "completed"
        case failed = "failed"
    }
    
    /// Convenience property for transaction type
    var transactionType: TransactionType? {
        get { TransactionType(rawValue: type) }
        set { type = newValue?.rawValue ?? "" }
    }
    
    /// Convenience property for transaction status
    var transactionStatus: TransactionStatus? {
        get { TransactionStatus(rawValue: status) }
        set { status = newValue?.rawValue ?? TransactionStatus.pending.rawValue }
    }
    
    /// Marks transaction as completed
    func complete() {
        status = TransactionStatus.completed.rawValue
        completedAt = Date()
    }
    
    /// Marks transaction as failed
    func fail() {
        status = TransactionStatus.failed.rawValue
        completedAt = Date()
    }
    
    /// Creates a mint transaction
    static func createMint(amount: Int64, mintURL: String, wallet: CashuWalletCache, in context: NSManagedObjectContext) -> CashuTransaction {
        let transaction = CashuTransaction(context: context)
        transaction.id = UUID().uuidString
        transaction.type = TransactionType.mint.rawValue
        transaction.amount = amount
        transaction.mintURL = mintURL
        transaction.wallet = wallet
        transaction.status = TransactionStatus.pending.rawValue
        transaction.createdAt = Date()
        
        return transaction
    }
    
    /// Creates a melt transaction
    static func createMelt(amount: Int64, mintURL: String, invoice: String, wallet: CashuWalletCache, in context: NSManagedObjectContext) -> CashuTransaction {
        let transaction = CashuTransaction(context: context)
        transaction.id = UUID().uuidString
        transaction.type = TransactionType.melt.rawValue
        transaction.amount = amount
        transaction.mintURL = mintURL
        transaction.lightningInvoice = invoice
        transaction.wallet = wallet
        transaction.status = TransactionStatus.pending.rawValue
        transaction.createdAt = Date()
        
        return transaction
    }
    
    /// Creates a send transaction (nutzap)
    static func createSend(amount: Int64, mintURL: String, recipientPubkey: String, comment: String?, wallet: CashuWalletCache, in context: NSManagedObjectContext) -> CashuTransaction {
        let transaction = CashuTransaction(context: context)
        transaction.id = UUID().uuidString
        transaction.type = TransactionType.send.rawValue
        transaction.amount = amount
        transaction.mintURL = mintURL
        transaction.recipientPubkey = recipientPubkey
        transaction.comment = comment
        transaction.wallet = wallet
        transaction.status = TransactionStatus.pending.rawValue
        transaction.createdAt = Date()
        
        return transaction
    }
    
    /// Creates a receive transaction
    static func createReceive(amount: Int64, mintURL: String, wallet: CashuWalletCache, in context: NSManagedObjectContext) -> CashuTransaction {
        let transaction = CashuTransaction(context: context)
        transaction.id = UUID().uuidString
        transaction.type = TransactionType.receive.rawValue
        transaction.amount = amount
        transaction.mintURL = mintURL
        transaction.wallet = wallet
        transaction.status = TransactionStatus.completed.rawValue
        transaction.createdAt = Date()
        transaction.completedAt = Date()
        
        return transaction
    }
}