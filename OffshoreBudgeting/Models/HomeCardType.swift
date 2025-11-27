import Foundation

// MARK: - HomeCardType
/// Cards that can appear on the Home feed. Stored via `@AppStorage` using raw values.
enum HomeCardType: String, CaseIterable, Identifiable, Codable {
    case budgetSummary
    case recentExpenses
    case upcomingIncome

    var id: String { rawValue }

    static var defaultOrder: [HomeCardType] {
        [.budgetSummary, .recentExpenses, .upcomingIncome]
    }

    var title: String {
        switch self {
        case .budgetSummary: return "Current Budget Summary"
        case .recentExpenses: return "Recent Expenses"
        case .upcomingIncome: return "Upcoming Income"
        }
    }

    var systemImage: String {
        switch self {
        case .budgetSummary: return "chart.pie.fill"
        case .recentExpenses: return "list.bullet.rectangle.fill"
        case .upcomingIncome: return "calendar.badge.clock"
        }
    }
}
