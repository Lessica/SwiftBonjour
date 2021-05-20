//
//  BrowserState.swift
//  SwiftBonjour
//
//  Created by Rachel on 5/19/21.
//

import SwiftUI

class BrowserState: ObservableObject {
    @Published var resolvedServiceProviders = Set<ServiceState>()
    
    var resolvedServiceSections: [String?] {
        Set(resolvedServiceProviders.compactMap({ $0.txtRecord?["ServerName"] }))
            .sorted(by: { $0.localizedCompare($1) == .orderedAscending }) + [nil]
    }
    
    func resolvedServiceProvidersInSection(_ section: String?) -> [ServiceState] {
        resolvedServiceProviders
            .filter({ $0.txtRecord?["ServerName"] == section })
            .sorted(by: { $0.name.localizedCompare($1.name) == .orderedAscending })
    }
}
