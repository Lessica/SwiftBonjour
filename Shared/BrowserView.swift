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
    
    func formSection(_ section: String?) -> some View {
        Section(
            header: Text(section ?? "Others")
                .font(.system(.headline))
                .textCase(.none)
                .padding()
        ) {
            LazyVGrid(columns: columns) {
                ForEach(
                    state.resolvedServiceProvidersInSection(section),
                    id: \.self
                ) { service in
                    DeviceView(serviceState: service)
                }
            }
        }
    }
    
    var form: some View {
        Form {
            ForEach(
                state.resolvedServiceSections,
                id: \.self
            ) { section in
                formSection(section)
            }
        }
    }
    
    var list: some View {
        #if os(macOS)
        ScrollView {
            form
        }
        .background(Color.white)
        #else
        NavigationView {
            form
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
