//
//  BonjourServer.swift
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

public class BonjourServer {
    public private(set) var serviceType: ServiceType
    public private(set) var netService: NetService
    var delegate: BonjourServerDelegate?
    var successCallback: ((Bool) -> Void)?

    /// Whether a publish started by this server may still be running and needs `stop()`.
    private var isPublishing = false
    /// Whether a publish has started and its result has not been reported yet.
    private var isPublishPending = false
    private var isStartingPublish = false

    public fileprivate(set) var started = false {
        didSet {
            successCallback?(started)
            successCallback = nil
        }
    }

    public var txtRecord: [String: String]? {
        get {
            netService.txtRecordDictionary
        }
        set {
            if netService.setTXTRecord(dictionary: newValue) {
                BonjourLogger.info("TXT Record updated", newValue as Any)
            } else {
                BonjourLogger.error("TXT Record not updated", newValue as Any)
            }
        }
    }

    public init(type: ServiceType, domain: String = "", name: String = "", port: Int32 = 0) {
        serviceType = type
        netService = NetService(domain: domain, type: type.description, name: name, port: port)
        delegate = BonjourServerDelegate()
        delegate?.server = self
        netService.delegate = delegate
    }

    public func start(options: NetService.Options = [.listenForConnections]) {
        start(options: options, success: nil)
    }

    /// Publishes the service.
    ///
    /// The service is scheduled on the current thread's run loop, which must keep running
    /// for the publish to complete. A thread parked in `dispatchMain()` never publishes;
    /// use `NWListener.service` there instead.
    ///
    /// On Linux, `.listenForConnections` and `.noAutoRename` are not supported and are ignored,
    /// so the server must be created with a port greater than 0.
    public func start(options: NetService.Options = [.listenForConnections], success: ((Bool) -> Void)?) {
        if started {
            success?(true)
            return
        }
        if isPublishPending {
            // A publish is already in flight: report its result to this caller too.
            let previousCallback = successCallback
            successCallback = { started in
                previousCallback?(started)
                success?(started)
            }
            return
        }
        if isPublishing {
            // A publish that failed after it started can leave its registration allocated
            // on Linux. Release it, so that the service can publish again.
            stop()
        }
        successCallback = success
        #if os(Linux)
        // The Linux NetService schedules itself on the current run loop and
        // traps on these options.
        var options = options
        options.remove(.listenForConnections)
        options.remove(.noAutoRename)
        #else
        netService.schedule(in: RunLoop.current, forMode: RunLoop.Mode.common)
        #endif
        isPublishing = true
        isPublishPending = true
        isStartingPublish = true
        netService.publish(options: options)
        isStartingPublish = false
    }

    public func stop() {
        #if os(Linux)
        // The Linux NetService traps when stopped without a running publish.
        guard isPublishing else { return }
        #endif
        isPublishing = false
        isPublishPending = false
        netService.stop()
        started = false
        #if os(Linux)
        // The Linux NetService cannot publish again once stopped.
        let txtRecordData = netService.txtRecordData()
        netService.delegate = nil
        netService = NetService(domain: netService.domain, type: netService.type, name: netService.name, port: Int32(netService.port))
        _ = netService.setTXTRecord(txtRecordData)
        netService.delegate = delegate
        #endif
    }

    fileprivate func publishDidSucceed() {
        isPublishPending = false
        started = true
    }

    fileprivate func publishDidFail() {
        isPublishPending = false
        #if os(Linux)
        // A failure reported while the publish is still starting means it never started.
        // A later failure leaves the registration allocated until `stop()`.
        if isStartingPublish {
            isPublishing = false
        }
        #else
        isPublishing = false
        #endif
        started = false
    }

    fileprivate func publishDidStop() {
        isPublishing = false
        isPublishPending = false
        started = false
    }

    deinit {
        stop()
        netService.delegate = nil
        delegate = nil
    }
}

class BonjourServerDelegate: NSObject, NetServiceDelegate {
    weak var server: BonjourServer?

    func netServiceDidPublish(_ sender: NetService) {
        server?.publishDidSucceed()
        BonjourLogger.info("Bonjour server started at domain \(sender.domain) port \(sender.port)")
    }

    func netService(_: NetService, didNotPublish errorDict: [String: NSNumber]) {
        server?.publishDidFail()
        BonjourLogger.fault("Bonjour server did not publish", errorDict)
    }

    func netServiceDidStop(_: NetService) {
        server?.publishDidStop()
        BonjourLogger.info("Bonjour server stoped")
    }
}
#endif
