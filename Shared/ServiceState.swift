//
//  ServiceState.swift
//  SwiftBonjour
//
//  Created by Rachel on 5/19/21.
//

import SwiftUI

class ServiceState: ObservableObject, Hashable {
    static func == (lhs: ServiceState, rhs: ServiceState) -> Bool {
        return lhs.hostName == rhs.hostName && lhs.domain == rhs.domain && lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(domain)
        hasher.combine(name)
        hasher.combine(hostName)
        hasher.combine(port)
    }
    
    @Published var domain: String = ""
    @Published var name: String = ""
    @Published var hostName: String?
    @Published var port: Int = 0
    @Published var txtRecord: [String: String]?
    private(set) weak var netService: NetService?
    
    init() {}
    
    init(domain: String, name: String, hostName: String?, port: Int, txtRecord: [String: String]?) {
        self.domain = domain
        self.name = name
        self.hostName = hostName
        self.port = port
        self.txtRecord = txtRecord
    }
    
    init(netService: NetService) {
        self.domain = netService.domain
        self.name = netService.name
        self.hostName = netService.hostName
        self.port = netService.port
        self.txtRecord = netService.txtRecordDictionary
        self.netService = netService
    }
}
