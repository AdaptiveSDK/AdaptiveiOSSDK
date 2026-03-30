import Foundation
import Combine

internal final class QueueProcessor: @unchecked Sendable {

    private let queue          : PersistentRequestQueue
    private let networkObserver: NetworkObserver
    private let executeRequest : (QueuedRequest) async -> Bool

    private var cancellables        = Set<AnyCancellable>()
    private var retryTask           : Task<Void, Never>?
    private var isDraining          = false
    private let logger              = AdaptiveLogger.shared
    private let retryIntervalSeconds: UInt64 = 30

    init(
        queue           : PersistentRequestQueue,
        networkObserver : NetworkObserver,
        executeRequest  : @escaping (QueuedRequest) async -> Bool
    ) {
        self.queue           = queue
        self.networkObserver = networkObserver
        self.executeRequest  = executeRequest
    }

    func start() {
        networkObserver
            .isConnectedPublisher
            .removeDuplicates()
            .sink { [weak self] isOnline in
                guard let self, isOnline else { return }
                self.logger.debug("QueueProcessor", "Online — draining queue (size=\(self.queue.size))")
                Task { await self.drainQueue() }
            }
            .store(in: &cancellables)

        retryTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: retryIntervalSeconds * 1_000_000_000)
                guard !Task.isCancelled else { return }
                guard networkObserver.isCurrentlyConnected, queue.size > 0 else { continue }
                logger.debug("QueueProcessor", "Periodic retry — draining queue (size=\(queue.size))")
                await drainQueue()
            }
        }
    }

    func stop() {
        cancellables.removeAll()
        retryTask?.cancel()
        retryTask = nil
        networkObserver.stop()
    }

    private func drainQueue() async {
        guard !isDraining else { return }
        isDraining = true
        defer { isDraining = false }

        let pending = queue.getAll()
        guard !pending.isEmpty else { return }

        for request in pending {

            if request.isExhausted {
                logger.error(
                    "QueueProcessor",
                    "Request [\(request.id)] exhausted after \(request.maxRetries) retries — dropping."
                )
                queue.remove(requestId: request.id)
                continue
            }

            if request.retryCount > 0 {
                let backoffNs = backoff(attempt: request.retryCount) * 1_000_000
                try? await Task.sleep(nanoseconds: UInt64(backoffNs))
            }

            logger.debug(
                "QueueProcessor",
                "Retrying [\(request.id)] attempt=\(request.retryCount + 1)"
            )

            let success = await executeRequest(request)

            if success {
                logger.debug("QueueProcessor", "Request [\(request.id)] succeeded on retry.")
                queue.remove(requestId: request.id)
            } else {
                queue.incrementRetry(requestId: request.id)
            }
        }
    }

    private func backoff(attempt: Int) -> UInt64 {
        return UInt64(2_000 * pow(2.0, Double(attempt)))
    }
}
