//
//  BrowserState.swift
//  SwiftBonjour
//
//  Created by Rachel on 5/19/21.
//

import SwiftBonjour
import SwiftUI

@MainActor
final class BrowserState: ObservableObject {
    @Published private(set) var resolvedServiceProviders = [String: ServiceState]()

    var resolvedServiceSections: [String?] {
        Set(resolvedServiceProviders.values.compactMap { $0.txtRecord?["ServerName"] })
            .sorted(by: { $0.localizedCompare($1) == .orderedAscending }) + [nil]
    }

    func resolvedServiceProvidersInSection(_ section: String?) -> [ServiceState] {
        resolvedServiceProviders.values
            .filter { $0.txtRecord?["ServerName"] == section }
            .sorted(by: { $0.name.localizedCompare($1.name) == .orderedAscending })
    }

    func insertOrUpdate(_ netService: NetService) {
        let id = ServiceState.id(of: netService)
        if let existing = resolvedServiceProviders[id] {
            existing.update(from: netService)
            objectWillChange.send()
        } else {
            resolvedServiceProviders[id] = ServiceState(netService: netService)
        }
    }

    func remove(_ netService: NetService) {
        resolvedServiceProviders[ServiceState.id(of: netService)] = nil
    }
}
