import Foundation
import Network
import Combine

internal final class NetworkObserver: @unchecked Sendable {

    private let subject        = CurrentValueSubject<Bool, Never>(false)
    var isConnectedPublisher   : AnyPublisher<Bool, Never> { subject.eraseToAnyPublisher() }

    private let monitor        = NWPathMonitor()
    private let monitorQueue   = DispatchQueue(label: "com.adaptive.network_monitor")
    private let logger         = AdaptiveLogger.shared

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let connected = path.status == .satisfied
            self.logger.debug("NetworkObserver", "Connectivity changed → isConnected=\(connected)")
            self.subject.send(connected)
        }
        monitor.start(queue: monitorQueue)
    }

    var isCurrentlyConnected: Bool {
        monitor.currentPath.status == .satisfied
    }

    func stop() {
        monitor.cancel()
        logger.debug("NetworkObserver", "Monitor stopped.")
    }

    deinit { stop() }
}
