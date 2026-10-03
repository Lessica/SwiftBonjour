//
//  NetworkService+Ext.swift
//  SwiftBonjour
//
//  Created by Rachel on 2021/5/18.
//

#if !os(watchOS)
import Foundation
#if os(Linux)
import NetService
#else
import Network
#endif

public extension NetService {
    class func dictionary(fromTXTRecord data: Data) -> [String: String] {
        NetService.dictionary(fromTXTRecord: data).mapValues { data in
            String(data: data, encoding: .utf8) ?? ""
        }
    }

    class func data(fromTXTRecord data: [String: String]) -> Data {
        NetService.data(fromTXTRecord: data.mapValues { $0.data(using: .utf8) ?? Data() })
    }

    /// Sets the TXT record of the service.
    ///
    /// Returns `false` without changing the record when a key is empty, contains `=` or
    /// a non-printable-ASCII character, or when a `key=value` entry is longer than 255 bytes.
    @discardableResult
    func setTXTRecord(dictionary: [String: String]?) -> Bool {
        guard let dictionary else {
            return setTXTRecord(nil)
        }
        guard dictionary.allSatisfy(NetService.isValidTXTRecordEntry) else {
            BonjourLogger.error("Invalid TXT Record", dictionary)
            return false
        }
        return setTXTRecord(NetService.data(fromTXTRecord: dictionary))
    }

    private static func isValidTXTRecordEntry(key: String, value: String) -> Bool {
        let keyBytes = Array(key.utf8)
        guard !keyBytes.isEmpty,
              keyBytes.allSatisfy({ $0 >= 0x20 && $0 <= 0x7E && $0 != UInt8(ascii: "=") })
        else {
            return false
        }
        return keyBytes.count + 1 + value.utf8.count <= 255
    }

    var txtRecordDictionary: [String: String]? {
        guard let data = txtRecordData() else { return nil }
        return NetService.dictionary(fromTXTRecord: data)
    }

    var ipAddresses: [IPAddress] {
        guard let addresses else {
            return []
        }
        return addresses.compactMap(NetService.ipAddress(fromSocketAddress:))
    }

    private static func ipAddress(fromSocketAddress data: Data) -> IPAddress? {
        guard data.count >= MemoryLayout<sockaddr>.size else {
            return nil
        }
        let family = data.withUnsafeBytes { $0.loadUnaligned(as: sockaddr.self).sa_family }
        switch Int32(family) {
        case AF_INET:
            guard data.count >= MemoryLayout<sockaddr_in>.size else {
                return nil
            }
            let socketAddress = data.withUnsafeBytes { $0.loadUnaligned(as: sockaddr_in.self) }
            return IPv4Address(withUnsafeBytes(of: socketAddress.sin_addr) { Data($0) })
        case AF_INET6:
            guard data.count >= MemoryLayout<sockaddr_in6>.size else {
                return nil
            }
            let socketAddress = data.withUnsafeBytes { $0.loadUnaligned(as: sockaddr_in6.self) }
            return IPv6Address(withUnsafeBytes(of: socketAddress.sin6_addr) { Data($0) })
        default:
            return nil
        }
    }
}

#if os(Linux)
/// The Linux NetService has no identity of its own; Apple's compares name, type and domain.
extension NetService: @retroactive Equatable, @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(type)
        hasher.combine(domain)
    }

    public static func == (lhs: NetService, rhs: NetService) -> Bool {
        lhs.name == rhs.name && lhs.type == rhs.type && lhs.domain == rhs.domain
    }
}
#endif
#endif
