//
//  DeviceView.swift
//  SwiftBonjour
//
//  Created by Rachel on 2021/5/18.
//

import SwiftUI

struct DeviceView: View {
    @State private var showPopup: Bool = false

    @ObservedObject var serviceState: ServiceState

    var body: some View {
        VStack {
            Image(
                systemName: HostClassType
                    .displayTypeForHardwareModel(
                        serviceState.txtRecord?["HWModel"] ?? "",
                    )
                    .symbolName,
            )
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 32, height: 32, alignment: .center)

            Text(
                serviceState.txtRecord?["HostName"] ?? serviceState.name,
            )
            .font(.system(.caption))
            .multilineTextAlignment(.center)
            .lineLimit(2)
        }
        .padding()
        .onTapGesture {
            serviceState.refresh()
            showPopup = true
        }
        .popover(isPresented: $showPopup, content: {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(serviceState.hostName ?? "Unknown")
                        .font(.headline)

                    Text("Addresses")
                        .font(.subheadline)
                    Text(serviceState.addresses.joined(separator: "\n"))

                    Text("TXT Records")
                        .font(.subheadline)
                    Text(txtRecordDescription)
                        .font(.system(.body, design: .monospaced))
                }
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .frame(minWidth: 240, minHeight: 160)
        })
    }

    private var txtRecordDescription: String {
        (serviceState.txtRecord ?? [:])
            .sorted(by: { $0.key < $1.key })
            .map { "Key: \($0.key)\nValue: \($0.value)" }
            .joined(separator: "\n\n")
    }
}

struct DeviceView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceView(serviceState: ServiceState())
    }
}
