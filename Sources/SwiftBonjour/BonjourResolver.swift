//
//  BonjourResolver.swift
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

public class BonjourResolver {
    public init(service: NetService) {
        self.service = service
        delegate.resolver = self
    }

    let service: NetService
    let delegate: BonjourResolverDelegate = .init()

    /// Called once the resolve has ended on its own (timeout or failure on Apple platforms).
    var onFinish: (() -> Void)?

    /// Whether a resolve started by this resolver may still be running and needs `service.stop()`.
    private var isResolving = false
    private var isStartingResolve = false
    /// Whether an earlier resolve by this resolver was still running when the current one started.
    private var isStartingOverRunningResolve = false

    /// Starts resolving the service.
    ///
    /// `completion` is called for each address the service resolves, and once with
    /// a failure if the service cannot be resolved. A `timeout` of `0` resolves indefinitely.
    public func resolve(
        withTimeout timeout: TimeInterval,
        completion: @escaping (Result<NetService, ErrorDictionary>) -> Void,
    ) {
        delegate.onResolve = completion
        service.delegate = delegate
        isStartingOverRunningResolve = isResolving
        isResolving = true
        isStartingResolve = true
        service.resolve(withTimeout: timeout)
        isStartingResolve = false
        isStartingOverRunningResolve = false
    }

    /// Stops a resolve started by this resolver. Calling it more than once is harmless.
    func stop() {
        guard isResolving else { return }
        isResolving = false
        service.stop()
    }

    fileprivate func resolveDidFail() {
        if isStartingResolve {
            // A failure reported while `resolve(withTimeout:)` is still running means this
            // resolve never started. If an earlier resolve is still running (the failure is
            // `activityInProgress`), it keeps running and still needs `stop()`.
            guard !isStartingOverRunningResolve else { return }
            isResolving = false
            onFinish?()
            return
        }
        #if !os(Linux)
        isResolving = false
        onFinish?()
        #endif
    }

    fileprivate func resolveDidStop() {
        isResolving = false
        onFinish?()
    }

    deinit {
        BonjourLogger.verbose(self)
        delegate.onResolve = nil
        stop()
        // NetService does not retain its delegate.
        if service.delegate === delegate {
            service.delegate = nil
        }
    }
}

public typealias ErrorDictionary = [String: Int]
extension ErrorDictionary: @retroactive Error {}

extension BonjourResolver {
    class BonjourResolverDelegate: NSObject, NetServiceDelegate {
        weak var resolver: BonjourResolver?
        var onResolve: ((Result<NetService, ErrorDictionary>) -> Void)?

        func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
            BonjourLogger.fault("Bonjour service did not resolve", sender, errorDict)
            let transformed = errorDict.mapValues { value in
                Int(truncating: value)
            }
            // A handler may release the resolver, and with it this delegate.
            withExtendedLifetime(self) {
                let resolver = self.resolver
                onResolve?(Result.failure(transformed))
                resolver?.resolveDidFail()
            }
        }

        func netServiceDidResolveAddress(_ sender: NetService) {
            BonjourLogger.info("Bonjour service resolved", sender)
            withExtendedLifetime(self) {
                onResolve?(Result.success(sender))
            }
        }

        func netServiceWillResolve(_ sender: NetService) {
            BonjourLogger.info("Bonjour service will resolve", sender)
        }

        func netServiceDidStop(_ sender: NetService) {
            BonjourLogger.info("Bonjour service stopped resolving", sender)
            withExtendedLifetime(self) {
                resolver?.resolveDidStop()
            }
        }
    }
}
#endif
