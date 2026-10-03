//
//  SwiftBonjourApp.swift
//  Shared
//
//  Created by Rachel on 2021/5/18.
//

import SwiftBonjour
import SwiftUI

@main
struct SwiftBonjourApp: App {
    static let serviceType = ServiceType.tcp("http")

    #if os(macOS)
    static let computerName = Host.current().localizedName ?? ProcessInfo().hostName
    #else
    static let computerName = UIDevice.current.name
    #endif

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var controller = BonjourController()

    var innerView: some View {
        #if SERVICE
        ServiceView(state: controller.state)
        #else
        BrowserView(state: controller.state)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            #if os(macOS)
            innerView
                .background(WindowConfigurator())
                .onAppear { controller.start() }
            #else
            innerView
                .onAppear { controller.start() }
            #endif
        }
        .onChange(of: scenePhase) { phase in
            // Discovery and publishing belong to the app, not to any one window.
            switch phase {
            case .active:
                controller.start()
            case .background:
                controller.stop()
            default:
                break
            }
        }
    }
}

/// Owns the Bonjour server or browser for the whole app.
@MainActor
final class BonjourController: ObservableObject {
    #if SERVICE
    let server = BonjourServer(
        type: SwiftBonjourApp.serviceType,
        name: "\(SwiftBonjourApp.computerName) (\(String(describing: SwiftBonjourApp.self)))",
    )
    let state = ServiceState()
    #else
    let browser = BonjourBrowser()
    let state = BrowserState()
    #endif

    init() {
        #if SERVICE
        server.txtRecord = [
            "HWModel": HostClassType.hardwareModel,
            "HostName": SwiftBonjourApp.computerName,
            "ServerName": String(describing: SwiftBonjourApp.self),
            "ServerVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
        ]
        #else
        browser.serviceFoundHandler = { service in
            print("Service found")
            print(service)
        }

        browser.serviceResolvedHandler = { [weak self] result in
            print("Service resolved")
            print(result)
            switch result {
            case let .success(service):
                self?.state.insertOrUpdate(service)
            case .failure:
                break
            }
        }

        browser.serviceRemovedHandler = { [weak self] service in
            print("Service removed")
            print(service)
            self?.state.remove(service)
        }
        #endif
    }

    /// Starts publishing or browsing. Calling it again while running does nothing.
    func start() {
        #if SERVICE
        server.start { [weak self] succeed in
            print("Bonjour server started: ", succeed)
            guard let self else { return }
            state.domain = server.netService.domain
            state.port = server.netService.port
            state.txtRecord = server.txtRecord ?? [:]
        }
        #else
        browser.browse(type: SwiftBonjourApp.serviceType)
        #endif
    }

    func stop() {
        #if SERVICE
        server.stop()
        #else
        browser.stop()
        #endif
    }
}

#if os(macOS)
/// Configures the window that hosts it, once, when it is added to that window.
private struct WindowConfigurator: NSViewRepresentable {
    final class ConfiguratorView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window else { return }
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
            window.level = .statusBar
        }
    }

    func makeNSView(context _: Context) -> NSView {
        ConfiguratorView()
    }

    func updateNSView(_: NSView, context _: Context) {}
}
#endif
