import Foundation

enum UbiquitousFlags {
    static func hasCloudData() -> Bool {
        CloudStateFacade.Flags.hasCloudData()
    }

    static func setHasCloudDataTrue() {
        CloudStateFacade.Flags.setHasCloudDataTrue()
    }

    static func clearHasCloudData() {
        CloudStateFacade.Flags.clearHasCloudData()
    }
}
