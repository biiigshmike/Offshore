import Foundation

/// A small, generic debouncer that coalesces rapid updates and delivers only the latest value.
///
/// Usage:
/// `debouncer.send(value, delay: 0.15) { latest in ... }`
final class Debouncer<Value> {
    private let queue: DispatchQueue
    private var workItem: DispatchWorkItem?

    init(queue: DispatchQueue = .main) {
        self.queue = queue
    }

    deinit {
        workItem?.cancel()
    }

    func cancel() {
        workItem?.cancel()
        workItem = nil
    }

    func send(_ value: Value, delay: TimeInterval, action: @escaping (Value) -> Void) {
        workItem?.cancel()

        let item = DispatchWorkItem { [value] in
            action(value)
        }
        workItem = item
        queue.asyncAfter(deadline: .now() + delay, execute: item)
    }

    static func intervalMilliseconds(isImporting: Bool, normal: Int, importing: Int) -> Int {
        isImporting ? importing : normal
    }
}

