//
//  ServiceView.swift
//  SwiftBonjour
//
//  Created by Rachel on 5/19/21.
//

import SwiftUI

struct ServiceView: View {
    @ObservedObject var state: ServiceState
    
    var messageView: some View {
        if !state.domain.isEmpty {
            return Text("Service published at domain \(state.domain) port \(String(state.port))")
        } else {
            return Text("Will publish...")
        }
    }
    
    var body: some View {
        messageView
            .padding()
            .frame(minWidth: 200, minHeight: 120)
    }
}

struct ServiceView_Previews: PreviewProvider {
    static var previews: some View {
        ServiceView(state: ServiceState())
    }
}
