//
//  NetworkService+Ext.swift
//  SwiftBonjour
//
//  Created by Rachel on 2021/5/18.
//

import Foundation
#if os(Linux)
import NetService
#else
import Network
#endif

extension NetService: Hashable {
    public class func dictionary(fromTXTRecord data: Data) -> [String: String] {
        return NetService.dictionary(fromTXTRecord: data).mapValues { data in
            String(data: data, encoding: .utf8) ?? ""
        }
    }

    public class func data(fromTXTRecord data: [String: String]) -> Data {
        return NetService.data(fromTXTRecord: data.mapValues { $0.data(using: .utf8) ?? Data() })
    }

    public func setTXTRecord(dictionary: [String: String]?) {
        guard let dictionary = dictionary else {
            _ = self.setTXTRecord(nil)
            return
        }
        _ = self.setTXTRecord(NetService.data(fromTXTRecord: dictionary))
    }

    public var txtRecordDictionary: [String: String]? {
        guard let data = self.txtRecordData() else { return nil }
        return NetService.dictionary(fromTXTRecord: data)
    }
    
    @available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *)
    public var ipAddresses: [IPAddress] {
        var ipAddrs = [IPAddress]()
        guard let addresses = addresses else {
            return ipAddrs
        }
        for sockAddrData in addresses {
            if sockAddrData.count == MemoryLayout<sockaddr_in>.size {
                let sockAddrBytes = UnsafeMutableBufferPointer<sockaddr_in>.allocate(capacity: sockAddrData.count)
                assert(sockAddrData.copyBytes(to: sockAddrBytes) == MemoryLayout<sockaddr_in>.size)
                if var sinAddr = sockAddrBytes.baseAddress?.pointee.sin_addr,
                   let ipAddr = IPv4Address(Data(bytes: &sinAddr.s_addr, count: MemoryLayout<in_addr>.size))
                {
                    ipAddrs.append(ipAddr)
                }
            } else if sockAddrData.count == MemoryLayout<sockaddr_in6>.size {
                let sockAddrBytes = UnsafeMutableBufferPointer<sockaddr_in6>.allocate(capacity: sockAddrData.count)
                assert(sockAddrData.copyBytes(to: sockAddrBytes) == MemoryLayout<sockaddr_in6>.size)
                if var sinAddr = sockAddrBytes.baseAddress?.pointee.sin6_addr,
                   let ipAddr = IPv6Address(Data(bytes: &sinAddr, count: MemoryLayout<in6_addr>.size))
                {
                    ipAddrs.append(ipAddr)
                }
            }
        }
        return ipAddrs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
        hasher.combine(self.type)
        hasher.combine(self.domain)
    }

    public static func == (lhs: NetService, rhs: NetService) -> Bool {
        return lhs.name == rhs.name && lhs.type == rhs.type && lhs.domain == rhs.domain
    }
}
