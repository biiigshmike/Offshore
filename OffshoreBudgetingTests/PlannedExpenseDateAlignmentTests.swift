import XCTest
import CoreData
@testable import OffshoreBudgeting

final class PlannedExpenseDateAlignmentTests: XCTestCase {
    private var container: NSPersistentContainer!
    private var context: NSManagedObjectContext!

    override func setUpWithError() throws {
        try super.setUpWithError()
        container = NSPersistentContainer(name: "OffshoreBudgetingModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]

        var loadError: Error?
        let loadExpectation = expectation(description: "Load in-memory store")
        container.loadPersistentStores { _, error in
            loadError = error
            loadExpectation.fulfill()
        }
        wait(for: [loadExpectation], timeout: 5.0)
        if let loadError { throw loadError }

        context = container.viewContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.undoManager = nil
    }

    override func tearDownWithError() throws {
        context = nil
        container = nil
        try super.tearDownWithError()
    }

    @MainActor
    func testPresetChildDateClampedWithinBudgetRange() throws {
        let calendar = Calendar(identifier: .gregorian)
        let startOfBudget = calendar.startOfDay(for: Date())
        guard let budgetEnd = calendar.date(byAdding: .day, value: 6, to: startOfBudget) else {
            XCTFail("Failed to compute budget end date")
            return
        }
        guard let futureTransactionDate = calendar.date(byAdding: .day, value: 30, to: startOfBudget) else {
            XCTFail("Failed to compute future transaction date")
            return
        }

        let budget = Budget(context: context)
        budget.setValue(UUID(), forKey: "id")
        budget.name = "Test Budget"
        budget.startDate = startOfBudget
        budget.endDate = budgetEnd
        budget.isRecurring = false

        let category = ExpenseCategory(context: context)
        category.setValue(UUID(), forKey: "id")
        category.name = "Utilities"
        category.color = "#FFFFFF"

        let card = Card(context: context)
        card.setValue(UUID(), forKey: "id")
        card.name = "Primary Card"

        try context.save()

        let viewModel = AddPlannedExpenseViewModel(context: context)
        viewModel.saveAsGlobalPreset = true
        viewModel.selectedBudgetIDs = [budget.objectID]
        viewModel.selectedCategoryID = category.objectID
        viewModel.selectedCardID = card.objectID
        viewModel.descriptionText = "Gym Membership"
        viewModel.plannedAmountString = "55"
        viewModel.actualAmountString = "0"
        viewModel.transactionDate = futureTransactionDate

        try viewModel.save()

        let request: NSFetchRequest<PlannedExpense> = PlannedExpense.fetchRequest()
        request.predicate = NSPredicate(format: "isGlobal == NO AND budget == %@", budget)
        let children = try context.fetch(request)
        XCTAssertEqual(children.count, 1)

        guard let child = children.first, let childDate = child.transactionDate else {
            XCTFail("Expected a single planned expense child with a transaction date")
            return
        }

        XCTAssertGreaterThanOrEqual(childDate, startOfBudget)
        XCTAssertLessThanOrEqual(childDate, budgetEnd)
        XCTAssertEqual(childDate, budgetEnd)
    }
}
