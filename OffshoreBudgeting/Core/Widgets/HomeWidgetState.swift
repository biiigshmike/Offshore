import Foundation

@MainActor
final class HomeWidgetState: ObservableObject {
    // MARK: Keys
    private enum Keys {
        static let pinnedStorage = "homePinnedWidgetIDs"
        static let orderStorage = "homeWidgetOrderIDs"
        static let availabilitySegmentRawValue = "homeAvailabilitySegment"
        static let scenarioAllocationsRaw = "homeScenarioAllocations"
    }

    // MARK: Stored (String)
    @Published var pinnedStorage: String = "" {
        didSet {
            guard !isSyncingFromDefaults else { return }
            defaults.set(pinnedStorage, forKey: Keys.pinnedStorage)
        }
    }

    @Published var orderStorage: String = "" {
        didSet {
            guard !isSyncingFromDefaults else { return }
            defaults.set(orderStorage, forKey: Keys.orderStorage)
        }
    }

    @Published var scenarioAllocationsRaw: String = "" {
        didSet {
            guard !isSyncingFromDefaults else { return }
            defaults.set(scenarioAllocationsRaw, forKey: Keys.scenarioAllocationsRaw)
        }
    }

    // MARK: Stored (Segment)
    @Published var availabilitySegmentRawValue: String = CategoryAvailabilitySegment.combined.rawValue {
        didSet {
            guard !isSyncingFromDefaults else { return }
            guard !isMirroringAvailabilitySegment else { return }
            isMirroringAvailabilitySegment = true
            if detailAvailabilitySegmentRawValue != availabilitySegmentRawValue {
                detailAvailabilitySegmentRawValue = availabilitySegmentRawValue
            }
            isMirroringAvailabilitySegment = false
            defaults.set(availabilitySegmentRawValue, forKey: Keys.availabilitySegmentRawValue)
        }
    }

    @Published var detailAvailabilitySegmentRawValue: String = CategoryAvailabilitySegment.combined.rawValue {
        didSet {
            guard !isSyncingFromDefaults else { return }
            guard !isMirroringAvailabilitySegment else { return }
            isMirroringAvailabilitySegment = true
            if availabilitySegmentRawValue != detailAvailabilitySegmentRawValue {
                availabilitySegmentRawValue = detailAvailabilitySegmentRawValue
            }
            isMirroringAvailabilitySegment = false
            defaults.set(detailAvailabilitySegmentRawValue, forKey: Keys.availabilitySegmentRawValue)
        }
    }

    private let defaults: UserDefaults
    private var defaultsObserver: NSObjectProtocol?
    private var isSyncingFromDefaults = false
    private var isMirroringAvailabilitySegment = false

    // MARK: Init
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        syncFromDefaults()
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: defaults,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.syncFromDefaults()
            }
        }
    }

    deinit {
        if let defaultsObserver {
            NotificationCenter.default.removeObserver(defaultsObserver)
        }
    }

    // MARK: Private
    private func syncFromDefaults() {
        isSyncingFromDefaults = true

        pinnedStorage = defaults.string(forKey: Keys.pinnedStorage) ?? ""
        orderStorage = defaults.string(forKey: Keys.orderStorage) ?? ""
        scenarioAllocationsRaw = defaults.string(forKey: Keys.scenarioAllocationsRaw) ?? ""

        let segmentDefault = CategoryAvailabilitySegment.combined.rawValue
        let segmentRaw = defaults.string(forKey: Keys.availabilitySegmentRawValue) ?? segmentDefault
        availabilitySegmentRawValue = segmentRaw
        detailAvailabilitySegmentRawValue = segmentRaw

        isSyncingFromDefaults = false
    }
}
