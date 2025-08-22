//
//  IncomeScreenViewModel.swift
//  SoFar
//
//  Holds selected date, fetches incomes for the date, and performs CRUD via IncomeService.
//

import Foundation
import CoreData

// MARK: - IncomeScreenViewModel
@MainActor
final class IncomeScreenViewModel: ObservableObject {
    // MARK: Public, @Published
    @Published var selectedDate: Date? = Date()
    @Published private(set) var incomesForDay: [Income] = []
    @Published private(set) var totalForSelectedDate: Double = 0
    @Published private(set) var eventsByDay: [Date: [IncomeService.IncomeEvent]] = [:]
    
    // MARK: Private
    private let incomeService: IncomeService
    private let calendar: Calendar = .current
    
    // MARK: Init
    init(incomeService: IncomeService = IncomeService()) {
        self.incomeService = incomeService
    }
    
    // MARK: Titles
    var selectedDateTitle: String {
        guard let d = selectedDate else { return "—" }
        return DateFormatter.localizedString(from: d, dateStyle: .full, timeStyle: .none)
    }
    
    var totalForSelectedDateText: String {
        NumberFormatter.currency.string(from: totalForSelectedDate as NSNumber) ?? ""
    }
    
    // MARK: Loading
    func reloadForSelectedDay() {
        guard let d = selectedDate else { return }
        load(day: d)
    }
    
    func load(day: Date) {
        do {
            incomesForDay = try incomeService.fetchIncomes(on: day)
            totalForSelectedDate = incomesForDay.reduce(0) { $0 + $1.amount }
            eventsByDay = (try? incomeService.eventsByDay(inMonthContaining: day)) ?? [:]
        } catch {
            #if DEBUG
            print("Income fetch error:", error)
            #endif
            incomesForDay = []
            totalForSelectedDate = 0
            eventsByDay = [:]
        }
    }
    
    // MARK: CRUD
    func delete(income: Income) {
        // Capture the day before deleting because accessing properties on a
        // deleted managed object can crash or yield nil. The selected date is
        // preferred, but if it's unexpectedly nil fall back to the income's
        // own date, and finally to today.
        let day = selectedDate ?? income.date ?? Date()
        do {
            try incomeService.deleteIncome(income)
            load(day: day)
        } catch {
            #if DEBUG
            print("Income delete error:", error)
            #endif
        }
    }
    
    // MARK: Formatting
    func currencyString(for amount: Double) -> String {
        NumberFormatter.currency.string(from: amount as NSNumber) ?? String(format: "%.2f", amount)
    }

    // MARK: Events Summary
    func summary(for date: Date) -> (planned: Double, actual: Double)? {
        let day = calendar.startOfDay(for: date)
        guard let events = eventsByDay[day] else { return nil }
        let planned = events.filter { $0.isPlanned }.reduce(0) { $0 + $1.amount }
        let actual = events.filter { !$0.isPlanned }.reduce(0) { $0 + $1.amount }
        if planned == 0 && actual == 0 { return nil }
        return (planned, actual)
    }
}

// MARK: - Currency NumberFormatter
private extension NumberFormatter {
    static let currency: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        return f
    }()
}
