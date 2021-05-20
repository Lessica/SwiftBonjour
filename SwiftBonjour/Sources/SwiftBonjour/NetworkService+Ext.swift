//
//  NetworkService+Ext.swift
//  SwiftBonjour
//
//  Created by Rachel on 2021/5/18.
//

import Foundation
import Network

extension NetService {
    public class func dictionary(fromTXTRecord data: Data) -> [String: String] {
        return NetService.dictionary(fromTXTRecord: data).mapValues { data in
            String(data: data, encoding: .utf8) ?? ""
        }
    }

    public class func data(fromTXTRecord data: [String: String]) -> Data {
        return NetService.data(fromTXTRecord: data.mapValues { $0.data(using: .utf8) ?? Data() })
    }

    public func setTXTRecord(dictionary: [String: String]?){
        guard let dictionary = dictionary else {
            self.setTXTRecord(nil)
            return
        }
        self.setTXTRecord(NetService.data(fromTXTRecord: dictionary))
    }

    public var txtRecordDictionary: [String: String]? {
        guard let data = self.txtRecordData() else { return nil }
        return NetService.dictionary(fromTXTRecord: data)
    }
    
    @available(macOS 10.14, *)
    public var ipAddresses: [String] {
        var ipAddrs = [String]()
        guard let addresses = addresses else {
            return ipAddrs
        }
        for sockAddrData in addresses {
            if sockAddrData.count == MemoryLayout<sockaddr_in>.size {
                let sockAddrBytes = UnsafeMutableBufferPointer<sockaddr_in>.allocate(capacity: sockAddrData.count)
                assert(sockAddrData.copyBytes(to: sockAddrBytes) == MemoryLayout<sockaddr_in>.size)
                var ipAddressString = Array<CChar>(repeating: 0, count: Int(INET_ADDRSTRLEN))
                _ = inet_ntop(
                    AF_INET,
                    sockAddrBytes.baseAddress!,
                    &ipAddressString,
                    socklen_t(INET_ADDRSTRLEN)
                )
                ipAddrs.append(String(cString: ipAddressString))
            } else if sockAddrData.count == MemoryLayout<sockaddr_in6>.size {
                let sockAddrBytes = UnsafeMutableBufferPointer<sockaddr_in6>.allocate(capacity: sockAddrData.count)
                assert(sockAddrData.copyBytes(to: sockAddrBytes) == MemoryLayout<sockaddr_in6>.size)
                var ipAddressString = Array<CChar>(repeating: 0, count: Int(INET6_ADDRSTRLEN))
                _ = inet_ntop(
                    AF_INET6,
                    sockAddrBytes.baseAddress!,
                    &ipAddressString,
                    socklen_t(INET6_ADDRSTRLEN)
                )
                ipAddrs.append(String(cString: ipAddressString))
            }
        }
        return ipAddrs
    }
}
