//
//  ServiceType.swift
//  SwiftBonjour
//
//  Created by Rachel on 2021/5/18.
//

import Foundation

public enum ServiceType: Sendable, Hashable, CustomStringConvertible {
    case tcp(String)
    case udp(String)

    public var description: String {
        switch self {
        case let .tcp(name):
            "_\(name)._tcp."
        case let .udp(name):
            "_\(name)._udp."
        }
    }
}
