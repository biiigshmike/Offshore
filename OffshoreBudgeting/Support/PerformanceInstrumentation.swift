import Foundation
import SwiftUI
import os

// MARK: - UBPerf
/// Lightweight, opt-in performance instrumentation.
///
/// Contract:
/// - Disabled by default (no behavior change for normal users).
/// - Enable via launch argument `-ub-perf` or env var `UB_PERF=1`.
enum UBPerf {
    static var isEnabled: Bool {
        let info = ProcessInfo.processInfo
        if info.arguments.contains("-ub-perf") { return true }
        if info.environment["UB_PERF"] == "1" { return true }
        return UserDefaults.standard.bool(forKey: "UBPerf.enabled")
    }

    static let logger = Logger(subsystem: AppLog.subsystem, category: "Perf")
    static let diLogger = Logger(subsystem: AppLog.subsystem, category: "Perf.DI")
    static let renderLogger = Logger(subsystem: AppLog.subsystem, category: "Perf.Render")
    static let motionLogger = Logger(subsystem: AppLog.subsystem, category: "Perf.Motion")
    static let signposter = OSSignposter(subsystem: AppLog.subsystem, category: "Perf")

    private static var alsoStdout: Bool {
        guard isEnabled else { return false }
        return ProcessInfo.processInfo.environment["UB_PERF_STDOUT"] == "1"
    }

    static func emit(_ line: String) {
        guard alsoStdout else { return }
        NSLog("[UBPerf] %@", line)
    }

    static func mark(_ name: StaticString, _ message: String? = nil) {
        guard isEnabled else { return }
        if let message, !message.isEmpty {
            logger.info("\(String(describing: name), privacy: .public): \(message, privacy: .public)")
            emit("\(String(describing: name)): \(message)")
        } else {
            logger.info("\(String(describing: name), privacy: .public)")
            emit("\(String(describing: name))")
        }
    }

    @discardableResult
    static func measure<T>(_ name: StaticString, _ work: () throws -> T) rethrows -> T {
        guard isEnabled else { return try work() }
        let state = signposter.beginInterval(name)
        let start = DispatchTime.now().uptimeNanoseconds
        defer {
            let end = DispatchTime.now().uptimeNanoseconds
            signposter.endInterval(name, state)
            let ms = Double(end &- start) / 1_000_000.0
            logger.info("\(String(describing: name), privacy: .public) \(ms, format: .fixed(precision: 2))ms")
            emit("\(String(describing: name)) \(String(format: "%.2f", ms))ms")
        }
        return try work()
    }

    @discardableResult
    static func measureAsync<T>(_ name: StaticString, _ work: () async throws -> T) async rethrows -> T {
        guard isEnabled else { return try await work() }
        let state = signposter.beginInterval(name)
        let start = DispatchTime.now().uptimeNanoseconds
        defer {
            let end = DispatchTime.now().uptimeNanoseconds
            signposter.endInterval(name, state)
            let ms = Double(end &- start) / 1_000_000.0
            logger.info("\(String(describing: name), privacy: .public) \(ms, format: .fixed(precision: 2))ms")
            emit("\(String(describing: name)) \(String(format: "%.2f", ms))ms")
        }
        return try await work()
    }

    /// Thread-safe counter for high-frequency events (renders, callbacks, etc.).
    /// Logs on the 1st hit and then every `every` hits.
    static func tick(_ key: StaticString, every: Int = 100, log: Logger? = nil) {
        guard isEnabled else { return }
        let total = UBPerfCounters.shared.bumpCount(key, by: 1)
        let cadence = max(1, every)
        if total == 1 || (total % cadence == 0) {
            (log ?? logger).info("\(String(describing: key), privacy: .public) total=\(total, privacy: .public)")
            emit("\(String(describing: key)) total=\(total)")
        }
    }
}

// MARK: - UBPerf Counters (thread-safe)
private final class UBPerfCounters {
    static let shared = UBPerfCounters()
    private let lock = NSLock()
    private var counts: [String: Int] = [:]
    private var instanceIDsByKey: [String: Set<ObjectIdentifier>] = [:]

    func bumpCount(_ key: StaticString, by delta: Int = 1) -> Int {
        let k = String(describing: key)
        lock.lock()
        defer { lock.unlock() }
        let next = (counts[k] ?? 0) + delta
        counts[k] = next
        return next
    }

    func trackInstance(_ key: StaticString, instance: AnyObject) -> (total: Int, unique: Int) {
        let k = String(describing: key)
        let oid = ObjectIdentifier(instance)
        lock.lock()
        defer { lock.unlock() }
        let nextTotal = (counts[k] ?? 0) + 1
        counts[k] = nextTotal
        var set = instanceIDsByKey[k] ?? Set<ObjectIdentifier>()
        set.insert(oid)
        instanceIDsByKey[k] = set
        return (total: nextTotal, unique: set.count)
    }
}

// MARK: - Render Probes
@MainActor
private final class UBPerfRenderCounterStore: ObservableObject {
    private let name: String
    private let every: Int
    private var count: Int = 0

    init(name: StaticString, every: Int) {
        self.name = String(describing: name)
        self.every = max(1, every)
    }

    func bump() {
        count += 1
        if count == 1 || (count % every == 0) {
            let line = "\(self.name) renders=\(self.count)"
            UBPerf.renderLogger.info("\(line, privacy: .public)")
            UBPerf.emit(line)
        }
    }
}

private struct UBPerfRenderCounterModifier: ViewModifier {
    let name: StaticString
    let every: Int

    @StateObject private var store: UBPerfRenderCounterStore

    init(name: StaticString, every: Int) {
        self.name = name
        self.every = every
        _store = StateObject(wrappedValue: UBPerfRenderCounterStore(name: name, every: every))
    }

    func body(content: Content) -> some View {
        store.bump()
        return content
    }
}

private struct UBPerfRenderScope<Content: View>: View {
    let name: StaticString
    let content: Content

    var body: some View {
        let interval = UBPerf.signposter.beginInterval(name)
        let built = content
        UBPerf.signposter.endInterval(name, interval)
        return built
    }
}

extension View {
    /// Counts SwiftUI `body` re-evaluations (best-effort signal, not a guarantee of on-screen redraw).
    @ViewBuilder
    func ub_perfRenderCounter(_ name: StaticString, every: Int = 25) -> some View {
        if UBPerf.isEnabled {
            self.modifier(UBPerfRenderCounterModifier(name: name, every: every))
        } else {
            self
        }
    }

    /// Signposts view construction time for the subtree (best-effort; measures `body` build cost).
    @ViewBuilder
    func ub_perfRenderScope(_ name: StaticString) -> some View {
        if UBPerf.isEnabled {
            UBPerfRenderScope(name: name, content: self)
        } else {
            self
        }
    }
}

// MARK: - DI / Provider tracking
enum UBPerfDI {
    /// Tracks how often an injection site runs, and whether multiple unique instances are being injected.
    static func inject(_ key: StaticString, instance: AnyObject, every: Int = 50) {
        guard UBPerf.isEnabled else { return }
        let stats = UBPerfCounters.shared.trackInstance(key, instance: instance)
        if stats.unique > 1 {
            UBPerf.diLogger.error("\(String(describing: key), privacy: .public) injected multiple instances unique=\(stats.unique, privacy: .public) total=\(stats.total, privacy: .public)")
            UBPerf.emit("\(String(describing: key)) injected multiple instances unique=\(stats.unique) total=\(stats.total)")
        } else if stats.total == 1 || (stats.total % max(1, every) == 0) {
            UBPerf.diLogger.info("\(String(describing: key), privacy: .public) inject total=\(stats.total, privacy: .public) unique=\(stats.unique, privacy: .public)")
            UBPerf.emit("\(String(describing: key)) inject total=\(stats.total) unique=\(stats.unique)")
        }
    }

    /// Tracks how often a "resolution" codepath runs (service locator / factory calls).
    static func resolve(_ key: StaticString, every: Int = 100) {
        guard UBPerf.isEnabled else { return }
        let total = UBPerfCounters.shared.bumpCount(key, by: 1)
        if total == 1 || (total % max(1, every) == 0) {
            UBPerf.diLogger.info("\(String(describing: key), privacy: .public) resolve total=\(total, privacy: .public)")
            UBPerf.emit("\(String(describing: key)) resolve total=\(total)")
        }
    }
}

// MARK: - UBPerf Experiments (guarded fixes)
enum UBPerfExperiments {
    static var disableTabRemountsOnDataRevision: Bool {
        ProcessInfo.processInfo.environment["UB_PERF_EXPERIMENT_NO_TAB_REMOUNT"] == "1"
    }

    /// Diagnostic: disables the metallic title treatment for list/grid tiles (e.g., CardsView grid).
    /// Default OFF.
    static var disableListMotionEffects: Bool {
        ProcessInfo.processInfo.environment["UB_PERF_EXPERIMENT_DISABLE_LIST_MOTION_EFFECTS"] == "1"
    }

    static var importLoadOffMainActor: Bool {
        ProcessInfo.processInfo.environment["UB_PERF_EXPERIMENT_IMPORT_OFF_MAIN"] == "1"
    }

    /// Diagnostic/perf: caches derived import-row data (selectable IDs, ID→index lookups)
    /// to reduce repeated O(n) scans during SwiftUI list updates.
    /// Default OFF to preserve current behavior/perf characteristics.
    static var importStabilizeList: Bool {
        ProcessInfo.processInfo.environment["UB_PERF_EXPERIMENT_IMPORT_STABILIZE_LIST"] == "1"
    }

    /// Diagnostic/perf: debounces selection pruning on import list row updates to reduce
    /// rapid select/deselect flicker when row validity changes transiently (e.g., while editing).
    /// Default OFF to preserve current behavior.
    static var importDebounceSelectionPrune: Bool {
        ProcessInfo.processInfo.environment["UB_PERF_EXPERIMENT_IMPORT_DEBOUNCE_PRUNE"] == "1"
    }

    /// Optional override (milliseconds). If unset or invalid, defaults to 250ms.
    static var importDebounceSelectionPruneDelayMs: Int {
        guard let raw = ProcessInfo.processInfo.environment["UB_PERF_EXPERIMENT_IMPORT_DEBOUNCE_PRUNE_MS"],
              let value = Int(raw)
        else { return 250 }
        return max(0, value)
    }

    /// Perf/flicker experiment: avoid putting the SwiftUI `List` into EditMode, which can enable
    /// UIKit selection/highlight behaviors and expensive list coordinator updates.
    /// Default OFF to preserve current behavior.
    static var importAvoidListEditMode: Bool {
        ProcessInfo.processInfo.environment["UB_PERF_EXPERIMENT_IMPORT_AVOID_EDITMODE"] == "1"
    }

    /// Perf/flicker experiment: disables implicit animations within the Import screen.
    /// Default OFF to preserve current behavior.
    static var importDisableAnimations: Bool {
        ProcessInfo.processInfo.environment["UB_PERF_EXPERIMENT_IMPORT_DISABLE_ANIMATIONS"] == "1"
    }

    /// Fix A (Import flicker): dedupe rapid toggle events for the same row ID (e.g., duplicate tap delivery).
    /// Default OFF to preserve current behavior.
    static var importDedupeToggleEvents: Bool {
        ProcessInfo.processInfo.environment["UB_PERF_EXPERIMENT_IMPORT_DEDUPE_TOGGLES"] == "1"
    }

    /// Optional override (milliseconds). If unset or invalid, defaults to 100ms.
    static var importDedupeToggleWindowMs: Int {
        guard let raw = ProcessInfo.processInfo.environment["UB_PERF_EXPERIMENT_IMPORT_DEDUPE_TOGGLES_MS"],
              let value = Int(raw)
        else { return 100 }
        return max(0, value)
    }

    /// Fix B (Import flicker): do not prune selections while the user is actively selecting.
    /// Default OFF to preserve current behavior.
    static var importStickySelectionDuringSelectMode: Bool {
        ProcessInfo.processInfo.environment["UB_PERF_EXPERIMENT_IMPORT_STICKY_SELECTION"] == "1"
    }

    /// Fix C (Import speed): avoid per-row Core Data saves and external side-effects (widgets/reminders),
    /// and instead perform a single save/refresh at the end.
    /// Default OFF to preserve current behavior.
    static var importBatchWrites: Bool {
        ProcessInfo.processInfo.environment["UB_PERF_EXPERIMENT_IMPORT_BATCH_WRITES"] == "1"
    }

    /// Fix D2 (Import flicker): apply selection set changes (default selection, select all, deselect all)
    /// without implicit animations to reduce list cell highlight/tint churn.
    /// Default OFF to preserve current behavior.
    static var importSelectionSetNoAnimation: Bool {
        ProcessInfo.processInfo.environment["UB_PERF_EXPERIMENT_IMPORT_SELECTALL_NO_ANIM"] == "1"
    }

    /// Fix D3 (Import flicker): when in selection mode, render the rows using ScrollView/LazyVStack
    /// instead of SwiftUI List (UIKit-backed) to avoid selection/highlight flicker.
    /// Default OFF to preserve current behavior.
    static var importSelectModeUsesScrollView: Bool {
        ProcessInfo.processInfo.environment["UB_PERF_EXPERIMENT_IMPORT_SELECTMODE_SCROLL"] == "1"
    }

    /// Fix D (Import flicker): suppress pressed/highlight visuals for the checkmark control
    /// to reduce UIKit/SwiftUI tint/highlight flicker without changing selection state logic.
    /// Default OFF to preserve current behavior.
    static var importCheckmarkNoPressedHighlight: Bool {
        ProcessInfo.processInfo.environment["UB_PERF_EXPERIMENT_IMPORT_CHECKMARK_NO_HIGHLIGHT"] == "1"
    }

    /// Fix 1 (Motion vs Import): pause motion/effect updates in CardDetailView while the Import sheet/picker is active.
    /// Default OFF to preserve current behavior.
    static var pauseDetailMotionDuringImport: Bool {
        ProcessInfo.processInfo.environment["UB_PERF_EXPERIMENT_PAUSE_DETAIL_MOTION_DURING_IMPORT"] == "1"
    }
}
