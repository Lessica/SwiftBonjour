//
//  SwiftBonjourApp.swift
//  Shared
//
//  Created by Rachel on 2021/5/18.
//

import SwiftUI
import SwiftBonjour

@main
struct SwiftBonjourApp: App {
    
    static let serviceType = ServiceType.tcp("http")
    
    #if os(macOS)
    static let computerName = Host.current().localizedName ?? ProcessInfo().hostName
    static let willUpdateNotificationName = NSApplication.willUpdateNotification
    #else
    static let computerName = UIDevice.current.name
    static let didBecomeActiveNotificationName = UIApplication.didBecomeActiveNotification
    static let willResignActiveNotificationName = UIApplication.willResignActiveNotification
    #endif
    
    #if SERVICE
    let server = BonjourServer(
        type: SwiftBonjourApp.serviceType,
        name: "\(SwiftBonjourApp.computerName) (\(String(describing: SwiftBonjourApp.self)))"
    )
    let state = ServiceState()
    #else
    let browser = BonjourBrowser()
    let state = BrowserState()
    #endif
    
    var innerView: some View {
        #if SERVICE
        ServiceView(state: state)
        #else
        BrowserView(state: state)
        #endif
    }
    
    var outerView: some View {
        innerView
            .onAppear {
                DispatchQueue.main.async {
                    #if SERVICE
                    
                    server.txtRecord = [
                        "HWModel": HostClassType.hardwareModel,
                        "HostName": SwiftBonjourApp.computerName,
                        "ServerName": String(describing: SwiftBonjourApp.self),
                        "ServerVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                    ]
                    
                    server.start { succeed in
                        print("Bonjour server started: ", succeed)
                        state.domain = server.netService.domain
                        state.port = server.netService.port
                        state.txtRecord = server.txtRecord ?? [:]
                    }
                    
                    #else
                    
                    browser.serviceFoundHandler = { service in
                        print("Service found")
                        print(service)
                    }
                    
                    browser.serviceResolvedHandler = { result in
                        print("Service resolved")
                        print(result)
                        switch result {
                        case let .success(service):
                            state.resolvedServiceProviders.insert(ServiceState(netService: service))
                        case .failure(_):
                            break
                        }
                    }
                    
                    browser.serviceRemovedHandler = { service in
                        print("Service removed")
                        print(service)
                        if let serviceToRemove = state.resolvedServiceProviders.first(where: { $0.domain == service.domain && $0.name == service.name }) {
                            state.resolvedServiceProviders.remove(serviceToRemove)
                        }
                    }
                    
                    browser.browse(type: SwiftBonjourApp.serviceType)
                    
                    #endif
                }
            }
            .onDisappear {
                DispatchQueue.main.async {
                    #if SERVICE
                    server.stop()
                    #else
                    browser.stop()
                    #endif
                }
            }
    }
    
    var body: some Scene {
        WindowGroup {
            #if os(macOS)
            outerView
                .onReceive(NotificationCenter.default.publisher(for: SwiftBonjourApp.willUpdateNotificationName), perform: { _ in
                    hideZoomButton()
                })
            #else
            outerView
                .onReceive(NotificationCenter.default.publisher(for: SwiftBonjourApp.didBecomeActiveNotificationName), perform: { _ in
                    DispatchQueue.main.async {
                        #if SERVICE
                        server.start()
                        #else
                        browser.browse(type: SwiftBonjourApp.serviceType)
                        #endif
                    }
                })
                .onReceive(NotificationCenter.default.publisher(for: SwiftBonjourApp.willResignActiveNotificationName), perform: { _ in
                    DispatchQueue.main.async {
                        #if SERVICE
                        server.stop()
                        #else
                        browser.stop()
                        #endif
                    }
                })
            #endif
        }
    }
    
    #if os(macOS)
    func hideZoomButton() {
        for window in NSApplication.shared.windows {
            window.standardWindowButton(NSWindow.ButtonType.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(NSWindow.ButtonType.zoomButton)?.isHidden = true
            window.level = .statusBar
        }
    }
    #endif
}
