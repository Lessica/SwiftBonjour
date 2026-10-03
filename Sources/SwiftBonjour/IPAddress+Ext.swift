//
//  IPAddress+Ext.swift
//  SwiftBonjour
//
//  Created by Rachel on 2023/12/29.
//

#if os(Linux)
import Foundation

public protocol IPAddress: CustomDebugStringConvertible, Sendable {
    init?(_ networkBytes: Data)
    init?(_ presentation: String)
    var presentation: String { get }

    /// network-byte-order bytes
    var bytes: Data { get }
}

public extension IPAddress {
    var debugDescription: String {
        presentation
    }
}

/// IPv4 address, wraps `in_addr`. This type is used to convert between
/// human-readable presentation format and bytes in both host order and
/// network order.
public struct IPv4Address: IPAddress, Sendable {
    /// IPv4 address in network-byte-order
    public let address: in_addr

    public init(address: in_addr) {
        self.address = address
    }

    public init?(_ presentation: String) {
        var address = in_addr()
        guard inet_pton(AF_INET, presentation, &address) == 1 else {
            return nil
        }
        self.address = address
    }

    /// network order
    public init?(_ networkBytes: Data) {
        guard networkBytes.count == MemoryLayout<in_addr>.size else {
            return nil
        }
        address = networkBytes.withUnsafeBytes { $0.loadUnaligned(as: in_addr.self) }
    }

    /// host order
    public init(_ address: UInt32) {
        self.address = in_addr(s_addr: address.bigEndian)
    }

    /// Format this IPv4 address using common `a.b.c.d` notation.
    public var presentationString: String? {
        let length = Int(INET_ADDRSTRLEN)
        var presentationBytes = [CChar](repeating: 0, count: length)
        var addr = address
        guard inet_ntop(AF_INET, &addr, &presentationBytes, socklen_t(length)) != nil else {
            return nil
        }
        let terminated = presentationBytes.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
        return String(decoding: terminated, as: UTF8.self)
    }

    public var presentation: String {
        presentationString ?? "Invalid IPv4 address"
    }

    public var bytes: Data {
        withUnsafeBytes(of: address) { Data($0) }
    }
}

extension IPv4Address: Equatable, Hashable {
    // MARK: Conformance to `Hashable`

    public static func == (lhs: IPv4Address, rhs: IPv4Address) -> Bool {
        lhs.address.s_addr == rhs.address.s_addr
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(address.s_addr)
    }
}

extension IPv4Address: ExpressibleByIntegerLiteral {
    // MARK: Conformance to `ExpressibleByIntegerLiteral`

    public init(integerLiteral value: UInt32) {
        self.init(value)
    }
}

public struct IPv6Address: IPAddress, Sendable {
    public let address: in6_addr

    public init(address: in6_addr) {
        self.address = address
    }

    public init?(_ presentation: String) {
        var address = in6_addr()
        guard inet_pton(AF_INET6, presentation, &address) == 1 else {
            return nil
        }
        self.address = address
    }

    public init?(_ networkBytes: Data) {
        guard networkBytes.count == MemoryLayout<in6_addr>.size else {
            return nil
        }
        address = networkBytes.withUnsafeBytes { $0.loadUnaligned(as: in6_addr.self) }
    }

    /// Format this IPv6 address using common `a:b:c:d:e:f:g:h` notation.
    public var presentationString: String? {
        let length = Int(INET6_ADDRSTRLEN)
        var presentationBytes = [CChar](repeating: 0, count: length)
        var addr = address
        guard inet_ntop(AF_INET6, &addr, &presentationBytes, socklen_t(length)) != nil else {
            return nil
        }
        let terminated = presentationBytes.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
        return String(decoding: terminated, as: UTF8.self)
    }

    public var presentation: String {
        presentationString ?? "Invalid IPv6 address"
    }

    public var bytes: Data {
        withUnsafeBytes(of: address) { Data($0) }
    }
}

extension IPv6Address: Equatable, Hashable {
    // MARK: Conformance to `Hashable`

    public static func == (lhs: IPv6Address, rhs: IPv6Address) -> Bool {
        lhs.bytes == rhs.bytes
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(bytes)
    }
}
#endif
