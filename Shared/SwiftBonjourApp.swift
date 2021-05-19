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
    static let didBecomeActiveNotificationName = NSApplication.didFinishLaunchingNotification
    static let willResignActiveNotificationName = NSApplication.willTerminateNotification
    #else
    static let didBecomeActiveNotificationName = UIApplication.didBecomeActiveNotification
    static let willResignActiveNotificationName = UIApplication.willResignActiveNotification
    #endif
    
    #if SERVICE
    let server = BonjourServer(
        type: SwiftBonjourApp.serviceType,
        name: "\(ProcessInfo().hostName) (\(String(describing: SwiftBonjourApp.self)))"
    )
    let state = ServiceState()
    #else
    let browser = BonjourBrowser()
    let state = BrowserState()
    #endif
    
    var view: some View {
        #if SERVICE
        ServiceView(state: state)
        #else
        BrowserView(state: state)
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            view
                .onAppear {
                    #if SERVICE
                    
                    server.start { succeed in
                        print("Bonjour server started: ", succeed)
                        state.domain = server.netService.domain
                        state.port = server.netService.port
                        state.txtRecord = server.txtRecord ?? [:]
                    }
                    
                    server.txtRecord = [
                        "hwmodel": HostClassType.hardwareModel,
                        "hostname": ProcessInfo().hostName
                    ]
                    
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
                            state.resolvedServices.insert(ServiceState(netService: service))
                        case .failure(_):
                            break
                        }
                    }
                    
                    browser.serviceRemovedHandler = { service in
                        print("Service removed")
                        print(service)
                        if let serviceToRemove = state.resolvedServices.first(where: { $0.domain == service.domain && $0.name == service.name }) {
                            state.resolvedServices.remove(serviceToRemove)
                        }
                    }
                    
                    browser.browse(type: SwiftBonjourApp.serviceType)
                    
                    #endif
                }
                .onDisappear {
                    #if SERVICE
                    server.stop()
                    #else
                    browser.stop()
                    #endif
                }
                .onReceive(NotificationCenter.default.publisher(for: SwiftBonjourApp.didBecomeActiveNotificationName), perform: { _ in
                    hideZoomButton()
                    #if SERVICE
                    server.start()
                    #else
                    browser.browse(type: SwiftBonjourApp.serviceType)
                    #endif
                })
                .onReceive(NotificationCenter.default.publisher(for: SwiftBonjourApp.willResignActiveNotificationName), perform: { _ in
                    #if SERVICE
                    server.stop()
                    #else
                    browser.stop()
                    #endif
                })
        }
    }
    
    func hideZoomButton() {
        #if os(macOS)
        for window in NSApplication.shared.windows {
            window.standardWindowButton(NSWindow.ButtonType.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(NSWindow.ButtonType.zoomButton)?.isHidden = true
            window.level = .statusBar
        }
        #endif
    }
}
