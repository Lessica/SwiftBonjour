//
//  BonjourLogger.swift
//  SwiftBonjour
//
//  Created by Rachel on 2021/5/18.
//

import Foundation
#if os(Linux)
public struct OSLogType: RawRepresentable {
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

public var LoggerLevel = OSLogType.default

struct BonjourLogger {
    private static func log(_ message: [Any],
                            level: OSLogType,
                            fileName: String = #file,
                            line: Int = #line,
                            funcName: String = #function) {
        guard level.rawValue >= LoggerLevel.rawValue else { return }
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
    static func verbose(_ message: Any...,
                        fileName: String = #file,
                        line: Int = #line,
                        funcName: String = #function) {
        BonjourLogger.log(message, level: .default, fileName: fileName, line: line, funcName: funcName)
    }

    static func debug(_ message: Any...,
                      fileName: String = #file,
                      line: Int = #line,
                      funcName: String = #function) {
        BonjourLogger.log(message, level: .debug, fileName: fileName, line: line, funcName: funcName)
    }

    static func info(_ message: Any...,
                     fileName: String = #file,
                     line: Int = #line,
                     funcName: String = #function) {
        BonjourLogger.log(message, level: .info, fileName: fileName, line: line, funcName: funcName)
    }

    static func error(_ message: Any...,
                        fileName: String = #file,
                        line: Int = #line,
                        funcName: String = #function) {
        BonjourLogger.log(message, level: .error, fileName: fileName, line: line, funcName: funcName)
    }

    static func fault(_ message: Any...,
                      fileName: String = #file,
                      line: Int = #line,
                      funcName: String = #function) {
        BonjourLogger.log(message, level: .fault, fileName: fileName, line: line, funcName: funcName)
    }
}
