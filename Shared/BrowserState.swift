//
//  BrowserState.swift
//  SwiftBonjour
//
//  Created by Rachel on 5/19/21.
//

import SwiftUI

class BrowserState: ObservableObject {
    @Published var resolvedServices = Set<ServiceState>()
}
