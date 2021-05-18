//
//  ContentView.swift
//  Shared
//
//  Created by Rachel on 2021/5/18.
//

import SwiftUI

struct ContentView: View {
    
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
            ForEach(0...100, id: \.self) { idx in
                DeviceView(deviceName: "Example \(idx)")
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
