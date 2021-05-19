//
//  BrowserView.swift
//  Shared
//
//  Created by Rachel on 2021/5/18.
//

import SwiftUI

struct BrowserView: View {
    
    @ObservedObject var state: BrowserState
    
    #if os(macOS)
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    #else
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    #endif
    
    var grid: some View {
        LazyVGrid(columns: columns) {
            ForEach(state.resolvedServices.sorted(by: { $0.name.localizedCompare($1.name) == .orderedAscending }), id: \.self) { service in
                DeviceView(
                    deviceType: HostClassType.displayTypeForHardwareModel(service.txtRecord?["hwmodel"] ?? ""),
                    deviceName: service.name
                )
            }
        }
    }
    
    var list: some View {
        #if os(macOS)
        ScrollView {
            grid
        }
        .background(Color.white)
        #else
        NavigationView {
            Form {
                grid
            }
            .background(Color.white)
            .navigationBarTitle(Text("SwiftBonjour"), displayMode: .inline)
        }
        #endif
    }
    
    var body: some View {
        #if os(macOS)
        list
        .frame(minWidth: 720, minHeight: 480)
        #else
        list
        #endif
    }
}

struct BrowserView_Previews: PreviewProvider {
    static var previews: some View {
        BrowserView(state: BrowserState())
    }
}
