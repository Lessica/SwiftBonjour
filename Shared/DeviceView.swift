//
//  DeviceView.swift
//  SwiftBonjour
//
//  Created by Rachel on 2021/5/18.
//

import SwiftUI

struct DeviceView: View {
    @State var deviceType: DeviceType = .unknown
    @State var deviceName: String
    
    var body: some View {
        VStack {
            Image(systemName: deviceType.symbolName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32, alignment: .center)
            
            Text(deviceName)
                .font(.system(.caption))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding()
    }
}

struct DeviceView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceView(deviceName: "Example Device")
    }
}
