//
//  DeviceView.swift
//  SwiftBonjour
//
//  Created by Rachel on 2021/5/18.
//

import SwiftUI
import MarkdownUI
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
            ScrollView(showsIndicators: false) {
                Markdown("""
                ### \(serviceState.hostName ?? "Unknown")
                
                #### Addresses
                
                \(serviceState.netService?.ipAddresses.compactMap({ String(describing: $0) }).joined(separator: "\n") ?? "")
                
                #### TXT Records
                
                ```
                \(serviceState.txtRecord?.compactMap({ "Key: \($0.key)\nValue: \($0.value)" }).joined(separator: "\n\n") ?? "")
                ```
                """
                )
                .padding()
            }
            .frame(minWidth: 240, minHeight: 160)
        })
    }
}

struct DeviceView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceView(serviceState: ServiceState())
    }
}
