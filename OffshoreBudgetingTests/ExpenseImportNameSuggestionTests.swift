import XCTest
@testable import Offshore

final class ExpenseImportNameSuggestionTests: XCTestCase {

    func testSuggestedExpenseName_StripsMaskedCardAndBoilerplate() {
        let raw = "RECURRING DEBIT CARD xxxxxxxxxxxxxxxx0336 INSURANCE* HPSO INDIVI HPSOCOVER.C PA"
        XCTAssertEqual(ExpenseImportViewModel.suggestedExpenseName(from: raw), "HPSO")
    }

    func testSuggestedExpenseName_StripsCityStateAndTerminalNoise() {
        let raw = "TMOBILE AU BELLEVUE WA N0919 0336 PAYMENT POS001 xxx4053"
        XCTAssertEqual(ExpenseImportViewModel.suggestedExpenseName(from: raw), "TMOBILE")
    }

    func testSuggestedExpenseName_CutsAtACH() {
        let raw = "UNITED FIN CAS INS PREM ACH DEBIT xxxxx5086 Micha"
        XCTAssertEqual(ExpenseImportViewModel.suggestedExpenseName(from: raw), "UNITED FIN CAS INS PREM")
    }

    func testSuggestedExpenseName_PrefersPhraseOverConcatenatedTail() {
        let raw = "RECURRING DEBIT CARD xxxxxxxxxxxxxxxx0336 BURST ORAL CARE BURSTORALCA CA"
        XCTAssertEqual(ExpenseImportViewModel.suggestedExpenseName(from: raw), "BURST ORAL CARE")
    }

    func testSuggestedExpenseName_DoesNotDropDigitMerchants() {
        let raw = "DEBIT CARD PURCHASE 7-ELEVEN 1234 WA"
        XCTAssertEqual(ExpenseImportViewModel.suggestedExpenseName(from: raw), "7-ELEVEN")
    }

    func testNameLearningStore_SavesAndLoadsPerWorkspace() {
        let suite = "ExpenseImportNameLearningStoreTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            XCTFail("Failed to create UserDefaults suite")
            return
        }
        defaults.removePersistentDomain(forName: suite)

        let workspaceID = UUID()
        let store = ExpenseImportNameLearningStore(defaults: defaults, workspaceID: workspaceID)

        let original = "TMOBILE AU BELLEVUE WA N0919 0336 PAYMENT POS001 xxx4053"
        store.savePreferredName("TMOBILE", forOriginalDescription: original)

        let reloaded = ExpenseImportNameLearningStore(defaults: defaults, workspaceID: workspaceID)
        XCTAssertEqual(reloaded.preferredName(forOriginalDescription: original), "TMOBILE")
    }
}

