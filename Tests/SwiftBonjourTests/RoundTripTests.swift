//
//  RoundTripTests.swift
//  SwiftBonjourTests
//

#if !os(Linux) && !os(watchOS)
import Foundation
@testable import SwiftBonjour
import Testing

/// What the round trip observed, collected on the run-loop thread.
private struct RoundTripReport: Sendable {
    var published = false
    var resolvedTXTRecord: [String: String]?
    var resolvedPort = 0
    var resolvedAddressCount = 0
    var removedOnStop = false
    var servicesEmptyAfterStop = false
    var searchingAfterStop = true
    var removedAfterServerStop = false
    var timedOut = false
}

/// Drives the run loop of the thread it was created on.
private final class RunLoopDriver {
    private(set) var isFinished = false
    private var nextTurn = [() -> Void]()

    func finish() {
        isFinished = true
    }

    /// Runs `block` after the run loop has handled the events that are pending now.
    func onNextTurn(_ block: @escaping () -> Void) {
        nextTurn.append(block)
    }

    func run(timeout: TimeInterval) {
        let deadline = Date(timeIntervalSinceNow: timeout)
        while !isFinished, Date() < deadline {
            _ = RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.05))
            let blocks = nextTurn
            nextTurn.removeAll()
            blocks.forEach { $0() }
        }
    }
}

/// Runs `body` on a dedicated thread and spins that thread's run loop until `body` calls
/// `finish()` or the timeout passes. NetService and NetServiceBrowser need a running run loop.
private func runOnRunLoopThread(
    timeout: TimeInterval,
    _ body: @escaping @Sendable (RunLoopDriver) -> Void,
) async -> Bool {
    await withCheckedContinuation { continuation in
        let thread = Thread {
            let driver = RunLoopDriver()
            body(driver)
            driver.run(timeout: timeout)
            continuation.resume(returning: driver.isFinished)
        }
        thread.start()
    }
}

/// Publishes a service with a random name and drives a browser through find, resolve,
/// stop, browse again and removal. It talks to the local mDNS responder, so it needs a
/// machine with a working network stack; it is not meant for isolated VMs.
@Test(.timeLimit(.minutes(1)))
func `publish browse resolve stop and remove`() async {
    let serviceType = ServiceType.tcp("swiftbonjourtest")
    let serviceName = "SwiftBonjourTests-\(UUID().uuidString.prefix(8))"
    let txtRecord = ["key": "value", "version": "1"]

    let lock = NSLock()
    nonisolated(unsafe) var report = RoundTripReport()

    let finished = await runOnRunLoopThread(timeout: 30) { driver in
        let server = BonjourServer(type: serviceType, domain: "local.", name: serviceName)
        server.txtRecord = txtRecord
        let browser = BonjourBrowser()
        var phase = 0

        func record(_ update: (inout RoundTripReport) -> Void) {
            lock.lock()
            update(&report)
            lock.unlock()
        }

        browser.serviceResolvedHandler = { result in
            guard phase == 0, case let .success(service) = result, service.name == serviceName else {
                return
            }
            phase = 1
            record {
                $0.resolvedTXTRecord = service.txtRecordDictionary
                $0.resolvedPort = service.port
                $0.resolvedAddressCount = service.ipAddresses.count
            }

            browser.stop()
            record { $0.servicesEmptyAfterStop = browser.services.isEmpty }

            // Give the stopped browser a moment to report that it stopped, then browse
            // again to watch the service go away when the server stops.
            driver.onNextTurn {
                record { $0.searchingAfterStop = browser.isSearching }
                phase = 2
                browser.browse(type: serviceType, domain: "local.")
            }
        }

        browser.serviceFoundHandler = { service in
            guard phase == 2, service.name == serviceName else { return }
            phase = 3
            server.stop()
        }

        browser.serviceRemovedHandler = { service in
            guard service.name == serviceName else { return }
            switch phase {
            case 1:
                record { $0.removedOnStop = true }
            case 3:
                record { $0.removedAfterServerStop = true }
                browser.stop()
                withExtendedLifetime(server) { driver.finish() }
            default:
                break
            }
        }

        server.start { started in
            record { $0.published = started }
            guard started else {
                driver.finish()
                return
            }
            browser.browse(type: serviceType, domain: "local.")
        }
    }

    let result = lock.withLock { report }
    #expect(finished, "The round trip did not finish within the timeout.")
    #expect(result.published)
    #expect(result.resolvedTXTRecord == txtRecord)
    #expect(result.resolvedPort > 0)
    #expect(result.resolvedAddressCount > 0)
    #expect(result.removedOnStop)
    #expect(result.servicesEmptyAfterStop)
    #expect(!result.searchingAfterStop)
    #expect(result.removedAfterServerStop)
}
#endif
