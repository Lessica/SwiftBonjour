//
//  ServiceState.swift
//  SwiftBonjour
//
//  Created by Rachel on 5/19/21.
//

import SwiftUI
import SwiftBonjour

@MainActor
final class ServiceState: ObservableObject, Identifiable {
    /// Identifies the service by name, type and domain, which do not change while it is listed.
    let id: String

    @Published var domain: String = ""
    @Published var name: String = ""
    @Published var hostName: String?
    @Published var port: Int = 0
    @Published var txtRecord: [String: String]?
    @Published var addresses: [String] = []

    /// The service this state was last updated from. The browser keeps it alive while it is
    /// listed, and it may resolve more addresses after it was first reported.
    private weak var netService: NetService?

    init() {
        id = ""
    }

    init(netService: NetService) {
        id = ServiceState.id(of: netService)
        update(from: netService)
    }

    static func id(of netService: NetService) -> String {
        return "\(netService.name).\(netService.type)\(netService.domain)"
    }

    /// Copies what the service has resolved so far, so the state does not depend on the
    /// `NetService` object staying alive.
    func update(from netService: NetService) {
        self.netService = netService
        domain = netService.domain
        name = netService.name
        hostName = netService.hostName
        port = netService.port
        txtRecord = netService.txtRecordDictionary
        addresses = netService.ipAddresses.map { String(describing: $0) }
    }

    /// Copies what the service has resolved since the last update, if it is still listed.
    func refresh() {
        guard let netService else { return }
        update(from: netService)
    }
}
