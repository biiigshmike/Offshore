import AppIntents

enum WidgetPeriod: String, CaseIterable {
    case daily
    case weekly
    case biWeekly
    case monthly
    case quarterly
    case yearly
}

@available(iOS 17.0, *)
extension WidgetPeriod: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Period"

    static var caseDisplayRepresentations: [WidgetPeriod: DisplayRepresentation] = [
        .daily: "Daily",
        .weekly: "Weekly",
        .biWeekly: "Bi-Weekly",
        .monthly: "Monthly",
        .quarterly: "Quarterly",
        .yearly: "Yearly"
    ]
}
