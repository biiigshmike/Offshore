//
//  IncomeServiceIntegrationTests.swift
//  OffshoreBudgetingTests
//

import XCTest
import CoreData
#if canImport(Offshore)
@testable import Offshore
#elseif canImport(OffshoreBudgeting)
@testable import OffshoreBudgeting
#elseif canImport(SoFar)
@testable import SoFar
#else
#error("App module not found. Ensure the test target depends on the app target and update the conditional import.")
#endif

// MARK: - IncomeServiceIntegrationTests
final class IncomeServiceIntegrationTests: XCTestCase {
    private var stack: TestCoreDataStack! = nil
    private var service: IncomeService! = nil
    private var context: NSManagedObjectContext { stack.container.viewContext }

    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(secondsFromGMT: 0)!
        return c
    }

    override func setUp() {
        super.setUp()
        stack = TestCoreDataStack()
        service = IncomeService(stack: stack, calendar: cal)
    }

    override func tearDown() {
        stack = nil
        service = nil
        super.tearDown()
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var comps = DateComponents(); comps.year = y; comps.month = m; comps.day = d
        return cal.date(from: comps)!
    }

    // MARK: - Create monthly recurrence persists children
    func testCreateRecurringMonthlyPersistsChildren() throws {
        let base = date(2024, 1, 15)
        let end = date(2024, 3, 31)
        let inc = try service.createIncome(source: "Paycheck",
                                           amount: 1000,
                                           date: base,
                                           isPlanned: true,
                                           recurrence: "monthly",
                                           recurrenceEndDate: end)

        // Fetch children by parentID
        let request = Income.fetchRequest()
        request.predicate = NSPredicate(format: "parentID == %@", inc.id! as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(Income.date), ascending: true)]
        let children = try context.fetch(request)

        XCTAssertEqual(children.count, 2, "Expected two projected monthly children")
        XCTAssertTrue(cal.isDate(children[0].date!, inSameDayAs: date(2024, 2, 15)))
        XCTAssertTrue(cal.isDate(children[1].date!, inSameDayAs: date(2024, 3, 15)))
        XCTAssertEqual(children[0].parentID, inc.id)
    }

    // MARK: - Update future scope on a child truncates parent and creates standalone
    func testUpdateFutureScopeOnChildTruncatesParent() throws {
        let base = date(2024, 1, 10)
        let end = date(2024, 4, 30)
        let inc = try service.createIncome(source: "Salary",
                                           amount: 100,
                                           date: base,
                                           isPlanned: true,
                                           recurrence: "monthly",
                                           recurrenceEndDate: end)

        // Fetch a middle child (e.g., March 10)
        let childrenReq = Income.fetchRequest()
        childrenReq.predicate = NSPredicate(format: "parentID == %@", inc.id! as CVarArg)
        childrenReq.sortDescriptors = [NSSortDescriptor(key: #keyPath(Income.date), ascending: true)]
        let children = try context.fetch(childrenReq)
        XCTAssertEqual(children.count, 3) // Feb, Mar, Apr
        let march = children[1]
        let marchDate = march.date!

        // Update only future scope from this child
        try service.updateIncome(march, scope: .future, amount: 250)

        // Parent end date truncated to the day before the edited child
        let parentAfter = try service.findIncome(byID: inc.id!)!
        let expectedParentEnd = cal.date(byAdding: .day, value: -1, to: marchDate)!
        XCTAssertTrue(cal.isDate(parentAfter.recurrenceEndDate!, inSameDayAs: expectedParentEnd))

        // Siblings after March 10 removed
        let siblingsAfterReq = Income.fetchRequest()
        siblingsAfterReq.predicate = NSPredicate(format: "parentID == %@ AND date > %@", inc.id! as CVarArg, marchDate as CVarArg)
        let siblingsAfter = try context.fetch(siblingsAfterReq)
        XCTAssertEqual(siblingsAfter.count, 0)

        // Edited child becomes standalone (no parent, no recurrence unless explicitly set)
        XCTAssertNil(march.parentID)
        XCTAssertNil(march.recurrence)
        XCTAssertEqual(march.amount, 250)
    }

    // MARK: - Delete instance on parent promotes first child as new base
    func testDeleteInstanceOnParentPromotesFirstChild() throws {
        let base = date(2024, 1, 5)
        let end = date(2024, 3, 31)
        let parent = try service.createIncome(source: "Retainer",
                                              amount: 500,
                                              date: base,
                                              isPlanned: true,
                                              recurrence: "monthly",
                                              recurrenceEndDate: end)

        // Sanity: children exist
        var req = Income.fetchRequest()
        req.predicate = NSPredicate(format: "parentID == %@", parent.id! as CVarArg)
        req.sortDescriptors = [NSSortDescriptor(key: #keyPath(Income.date), ascending: true)]
        var children = try context.fetch(req)
        XCTAssertEqual(children.count, 2) // Feb, Mar
        let firstChildDate = children[0].date!

        // Delete the base instance only
        try service.deleteIncome(parent, scope: .instance)

        // New base is the former first child (parentID nil) with recurrence copied
        req = Income.fetchRequest()
        req.predicate = NSPredicate(format: "parentID == nil AND source == %@", "Retainer")
        req.sortDescriptors = [NSSortDescriptor(key: #keyPath(Income.date), ascending: true)]
        let bases = try context.fetch(req)
        XCTAssertTrue(bases.count >= 1)
        let newBase = bases.first!
        XCTAssertTrue(cal.isDate(newBase.date!, inSameDayAs: firstChildDate))
        XCTAssertEqual(newBase.recurrence, "monthly")

        // Its children should be regenerated to include the next month
        let newChildrenReq = Income.fetchRequest()
        newChildrenReq.predicate = NSPredicate(format: "parentID == %@", newBase.id! as CVarArg)
        let newChildren = try context.fetch(newChildrenReq)
        XCTAssertTrue(newChildren.count >= 1)
    }
}

