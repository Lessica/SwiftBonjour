//
//  BonjourLogger.swift
//  SwiftBonjour
//
//  Created by Rachel on 2021/5/18.
//

import Foundation

#if os(Linux)
public struct OSLogType: RawRepresentable, Sendable, Hashable {
    public static let `default` = OSLogType(rawValue: 0)
    public static let debug = OSLogType(rawValue: -2)
    public static let info = OSLogType(rawValue: -1)
    public static let error = OSLogType(rawValue: 1)
    public static let fault = OSLogType(rawValue: 2)

    public typealias RawValue = Int

    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
#else
import OSLog
#endif

private final class LoggerLevelStorage: @unchecked Sendable {
    private let lock = NSLock()
    #if os(Linux)
    private var value = OSLogType.default
    #else
    /// Apple platforms have always logged every level by default.
    private var value = OSLogType.debug
    #endif

    var level: OSLogType {
        get {
            lock.lock()
            defer { lock.unlock() }
            return value
        }
        set {
            lock.lock()
            value = newValue
            lock.unlock()
        }
    }
}

private let loggerLevelStorage = LoggerLevelStorage()

/// The least severe level that SwiftBonjour logs.
///
/// Levels are ordered by severity, from least to most severe:
/// `.debug`, `.info`, `.default`, `.error`, `.fault`.
/// The default is `.debug` on Apple platforms, where the unified logging system filters
/// messages itself, and `.default` on Linux.
/// Reading and writing this value is thread-safe.
public var LoggerLevel: OSLogType {
    get { loggerLevelStorage.level }
    set { loggerLevelStorage.level = newValue }
}

enum BonjourLogger {
    /// Orders levels by severity, because `OSLogType` raw values on Apple platforms are not.
    static func severityRank(_ level: OSLogType) -> Int {
        switch level.rawValue {
        case OSLogType.debug.rawValue:
            0
        case OSLogType.info.rawValue:
            1
        case OSLogType.error.rawValue:
            3
        case OSLogType.fault.rawValue:
            4
        default:
            2
        }
    }

    private static func log(
        _ message: [Any],
        level: OSLogType,
        fileName: String = #file,
        line: Int = #line,
        funcName: String = #function,
    ) {
        guard severityRank(level) >= severityRank(LoggerLevel) else { return }
        let msg = message.map { String(describing: $0) }.joined(separator: ", ")
        #if os(Linux)
        print("[\(sourceFileName(filePath: fileName))]:\(line) \(funcName) -> \(msg)")
        #else
        os_log("[%@]:%ld %@ -> %@", log: .default, type: level, sourceFileName(filePath: fileName), line, funcName, msg)
        #endif
    }

    private static func sourceFileName(filePath: String) -> String {
        let components = filePath.components(separatedBy: "/")
        return components.isEmpty ? "" : components.last!
    }
}

extension BonjourLogger {
    static func verbose(
        _ message: Any...,
        fileName: String = #file,
        line: Int = #line,
        funcName: String = #function,
    ) {
        BonjourLogger.log(message, level: .default, fileName: fileName, line: line, funcName: funcName)
    }

    static func debug(
        _ message: Any...,
        fileName: String = #file,
        line: Int = #line,
        funcName: String = #function,
    ) {
        BonjourLogger.log(message, level: .debug, fileName: fileName, line: line, funcName: funcName)
    }

    static func info(
        _ message: Any...,
        fileName: String = #file,
        line: Int = #line,
        funcName: String = #function,
    ) {
        BonjourLogger.log(message, level: .info, fileName: fileName, line: line, funcName: funcName)
    }

    static func error(
        _ message: Any...,
        fileName: String = #file,
        line: Int = #line,
        funcName: String = #function,
    ) {
        BonjourLogger.log(message, level: .error, fileName: fileName, line: line, funcName: funcName)
    }

    static func fault(
        _ message: Any...,
        fileName: String = #file,
        line: Int = #line,
        funcName: String = #function,
    ) {
        BonjourLogger.log(message, level: .fault, fileName: fileName, line: line, funcName: funcName)
    }
}
