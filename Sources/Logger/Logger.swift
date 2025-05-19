import Foundation
import Logging

// This is a bridge module to adapt Apple's swift-log to the Logger interface used in the project
public enum Log {
    private static let logger = Logger(label: "com.verse.nos")
    
    public static func debug(_ message: String) {
        logger.debug("\(message)")
    }
    
    public static func info(_ message: String) {
        logger.info("\(message)")
    }
    
    public static func warning(_ message: String) {
        logger.warning("\(message)")
    }
    
    public static func error(_ message: String) {
        logger.error("\(message)")
    }
    
    public static func critical(_ message: String) {
        logger.critical("\(message)")
    }
}