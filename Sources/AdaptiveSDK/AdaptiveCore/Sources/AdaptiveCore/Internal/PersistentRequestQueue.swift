import Foundation


internal final class PersistentRequestQueue {

    private let keychainKey  = "com.adaptive.request_queue"
    private let maxQueueSize = 100
    private let lock         = NSLock()
    private let logger       = AdaptiveLogger.shared

    func push(_ request: QueuedRequest) {
        lock.lock()
        defer { lock.unlock() }

        var current = getAll()

        if current.count >= maxQueueSize {
            logger.warning("RequestQueue", "Queue full (\(maxQueueSize)). Dropping oldest request.")
            current.removeFirst()
        }

        current.append(request)
        persist(current)
        logger.debug("RequestQueue", "Queued request [\(request.id)] → total=\(current.count)")
    }

    func remove(requestId: String) {
        lock.lock()
        defer { lock.unlock() }

        let updated = getAll().filter { $0.id != requestId }
        persist(updated)
        logger.debug("RequestQueue", "Removed request [\(requestId)] → remaining=\(updated.count)")
    }

    func incrementRetry(requestId: String) {
        lock.lock()
        defer { lock.unlock() }

        var updated = getAll()
        for i in updated.indices where updated[i].id == requestId {
            updated[i].retryCount += 1
        }
        persist(updated)
    }

    func getAll() -> [QueuedRequest] {
        guard let data = KeychainHelper.read(key: keychainKey) else { return [] }
        do {
            return try JSONDecoder().decode([QueuedRequest].self, from: data)
        } catch {
            logger.error("RequestQueue", "Failed to deserialize queue — clearing. \(error)")
            clear()
            return []
        }
    }

    func clear() {
        KeychainHelper.delete(key: keychainKey)
        logger.debug("RequestQueue", "Queue cleared.")
    }

    var size: Int {
        lock.lock()
        defer { lock.unlock() }
        return getAll().count
    }

    private func persist(_ list: [QueuedRequest]) {
        guard let data = try? JSONEncoder().encode(list) else { return }
        KeychainHelper.save(key: keychainKey, data: data)
    }
}
