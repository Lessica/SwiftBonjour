//
//  NetworkService+Ext.swift
//  SwiftBonjour
//
//  Created by Rachel on 2021/5/18.
//

import Foundation

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
}
