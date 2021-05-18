//
//  DeviceView.swift
//  SwiftBonjour
//
//  Created by Rachel on 2021/5/18.
//

import SwiftUI

struct DeviceView: View {
    enum DeviceType {
        case unknown
        case iphoneLegacy
        case iphone
        case ipadLegacy
        case ipad
        case appletv
        case applewatch
        case homepod
        case macbook
        case macmini
        case imac
        case macpro
        case macproLegacy
        
        var symbolName: String {
            switch self {
            case .unknown:
                return "bonjour"
            case .iphone:
                return "iphone"
            case .iphoneLegacy:
                return "iphone.homebutton"
            case .ipad:
                return "ipad"
            case .ipadLegacy:
                return "ipad.homebutton"
            case .appletv:
                return "appletv"
            case .applewatch:
                return "applewatch"
            case .homepod:
                return "homepod"
            case .macbook:
                return "laptopcomputer"
            case .macmini:
                return "macmini"
            case .imac:
                return "desktopcomputer"
            case .macpro:
                return "macpro.gen1"
            case .macproLegacy:
                return "macpro.gen2"
            }
        }
    }
    
    @State var deviceType: DeviceType = .unknown
    @State var deviceName: String
    
    var body: some View {
        VStack {
            Image(systemName: deviceType.symbolName)
                .resizable()
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
