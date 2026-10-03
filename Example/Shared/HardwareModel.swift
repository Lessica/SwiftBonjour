//
//  HardwareModel.swift
//  SwiftBonjour
//
//  Created by Rachel on 5/19/21.
//

#if os(macOS)
import Foundation

typealias HostClassType = Host
#else
import UIKit

typealias HostClassType = UIDevice
#endif

enum DeviceType {
    case unknown
    case ipodtouch
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
    case macproGen1
    case macproGen2
    case macproGen3

    var symbolName: String {
        switch self {
        case .unknown:
            "bonjour"
        case .ipodtouch:
            "ipodtouch"
        case .iphone:
            "iphone"
        case .iphoneLegacy:
            "iphone.homebutton"
        case .ipad:
            "ipad"
        case .ipadLegacy:
            "ipad.homebutton"
        case .appletv:
            "appletv"
        case .applewatch:
            "applewatch"
        case .homepod:
            "homepod"
        case .macbook:
            "laptopcomputer"
        case .macmini:
            "macmini"
        case .imac:
            "desktopcomputer"
        case .macproGen1:
            "macpro.gen1"
        case .macproGen2:
            "macpro.gen2"
        case .macproGen3:
            "macpro.gen3"
        }
    }
}

extension HostClassType {
    static let hardwareModel: String = {
        #if os(macOS)
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        defer { IOObjectRelease(service) }

        guard let modelData = IORegistryEntryCreateCFProperty(service, "model" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Data else {
            return ""
        }
        return String(decoding: modelData.prefix(while: { $0 != 0 }), as: UTF8.self)
        #else
        #if targetEnvironment(simulator)
        if let identifier = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return identifier
        }
        #endif
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        #endif
    }()

    static func displayTypeForHardwareModel(_ identifier: String) -> DeviceType { // swiftlint:disable:this cyclomatic_complexity
        if identifier.hasPrefix("iMac") {
            return .imac
        } else if identifier.hasPrefix("Macmini") {
            return .macmini
        } else if identifier.hasPrefix("MacBook") {
            return .macbook
        } else if identifier.hasPrefix("MacPro1") || identifier.hasPrefix("MacPro2") || identifier.hasPrefix("MacPro3") || identifier.hasPrefix("MacPro4") {
            return .macproGen1
        } else if identifier.hasPrefix("MacPro5") || identifier.hasPrefix("MacPro6") {
            return .macproGen2
        } else if identifier.hasPrefix("MacPro7") {
            return .macproGen3
        }
        switch identifier {
        case "iPod5,1", "iPod7,1", "iPod9,1":
            return .ipodtouch
        case "iPhone3,1", "iPhone3,2", "iPhone3,3",
             "iPhone4,1",
             "iPhone5,1", "iPhone5,2", "iPhone5,3", "iPhone5,4",
             "iPhone6,1", "iPhone6,2",
             "iPhone7,1", "iPhone7,2",
             "iPhone8,1", "iPhone8,2", "iPhone8,4",
             "iPhone9,1", "iPhone9,2", "iPhone9,3", "iPhone9,4",
             "iPhone10,1", "iPhone10,2", "iPhone10,4", "iPhone10,5",
             "iPhone12,8":
            return .iphoneLegacy
        case "iPhone10,3", "iPhone10,6",
             "iPhone11,2", "iPhone11,4", "iPhone11,6", "iPhone11,8",
             "iPhone12,1", "iPhone12,3", "iPhone12,5",
             "iPhone13,1", "iPhone13,2", "iPhone13,3", "iPhone13,4":
            return .iphone
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4", "iPad2,5", "iPad2,6", "iPad2,7",
             "iPad3,1", "iPad3,2", "iPad3,3", "iPad3,4", "iPad3,5", "iPad3,6",
             "iPad4,1", "iPad4,2", "iPad4,3", "iPad4,4", "iPad4,5", "iPad4,6", "iPad4,7", "iPad4,8", "iPad4,9",
             "iPad5,1", "iPad5,2", "iPad5,3", "iPad5,4",
             "iPad6,3", "iPad6,4", "iPad6,11", "iPad6,12",
             "iPad7,3", "iPad7,4", "iPad7,5", "iPad7,6", "iPad7,11", "iPad7,12",
             "iPad11,1", "iPad11,2", "iPad11,3", "iPad11,4", "iPad11,6", "iPad11,7":
            return .ipadLegacy
        case "iPad6,7", "iPad6,8",
             "iPad7,1", "iPad7,2",
             "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4", "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8",
             "iPad8,9", "iPad8,10", "iPad8,11", "iPad8,12",
             "iPad13,1", "iPad13,2":
            return .ipad
        case "AppleTV5,3", "AppleTV6,2":
            return .appletv
        case "AudioAccessory1,1", "AudioAccessory5,1":
            return .homepod
        default:
            return .unknown
        }
    }
}
