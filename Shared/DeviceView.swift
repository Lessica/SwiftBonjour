//
//  DeviceView.swift
//  SwiftBonjour
//
//  Created by Rachel on 2021/5/18.
//

import SwiftUI
import Network

struct DeviceView: View {
    
    @State private var showPopup: Bool = false
    
    var serviceState: ServiceState
    
    var body: some View {
        VStack {
            Image(systemName: HostClassType
                    .displayTypeForHardwareModel(
                        serviceState.txtRecord?["HWModel"] ?? ""
                    )
                    .symbolName
            )
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 32, height: 32, alignment: .center)
            
            Text(
                serviceState.txtRecord?["HostName"] ?? serviceState.name
            )
            .font(.system(.caption))
            .multilineTextAlignment(.center)
            .lineLimit(2)
        }
        .padding()
        .onTapGesture {
            self.showPopup = true
        }
        .popover(isPresented: $showPopup, content: {
            Text(
                """
                Host Name: \(serviceState.hostName ?? "Unknown")
                Hardware Model: \(serviceState.txtRecord?["HWModel"] ?? "Unknown")
                Server Name: \(serviceState.txtRecord?["ServerName"] ?? "Unknown")
                Server Version: \(serviceState.txtRecord?["ServerVersion"] ?? "Unknown")
                
                [Addresses]
                \(serviceState.netService!.ipAddresses.joined(separator: "\n"))
                """
            )
            .padding()
        })
    }
}

struct DeviceView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceView(serviceState: ServiceState())
    }
}
