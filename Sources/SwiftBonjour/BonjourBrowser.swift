//
//  BonjourBrowser.swift
//  SwiftBonjour
//
//  Created by Rachel on 2021/5/18.
//

#if !os(watchOS)
import Foundation
#if os(Linux)
import NetService
#else
import Network
#endif

public class BonjourBrowser {
    /// How long the browser tries to resolve each found service.
    static let resolveTimeout: TimeInterval = 5

    var netServiceBrowser: NetServiceBrowser
    var delegate: BonjourBrowserDelegate

    public var services = Set<NetService>()

    // Handlers
    public var serviceFoundHandler: ((NetService) -> Void)?
    public var serviceRemovedHandler: ((NetService) -> Void)?
    public var serviceResolvedHandler: ((Result<NetService, ErrorDictionary>) -> Void)?


    public var isSearching = false {
        didSet {
            BonjourLogger.info(isSearching)
        }
    }

    /// The type and domain of the search this browser started and has not stopped yet.
    private var activeSearch: (type: String, domain: String)?
    /// Whether the active search failed after it started. It stays allocated until `stop()`.
    private var activeSearchFailed = false
    private var isStartingSearch = false
    private var resolvers = [ObjectIdentifier: BonjourResolver]()

    public init() {
        netServiceBrowser = NetServiceBrowser()
        delegate = BonjourBrowserDelegate()
        netServiceBrowser.delegate = delegate
        delegate.browser = self
    }

    deinit {
        stop(notifyingRemovedServices: false)
        // NetServiceBrowser does not retain its delegate.
        netServiceBrowser.delegate = nil
    }

    public func browse(type: ServiceType, domain: String = "") {
        browse(type: type.description, domain: domain)
    }

    /// Starts searching for services. Browsing again for the same type and domain while that
    /// search is running does nothing; otherwise the current search stops first, as `stop()` does.
    public func browse(type: String, domain: String = "") {
        if let activeSearch {
            if !activeSearchFailed && activeSearch.type == type && activeSearch.domain == domain {
                return
            }
            stop()
        }
        activeSearch = (type, domain)
        isStartingSearch = true
        netServiceBrowser.searchForServices(ofType: type, inDomain: domain)
        isStartingSearch = false
    }

    fileprivate func serviceFound(_ service: NetService) {
        services.update(with: service)
        serviceFoundHandler?(service)

        // resolve services if handler is registered
        guard serviceResolvedHandler != nil else { return }
        let key = ObjectIdentifier(service)
        guard resolvers[key] == nil else { return }
        let resolver = BonjourResolver(service: service)
        resolvers[key] = resolver
        resolver.onFinish = { [weak self] in
            self?.resolvers[key] = nil
        }
        // Report the service once, then release the resolver, which stops the resolve.
        // A running resolve makes the found service busy: another resolve of it fails with
        // `activityInProgress`. (The Linux NetService also ignores the timeout.)
        var didReport = false
        resolver.resolve(withTimeout: BonjourBrowser.resolveTimeout) { [weak self] result in
            guard !didReport else { return }
            didReport = true
            self?.serviceResolvedHandler?(result)
            self?.resolvers[key] = nil
        }
    }

    fileprivate func serviceRemoved(_ service: NetService) {
        services.remove(service)
        cancelResolvers { $0 == service }
        serviceRemovedHandler?(service)
    }

    fileprivate func searchDidFail() {
        #if os(Linux)
        // A failure reported while the search is still starting means it never started.
        // A later failure leaves the search allocated until `stop()`.
        if isStartingSearch {
            activeSearch = nil
        } else {
            activeSearchFailed = true
        }
        #else
        activeSearch = nil
        #endif
        isSearching = false
    }

    private func cancelResolvers(where shouldCancel: (NetService) -> Bool) {
        let cancelled = resolvers.filter { shouldCancel($0.value.service) }
        for key in cancelled.keys {
            resolvers[key] = nil
        }
        // `cancelled` releases the resolvers, which stop their services.
    }

    /// Stops searching and removes every found service from `services`,
    /// calling `serviceRemovedHandler` for each one.
    public func stop() {
        stop(notifyingRemovedServices: true)
    }

    private func stop(notifyingRemovedServices: Bool) {
        cancelResolvers { _ in true }
        if activeSearch != nil {
            activeSearch = nil
            activeSearchFailed = false
            netServiceBrowser.stop()
            #if os(Linux)
            // The Linux NetServiceBrowser cannot search again once stopped.
            netServiceBrowser.delegate = nil
            netServiceBrowser = NetServiceBrowser()
            netServiceBrowser.delegate = delegate
            #endif
        }
        // A stopped browser reports no removals, so the found services would go stale.
        let removedServices = services
        services.removeAll()
        guard notifyingRemovedServices else { return }
        for service in removedServices {
            serviceRemovedHandler?(service)
        }
    }
}

class BonjourBrowserDelegate: NSObject, NetServiceBrowserDelegate {
    weak var browser: BonjourBrowser?
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        BonjourLogger.info("Bonjour service found", service)
        self.browser?.serviceFound(service)
    }

    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        BonjourLogger.info("Bonjour browser will search")
        self.browser?.isSearching = true
    }

    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        BonjourLogger.info("Bonjour browser stopped search")
        self.browser?.isSearching = false
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) {
        BonjourLogger.debug("Bonjour browser did not search", errorDict)
        self.browser?.searchDidFail()
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        BonjourLogger.info("Bonjour service removed", service)
        self.browser?.serviceRemoved(service)
    }
}
#endif
