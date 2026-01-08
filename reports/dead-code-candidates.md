Dead Code Candidates (Heuristic)

Notes:
- Token-based counts; 0 refs may still be dynamically referenced.
- Each candidate includes a Dynamic-Risk Checklist assessment.

SAFE-REMOVE-CANDIDATE
- AppUpdateLogEntry (struct) — OffshoreBudgeting/App Update Logs/AppUpdateLogs.swift:5
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/App Update Logs/AppUpdateLogs.swift:5
  Def: struct AppUpdateLogEntry: Identifiable {
  Dynamic-Risk Checklist: none flagged
- releaseLogs (var) — OffshoreBudgeting/App Update Logs/AppUpdateLogs.swift:38
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/App Update Logs/AppUpdateLogs.swift:38
  Def: static var releaseLogs: [AppUpdateLogEntry] {
  Dynamic-Risk Checklist: none flagged
- advance (func) — OffshoreBudgeting/Models/BudgetPeriod.swift:88
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Models/BudgetPeriod.swift:88
  Def: func advance(_ date: Date, by delta: Int) -> Date {
  Dynamic-Risk Checklist: none flagged
- fromStoredValue (func) — OffshoreBudgeting/Models/CardItem.swift:30
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Models/CardItem.swift:30
  Def: static func fromStoredValue(_ raw: String?) -> CardEffect {
  Dynamic-Risk Checklist: none flagged
- OffshoreBudgetingApp (struct) — OffshoreBudgeting/OffshoreBudgetingApp.swift:13
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/OffshoreBudgetingApp.swift:13
  Def: struct OffshoreBudgetingApp: App {
  Dynamic-Risk Checklist: none flagged
- appDelegate (var) — OffshoreBudgeting/OffshoreBudgetingApp.swift:15
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/OffshoreBudgetingApp.swift:15
  Def: @UIApplicationDelegateAdaptor(OffshoreAppDelegate.self) private var appDelegate
  Dynamic-Risk Checklist: none flagged
- coreDataReady (var) — OffshoreBudgeting/OffshoreBudgetingApp.swift:20
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/OffshoreBudgetingApp.swift:20
  Def: @State private var coreDataReady = false
  Dynamic-Risk Checklist: none flagged
- dataChangeObserver (var) — OffshoreBudgeting/OffshoreBudgetingApp.swift:23
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/OffshoreBudgetingApp.swift:23
  Def: @State private var dataChangeObserver: NSObjectProtocol?
  Dynamic-Risk Checklist: none flagged
- homeContentReady (var) — OffshoreBudgeting/OffshoreBudgetingApp.swift:24
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/OffshoreBudgetingApp.swift:24
  Def: @State private var homeContentReady = false
  Dynamic-Risk Checklist: none flagged
- homeDataObserver (var) — OffshoreBudgeting/OffshoreBudgetingApp.swift:25
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/OffshoreBudgetingApp.swift:25
  Def: @State private var homeDataObserver: NSObjectProtocol?
  Dynamic-Risk Checklist: none flagged
- didTriggerInitialAppLock (var) — OffshoreBudgeting/OffshoreBudgetingApp.swift:26
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/OffshoreBudgetingApp.swift:26
  Def: @State private var didTriggerInitialAppLock = false
  Dynamic-Risk Checklist: none flagged
- systemColorScheme (var) — OffshoreBudgeting/OffshoreBudgetingApp.swift:28
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/OffshoreBudgetingApp.swift:28
  Def: @Environment(\.colorScheme) private var systemColorScheme
  Dynamic-Risk Checklist: none flagged
- scenePhase (var) — OffshoreBudgeting/OffshoreBudgetingApp.swift:29
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/OffshoreBudgetingApp.swift:29
  Def: @Environment(\.scenePhase) private var scenePhase
  Dynamic-Risk Checklist: none flagged
- labelAppearance (let) — OffshoreBudgeting/OffshoreBudgetingApp.swift:43
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/OffshoreBudgetingApp.swift:43
  Def: let labelAppearance = UILabel.appearance()
  Dynamic-Risk Checklist: none flagged
- configuredScene (func) — OffshoreBudgeting/OffshoreBudgetingApp.swift:94
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/OffshoreBudgetingApp.swift:94
  Def: private func configuredScene<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
  Dynamic-Risk Checklist: none flagged
- startDataReadinessFlow (func) — OffshoreBudgeting/OffshoreBudgetingApp.swift:191
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/OffshoreBudgetingApp.swift:191
  Def: private func startDataReadinessFlow() {
  Dynamic-Risk Checklist: none flagged
- workspaceReady (var) — OffshoreBudgeting/OffshoreBudgetingApp.swift:215
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/OffshoreBudgetingApp.swift:215
  Def: private var workspaceReady: Bool {
  Dynamic-Risk Checklist: none flagged
- configureForUITestingIfNeeded (func) — OffshoreBudgeting/OffshoreBudgetingApp.swift:251
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/OffshoreBudgetingApp.swift:251
  Def: private func configureForUITestingIfNeeded() {
  Dynamic-Risk Checklist: none flagged
- resetPersistentStateForUITests (func) — OffshoreBudgeting/OffshoreBudgetingApp.swift:275
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/OffshoreBudgetingApp.swift:275
  Def: private func resetPersistentStateForUITests() {
  Dynamic-Risk Checklist: none flagged
- resetUserDefaultsForUITests (func) — OffshoreBudgeting/OffshoreBudgetingApp.swift:283
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/OffshoreBudgetingApp.swift:283
  Def: private func resetUserDefaultsForUITests() {
  Dynamic-Risk Checklist: none flagged
- logPlatformCapabilities (func) — OffshoreBudgeting/OffshoreBudgetingApp.swift:296
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/OffshoreBudgetingApp.swift:296
  Def: private func logPlatformCapabilities() {
  Dynamic-Risk Checklist: none flagged
- helpActivityType (var) — OffshoreBudgeting/OffshoreBudgetingApp.swift:304
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/OffshoreBudgetingApp.swift:304
  Def: private var helpActivityType: String {
  Dynamic-Risk Checklist: none flagged
- catalystHelpSceneIdentifier (var) — OffshoreBudgeting/OffshoreBudgetingApp.swift:308
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/OffshoreBudgetingApp.swift:308
  Def: private var catalystHelpSceneIdentifier: String { "help" }
  Dynamic-Risk Checklist: none flagged
- requestHelpScene (func) — OffshoreBudgeting/OffshoreBudgetingApp.swift:310
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/OffshoreBudgetingApp.swift:310
  Def: private func requestHelpScene() {
  Dynamic-Risk Checklist: none flagged
- TestUIOverridesModifier (struct) — OffshoreBudgeting/OffshoreBudgetingApp.swift:319
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/OffshoreBudgetingApp.swift:319
  Def: private struct TestUIOverridesModifier: ViewModifier {
  Dynamic-Risk Checklist: none flagged
- testUIOverridesIfAny (func) — OffshoreBudgeting/OffshoreBudgetingApp.swift:344
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/OffshoreBudgetingApp.swift:344
  Def: func testUIOverridesIfAny() -> TestUIOverridesModifier.Overrides {
  Dynamic-Risk Checklist: none flagged
- uiTestingFlagsIfAny (func) — OffshoreBudgeting/OffshoreBudgetingApp.swift:391
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/OffshoreBudgetingApp.swift:391
  Def: func uiTestingFlagsIfAny() -> UITestingFlags {
  Dynamic-Risk Checklist: none flagged
- seedForUITests (func) — OffshoreBudgeting/OffshoreBudgetingApp.swift:400
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/OffshoreBudgetingApp.swift:400
  Def: func seedForUITests(scenario: String) async {
  Dynamic-Risk Checklist: none flagged
- ThemedToggleTint (struct) — OffshoreBudgeting/OffshoreBudgetingApp.swift:422
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/OffshoreBudgetingApp.swift:422
  Def: private struct ThemedToggleTint: ViewModifier {
  Dynamic-Risk Checklist: none flagged
- BudgetIncomeCalculator (struct) — OffshoreBudgeting/Resources/BudgetIncomeCalculator.swift:14
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/BudgetIncomeCalculator.swift:14
  Def: struct BudgetIncomeCalculator {
  Dynamic-Risk Checklist: none flagged
- sumKey (let) — OffshoreBudgeting/Resources/BudgetIncomeCalculator.swift:16
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/BudgetIncomeCalculator.swift:16
  Def: private static let sumKey = "totalAmount"
  Dynamic-Risk Checklist: none flagged
- sum (func) — OffshoreBudgeting/Resources/BudgetIncomeCalculator.swift:39
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/BudgetIncomeCalculator.swift:39
  Def: static func sum(in range: DateInterval,
  Dynamic-Risk Checklist: none flagged
- cardUUID (let) — OffshoreBudgeting/Resources/CardItem+CoreDataBridge.swift:30
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/CardItem+CoreDataBridge.swift:30
  Def: let cardUUID: UUID = managedCard.value(forKey: "id") as? UUID ?? UUID()
  Dynamic-Risk Checklist: none flagged
- cancellable (var) — OffshoreBudgeting/Resources/CoreDataEntityChangeMonitor.swift:25
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/CoreDataEntityChangeMonitor.swift:25
  Def: private var cancellable: AnyCancellable?
  Dynamic-Risk Checklist: none flagged
- merged (let) — OffshoreBudgeting/Resources/CoreDataEntityChangeMonitor.swift:121
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/CoreDataEntityChangeMonitor.swift:121
  Def: let merged = objectsDidChangePublisher
  Dynamic-Risk Checklist: none flagged
- NotificationPayloadDigest (struct) — OffshoreBudgeting/Resources/CoreDataEntityChangeMonitor.swift:171
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/CoreDataEntityChangeMonitor.swift:171
  Def: struct NotificationPayloadDigest: Equatable {
  Dynamic-Risk Checklist: none flagged
- mapping (var) — OffshoreBudgeting/Resources/CoreDataEntityChangeMonitor.swift:184
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/CoreDataEntityChangeMonitor.swift:184
  Def: var mapping: [String: Set<String>] = [:]
  Dynamic-Risk Checklist: none flagged
- addIdentifiers (func) — OffshoreBudgeting/Resources/CoreDataEntityChangeMonitor.swift:186
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/CoreDataEntityChangeMonitor.swift:186
  Def: func addIdentifiers(_ identifiers: [String], for key: String) {
  Dynamic-Risk Checklist: none flagged
- containsRelevantObjects (func) — OffshoreBudgeting/Resources/CoreDataEntityChangeMonitor.swift:213
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/CoreDataEntityChangeMonitor.swift:213
  Def: static func containsRelevantObjects(
  Dynamic-Risk Checklist: none flagged
- containsRelevantObjectIDs (func) — OffshoreBudgeting/Resources/CoreDataEntityChangeMonitor.swift:227
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/CoreDataEntityChangeMonitor.swift:227
  Def: static func containsRelevantObjectIDs(
  Dynamic-Risk Checklist: none flagged
- extractManagedObjects (func) — OffshoreBudgeting/Resources/CoreDataEntityChangeMonitor.swift:241
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/CoreDataEntityChangeMonitor.swift:241
  Def: static func extractManagedObjects(from value: Any?) -> [NSManagedObject]? {
  Dynamic-Risk Checklist: none flagged
- extractManagedObjectIDs (func) — OffshoreBudgeting/Resources/CoreDataEntityChangeMonitor.swift:260
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/CoreDataEntityChangeMonitor.swift:260
  Def: static func extractManagedObjectIDs(from value: Any?) -> [NSManagedObjectID]? {
  Dynamic-Risk Checklist: none flagged
- CoreDataListObserver (class) — OffshoreBudgeting/Resources/CoreDataListObserver.swift:22
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/CoreDataListObserver.swift:22
  Def: final class CoreDataListObserver<T: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate {
  Dynamic-Risk Checklist: none flagged
- started (var) — OffshoreBudgeting/Resources/CoreDataListObserver.swift:27
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/CoreDataListObserver.swift:27
  Def: private var started = false
  Dynamic-Risk Checklist: none flagged
- controllerDidChangeContent (func) — OffshoreBudgeting/Resources/CoreDataListObserver.swift:72
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/CoreDataListObserver.swift:72
  Def: func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
  Dynamic-Risk Checklist: none flagged
- DataRevisionKey (struct) — OffshoreBudgeting/Resources/DataRevisionEnvironment.swift:3
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/DataRevisionEnvironment.swift:3
  Def: private struct DataRevisionKey: EnvironmentKey {
  Dynamic-Risk Checklist: none flagged
- titleFont (var) — OffshoreBudgeting/Resources/HolographicMetallicText.swift:30
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/HolographicMetallicText.swift:30
  Def: var titleFont: Font = Font.system(.title, design: .rounded).weight(.semibold)
  Dynamic-Risk Checklist: none flagged
- maxMetallicOpacity (var) — OffshoreBudgeting/Resources/HolographicMetallicText.swift:32
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/HolographicMetallicText.swift:32
  Def: var maxMetallicOpacity: Double = 0.6
  Dynamic-Risk Checklist: none flagged
- maxShineOpacity (var) — OffshoreBudgeting/Resources/HolographicMetallicText.swift:33
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/HolographicMetallicText.swift:33
  Def: var maxShineOpacity: Double = 0.7
  Dynamic-Risk Checklist: none flagged
- verticalResponse (var) — OffshoreBudgeting/Resources/HolographicMetallicText.swift:123
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/HolographicMetallicText.swift:123
  Def: var verticalResponse: Double {
  Dynamic-Risk Checklist: none flagged
- metallicOpacity (var) — OffshoreBudgeting/Resources/HolographicMetallicText.swift:141
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/HolographicMetallicText.swift:141
  Def: var metallicOpacity: Double {
  Dynamic-Risk Checklist: none flagged
- scaled (let) — OffshoreBudgeting/Resources/HolographicMetallicText.swift:145
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/HolographicMetallicText.swift:145
  Def: let scaled = min(maxMetallicOpacity, max(0.0, magnitude * shimmerResponsiveness))
  Dynamic-Risk Checklist: none flagged
- shineOpacity (var) — OffshoreBudgeting/Resources/HolographicMetallicText.swift:154
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/HolographicMetallicText.swift:154
  Def: var shineOpacity: Double {
  Dynamic-Risk Checklist: none flagged
- scaled (let) — OffshoreBudgeting/Resources/HolographicMetallicText.swift:158
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/HolographicMetallicText.swift:158
  Def: let scaled = min(maxShineOpacity, max(0.0, magnitude * (shimmerResponsiveness + 0.5)))
  Dynamic-Risk Checklist: none flagged
- shineIntensity (var) — OffshoreBudgeting/Resources/HolographicMetallicText.swift:167
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/HolographicMetallicText.swift:167
  Def: var shineIntensity: Double {
  Dynamic-Risk Checklist: none flagged
- metallicAngle (var) — OffshoreBudgeting/Resources/HolographicMetallicText.swift:180
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/HolographicMetallicText.swift:180
  Def: var metallicAngle: Angle {
  Dynamic-Risk Checklist: none flagged
- shineAngle (var) — OffshoreBudgeting/Resources/HolographicMetallicText.swift:191
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/HolographicMetallicText.swift:191
  Def: var shineAngle: Angle {
  Dynamic-Risk Checklist: none flagged
- alignedTransactionDate (func) — OffshoreBudgeting/Resources/PlannedExpenseService+Templates.swift:17
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/PlannedExpenseService+Templates.swift:17
  Def: private func alignedTransactionDate(for template: PlannedExpense, budget: Budget) -> Date? {
  Dynamic-Risk Checklist: none flagged
- fetchGlobalTemplates (func) — OffshoreBudgeting/Resources/PlannedExpenseService+Templates.swift:62
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/PlannedExpenseService+Templates.swift:62
  Def: func fetchGlobalTemplates(in context: NSManagedObjectContext, workspaceID: UUID) -> [PlannedExpense] {
  Dynamic-Risk Checklist: none flagged
- fetchChildren (func) — OffshoreBudgeting/Resources/PlannedExpenseService+Templates.swift:84
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/PlannedExpenseService+Templates.swift:84
  Def: func fetchChildren(of template: PlannedExpense, in context: NSManagedObjectContext, workspaceID: UUID) -> [PlannedExpense] {
  Dynamic-Risk Checklist: none flagged
- removeChild (func) — OffshoreBudgeting/Resources/PlannedExpenseService+Templates.swift:196
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/PlannedExpenseService+Templates.swift:196
  Def: func removeChild(from template: PlannedExpense,
  Dynamic-Risk Checklist: none flagged
- fetchAllBudgets (func) — OffshoreBudgeting/Resources/PlannedExpenseService+Templates.swift:229
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/PlannedExpenseService+Templates.swift:229
  Def: func fetchAllBudgets(in context: NSManagedObjectContext, workspaceID: UUID) -> [Budget] {
  Dynamic-Risk Checklist: none flagged
- deleteTemplateAndChildren (func) — OffshoreBudgeting/Resources/PlannedExpenseService+Templates.swift:245
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/PlannedExpenseService+Templates.swift:245
  Def: func deleteTemplateAndChildren(template: PlannedExpense, in context: NSManagedObjectContext) throws {
  Dynamic-Risk Checklist: none flagged
- updateTemplateHierarchy (func) — OffshoreBudgeting/Resources/PlannedExpenseService+Templates.swift:269
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/PlannedExpenseService+Templates.swift:269
  Def: func updateTemplateHierarchy(for expense: PlannedExpense,
  Dynamic-Risk Checklist: none flagged
- fetchTemplate (func) — OffshoreBudgeting/Resources/PlannedExpenseService+Templates.swift:312
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/PlannedExpenseService+Templates.swift:312
  Def: private func fetchTemplate(withID id: UUID, in context: NSManagedObjectContext, workspaceID: UUID) -> PlannedExpense? {
  Dynamic-Risk Checklist: none flagged
- icsCode (var) — OffshoreBudgeting/Resources/RecurrenceRule.swift:28
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/RecurrenceRule.swift:28
  Def: var icsCode: String {
  Dynamic-Risk Checklist: none flagged
- fromICS (func) — OffshoreBudgeting/Resources/RecurrenceRule.swift:40
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/RecurrenceRule.swift:40
  Def: static func fromICS(_ code: String) -> Weekday? {
  Dynamic-Risk Checklist: none flagged
- toRRule (func) — OffshoreBudgeting/Resources/RecurrenceRule.swift:79
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/RecurrenceRule.swift:79
  Def: func toRRule(starting: Date) -> Built? {
  Dynamic-Risk Checklist: none flagged
- parse (func) — OffshoreBudgeting/Resources/RecurrenceRule.swift:108
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/RecurrenceRule.swift:108
  Def: static func parse(from rrule: String, endDate: Date?, secondBiMonthlyPayDay: Int) -> RecurrenceRule? {
  Dynamic-Risk Checklist: none flagged
- clampDay (func) — OffshoreBudgeting/Resources/RecurrenceRule.swift:155
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/RecurrenceRule.swift:155
  Def: private static func clampDay(_ day: Int) -> Int {
  Dynamic-Risk Checklist: none flagged
- clampDay (func) — OffshoreBudgeting/Resources/RecurrenceRule.swift:158
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/RecurrenceRule.swift:158
  Def: private func clampDay(_ day: Int) -> Int {
  Dynamic-Risk Checklist: none flagged
- SaveError (enum) — OffshoreBudgeting/Resources/SaveError.swift:14
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/SaveError.swift:14
  Def: public enum SaveError: Error, LocalizedError, Identifiable {
  Dynamic-Risk Checklist: none flagged
- errorDescription (var) — OffshoreBudgeting/Resources/SaveError.swift:34
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/SaveError.swift:34
  Def: public var errorDescription: String? { message }
  Dynamic-Risk Checklist: none flagged
- asPublicError (func) — OffshoreBudgeting/Resources/SaveError.swift:38
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/SaveError.swift:38
  Def: public func asPublicError() -> Error { self }
  Dynamic-Risk Checklist: none flagged
- describe (func) — OffshoreBudgeting/Resources/SaveError.swift:42
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/SaveError.swift:42
  Def: public static func describe(_ error: NSError) -> String {
  Dynamic-Risk Checklist: none flagged
- deleteOnly (let) — OffshoreBudgeting/Resources/UnifiedSwipeActions.swift:56
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/UnifiedSwipeActions.swift:56
  Def: public static let deleteOnly = UnifiedSwipeConfig(showsEditAction: false)
  Dynamic-Risk Checklist: none flagged
- defaultDeleteTint (var) — OffshoreBudgeting/Resources/UnifiedSwipeActions.swift:59
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/UnifiedSwipeActions.swift:59
  Def: public static var defaultDeleteTint: Color {
  Dynamic-Risk Checklist: none flagged
- defaultEditTint (var) — OffshoreBudgeting/Resources/UnifiedSwipeActions.swift:63
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/UnifiedSwipeActions.swift:63
  Def: public static var defaultEditTint: Color {
  Dynamic-Risk Checklist: none flagged
- UnifiedSwipeCustomAction (struct) — OffshoreBudgeting/Resources/UnifiedSwipeActions.swift:76
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/UnifiedSwipeActions.swift:76
  Def: public struct UnifiedSwipeCustomAction: Identifiable {
  Dynamic-Risk Checklist: none flagged
- UnifiedSwipeActionsModifier (struct) — OffshoreBudgeting/Resources/UnifiedSwipeActions.swift:103
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/UnifiedSwipeActions.swift:103
  Def: private struct UnifiedSwipeActionsModifier: ViewModifier {
  Dynamic-Risk Checklist: none flagged
- deleteButton (func) — OffshoreBudgeting/Resources/UnifiedSwipeActions.swift:154
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/UnifiedSwipeActions.swift:154
  Def: private func deleteButton() -> some View {
  Dynamic-Risk Checklist: none flagged
- editButton (func) — OffshoreBudgeting/Resources/UnifiedSwipeActions.swift:173
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/UnifiedSwipeActions.swift:173
  Def: private func editButton(onEdit: @escaping () -> Void) -> some View {
  Dynamic-Risk Checklist: none flagged
- customButtons (func) — OffshoreBudgeting/Resources/UnifiedSwipeActions.swift:190
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/UnifiedSwipeActions.swift:190
  Def: private func customButtons() -> some View {
  Dynamic-Risk Checklist: none flagged
- UnifiedSwipeActionButtonLabel (struct) — OffshoreBudgeting/Resources/UnifiedSwipeActions.swift:208
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/UnifiedSwipeActions.swift:208
  Def: private struct UnifiedSwipeActionButtonLabel: View {
  Dynamic-Risk Checklist: none flagged
- triggerDelete (func) — OffshoreBudgeting/Resources/UnifiedSwipeActions.swift:233
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/UnifiedSwipeActions.swift:233
  Def: private func triggerDelete() {
  Dynamic-Risk Checklist: none flagged
- accessibilityIdentifierIfAvailable (func) — OffshoreBudgeting/Resources/UnifiedSwipeActions.swift:263
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/UnifiedSwipeActions.swift:263
  Def: func accessibilityIdentifierIfAvailable(_ identifier: String?) -> some View {
  Dynamic-Risk Checklist: none flagged
- ub_swipeActionTint (func) — OffshoreBudgeting/Resources/UnifiedSwipeActions.swift:272
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/UnifiedSwipeActions.swift:272
  Def: func ub_swipeActionTint(_ color: Color) -> some View {
  Dynamic-Risk Checklist: none flagged
- applySwipeActionTintIfNeeded (func) — OffshoreBudgeting/Resources/UnifiedSwipeActions.swift:277
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/UnifiedSwipeActions.swift:277
  Def: func applySwipeActionTintIfNeeded(_ color: Color?) -> some View {
  Dynamic-Risk Checklist: none flagged
- contrastingColor (func) — OffshoreBudgeting/Resources/UnifiedSwipeActions.swift:295
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/UnifiedSwipeActions.swift:295
  Def: static func contrastingColor(red: CGFloat, green: CGFloat, blue: CGFloat) -> Color {
  Dynamic-Risk Checklist: none flagged
- ifLet (func) — OffshoreBudgeting/Resources/View+If.swift:10
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/View+If.swift:10
  Def: func ifLet<T, Content: View>(_ value: T?, transform: (Self, T) -> Content) -> some View {
  Dynamic-Risk Checklist: none flagged
- errorDescription (var) — OffshoreBudgeting/Services/BiometricAuthenticationManager.swift:26
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/BiometricAuthenticationManager.swift:26
  Def: public var errorDescription: String? {
  Dynamic-Risk Checklist: none flagged
- supportedBiometryType (func) — OffshoreBudgeting/Services/BiometricAuthenticationManager.swift:67
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/BiometricAuthenticationManager.swift:67
  Def: public func supportedBiometryType() -> LABiometryType {
  Dynamic-Risk Checklist: none flagged
- canEvaluateBiometrics (func) — OffshoreBudgeting/Services/BiometricAuthenticationManager.swift:76
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/BiometricAuthenticationManager.swift:76
  Def: public func canEvaluateBiometrics(errorOut: inout BiometricError?) -> Bool {
  Dynamic-Risk Checklist: none flagged
- canEvaluateDeviceOwnerAuthentication (func) — OffshoreBudgeting/Services/BiometricAuthenticationManager.swift:93
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/BiometricAuthenticationManager.swift:93
  Def: public func canEvaluateDeviceOwnerAuthentication(errorOut: inout BiometricError?) -> Bool {
  Dynamic-Risk Checklist: none flagged
- evaluateCanUseBiometrics (func) — OffshoreBudgeting/Services/BiometricAuthenticationManager.swift:158
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/BiometricAuthenticationManager.swift:158
  Def: private func evaluateCanUseBiometrics(context: LAContext) throws -> Bool {
  Dynamic-Risk Checklist: none flagged
- evaluateCanUse (func) — OffshoreBudgeting/Services/BiometricAuthenticationManager.swift:169
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/BiometricAuthenticationManager.swift:169
  Def: private func evaluateCanUse(policy: LAPolicy, context: LAContext) throws -> Bool {
  Dynamic-Risk Checklist: none flagged
- mapLAError (func) — OffshoreBudgeting/Services/BiometricAuthenticationManager.swift:179
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/BiometricAuthenticationManager.swift:179
  Def: private func mapLAError(_ nsError: NSError) -> BiometricError {
  Dynamic-Risk Checklist: none flagged
- fetchAllBudgets (func) — OffshoreBudgeting/Services/BudgetService.swift:29
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/BudgetService.swift:29
  Def: func fetchAllBudgets(sortByStartDateDescending: Bool = true) throws -> [Budget] {
  Dynamic-Risk Checklist: none flagged
- findBudget (func) — OffshoreBudgeting/Services/BudgetService.swift:42
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/BudgetService.swift:42
  Def: func findBudget(byID id: UUID) throws -> Budget? {
  Dynamic-Risk Checklist: none flagged
- fetchActiveBudget (func) — OffshoreBudgeting/Services/BudgetService.swift:56
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/BudgetService.swift:56
  Def: func fetchActiveBudget(on date: Date = Date()) throws -> Budget? {
  Dynamic-Risk Checklist: none flagged
- createBudget (func) — OffshoreBudgeting/Services/BudgetService.swift:80
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/BudgetService.swift:80
  Def: func createBudget(name: String,
  Dynamic-Risk Checklist: none flagged
- updateBudget (func) — OffshoreBudgeting/Services/BudgetService.swift:115
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/BudgetService.swift:115
  Def: func updateBudget(_ budget: Budget,
  Dynamic-Risk Checklist: none flagged
- deleteBudget (func) — OffshoreBudgeting/Services/BudgetService.swift:139
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/BudgetService.swift:139
  Def: func deleteBudget(_ budget: Budget) throws {
  Dynamic-Risk Checklist: none flagged
- fetchAllCards (func) — OffshoreBudgeting/Services/CardService.swift:49
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CardService.swift:49
  Def: func fetchAllCards(sortedByName: Bool = true) throws -> [Card] {
  Dynamic-Risk Checklist: none flagged
- findCard (func) — OffshoreBudgeting/Services/CardService.swift:87
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CardService.swift:87
  Def: func findCard(byID id: UUID) throws -> Card? {
  Dynamic-Risk Checklist: none flagged
- countCards (func) — OffshoreBudgeting/Services/CardService.swift:101
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CardService.swift:101
  Def: func countCards(named name: String) throws -> Int {
  Dynamic-Risk Checklist: none flagged
- createCard (func) — OffshoreBudgeting/Services/CardService.swift:118
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CardService.swift:118
  Def: func createCard(name: String,
  Dynamic-Risk Checklist: none flagged
- renameCard (func) — OffshoreBudgeting/Services/CardService.swift:152
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CardService.swift:152
  Def: func renameCard(_ card: Card, to newName: String) throws {
  Dynamic-Risk Checklist: none flagged
- updateCard (func) — OffshoreBudgeting/Services/CardService.swift:164
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CardService.swift:164
  Def: func updateCard(_ card: Card, name: String? = nil, theme: CardTheme? = nil, effect: CardEffect? = nil) throws {
  Dynamic-Risk Checklist: none flagged
- deleteCard (func) — OffshoreBudgeting/Services/CardService.swift:176
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CardService.swift:176
  Def: func deleteCard(_ card: Card) throws {
  Dynamic-Risk Checklist: none flagged
- deleteAllCards (func) — OffshoreBudgeting/Services/CardService.swift:183
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CardService.swift:183
  Def: func deleteAllCards() throws {
  Dynamic-Risk Checklist: none flagged
- attachCard (func) — OffshoreBudgeting/Services/CardService.swift:192
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CardService.swift:192
  Def: func attachCard(_ card: Card, toBudgetsWithIDs budgetIDs: [UUID]) throws {
  Dynamic-Risk Checklist: none flagged
- detachCard (func) — OffshoreBudgeting/Services/CardService.swift:215
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CardService.swift:215
  Def: func detachCard(_ card: Card, fromBudgetsWithIDs budgetIDs: [UUID]) throws {
  Dynamic-Risk Checklist: none flagged
- replaceCard (func) — OffshoreBudgeting/Services/CardService.swift:237
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CardService.swift:237
  Def: func replaceCard(_ card: Card, budgetsWithIDs budgetIDs: [UUID]) throws {
  Dynamic-Risk Checklist: none flagged
- isCloudAccountAvailable (var) — OffshoreBudgeting/Services/CloudAccountStatusProvider.swift:41
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CloudAccountStatusProvider.swift:41
  Def: var isCloudAccountAvailable: Bool? {
  Dynamic-Risk Checklist: none flagged
- isChecking (var) — OffshoreBudgeting/Services/CloudAccountStatusProvider.swift:50
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CloudAccountStatusProvider.swift:50
  Def: private var isChecking = false
  Dynamic-Risk Checklist: none flagged
- coreDataZoneID (var) — OffshoreBudgeting/Services/CloudAccountStatusProvider.swift:53
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CloudAccountStatusProvider.swift:53
  Def: private var coreDataZoneID: CKRecordZone.ID? {
  Dynamic-Risk Checklist: none flagged
- coreDataZoneIdentifier (let) — OffshoreBudgeting/Services/CloudAccountStatusProvider.swift:58
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CloudAccountStatusProvider.swift:58
  Def: private static let coreDataZoneIdentifier = CKRecordZone.ID(
  Dynamic-Risk Checklist: none flagged
- requestAccountStatusCheck (func) — OffshoreBudgeting/Services/CloudAccountStatusProvider.swift:87
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CloudAccountStatusProvider.swift:87
  Def: func requestAccountStatusCheck(force: Bool = false) {
  Dynamic-Risk Checklist: none flagged
- resolveAvailability (func) — OffshoreBudgeting/Services/CloudAccountStatusProvider.swift:101
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CloudAccountStatusProvider.swift:101
  Def: func resolveAvailability(forceRefresh: Bool = false) async -> Bool {
  Dynamic-Risk Checklist: none flagged
- probeNamedContainer (func) — OffshoreBudgeting/Services/CloudAccountStatusProvider.swift:139
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CloudAccountStatusProvider.swift:139
  Def: private func probeNamedContainer(_ container: CKContainer) async -> Bool {
  Dynamic-Risk Checklist: none flagged
- shouldTreatErrorAsReachable (func) — OffshoreBudgeting/Services/CloudAccountStatusProvider.swift:169
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CloudAccountStatusProvider.swift:169
  Def: private static func shouldTreatErrorAsReachable(_ error: Error) -> Bool {
  Dynamic-Risk Checklist: none flagged
- isCloudAccountAvailable (var) — OffshoreBudgeting/Services/CloudAccountStatusProvider.swift:198
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CloudAccountStatusProvider.swift:198
  Def: var isCloudAccountAvailable: Bool? { get }
  Dynamic-Risk Checklist: none flagged
- availabilityPublisher (var) — OffshoreBudgeting/Services/CloudAccountStatusProvider.swift:199
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CloudAccountStatusProvider.swift:199
  Def: var availabilityPublisher: AnyPublisher<CloudAccountStatusProvider.Availability, Never> { get }
  Dynamic-Risk Checklist: none flagged
- requestAccountStatusCheck (func) — OffshoreBudgeting/Services/CloudAccountStatusProvider.swift:200
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CloudAccountStatusProvider.swift:200
  Def: func requestAccountStatusCheck(force: Bool)
  Dynamic-Risk Checklist: none flagged
- hasAnyData (func) — OffshoreBudgeting/Services/CloudDataProbe.swift:10
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CloudDataProbe.swift:10
  Def: func hasAnyData() -> Bool {
  Dynamic-Risk Checklist: none flagged
- scanForExistingData (func) — OffshoreBudgeting/Services/CloudDataProbe.swift:18
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CloudDataProbe.swift:18
  Def: func scanForExistingData(timeout: TimeInterval = 3.0,
  Dynamic-Risk Checklist: none flagged
- hasAnyDataOnce (func) — OffshoreBudgeting/Services/CloudDataProbe.swift:32
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CloudDataProbe.swift:32
  Def: private func hasAnyDataOnce() -> Bool {
  Dynamic-Risk Checklist: none flagged
- database (let) — OffshoreBudgeting/Services/CloudDataRemoteProbe.swift:8
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CloudDataRemoteProbe.swift:8
  Def: private let database: CKDatabase
  Dynamic-Risk Checklist: none flagged
- recordTypes (let) — OffshoreBudgeting/Services/CloudDataRemoteProbe.swift:11
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CloudDataRemoteProbe.swift:11
  Def: private let recordTypes = [
  Dynamic-Risk Checklist: none flagged
- hasAnyRemoteData (func) — OffshoreBudgeting/Services/CloudDataRemoteProbe.swift:21
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CloudDataRemoteProbe.swift:21
  Def: func hasAnyRemoteData(timeout: TimeInterval = 6.0) async -> Bool {
  Dynamic-Risk Checklist: none flagged
- hasRecord (func) — OffshoreBudgeting/Services/CloudDataRemoteProbe.swift:36
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CloudDataRemoteProbe.swift:36
  Def: private func hasRecord(ofType recordType: String) async throws -> Bool {
  Dynamic-Risk Checklist: none flagged
- CloudDiagnostics (class) — OffshoreBudgeting/Services/CloudDiagnostics.swift:7
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CloudDiagnostics.swift:7
  Def: final class CloudDiagnostics: ObservableObject {
  Dynamic-Risk Checklist: none flagged
- cloudEventObserver (var) — OffshoreBudgeting/Services/CloudDiagnostics.swift:14
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CloudDiagnostics.swift:14
  Def: private var cloudEventObserver: NSObjectProtocol?
  Dynamic-Risk Checklist: none flagged
- lastNudge (var) — OffshoreBudgeting/Services/CloudSyncAccelerator.swift:17
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CloudSyncAccelerator.swift:17
  Def: private var lastNudge: Date?
  Dynamic-Risk Checklist: none flagged
- minNudgeInterval (let) — OffshoreBudgeting/Services/CloudSyncAccelerator.swift:20
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CloudSyncAccelerator.swift:20
  Def: private let minNudgeInterval: TimeInterval = 5.0
  Dynamic-Risk Checklist: none flagged
- awaitInitialImport (func) — OffshoreBudgeting/Services/CloudSyncMonitor.swift:41
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CloudSyncMonitor.swift:41
  Def: func awaitInitialImport(timeout: TimeInterval = 10.0, pollInterval: TimeInterval = 0.1) async -> Bool {
  Dynamic-Risk Checklist: none flagged
- modelName (let) — OffshoreBudgeting/Services/CoreDataService.swift:28
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CoreDataService.swift:28
  Def: private let modelName = "OffshoreBudgetingModel"
  Dynamic-Risk Checklist: none flagged
- cloudKitContainerIdentifier (var) — OffshoreBudgeting/Services/CoreDataService.swift:31
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CoreDataService.swift:31
  Def: private var cloudKitContainerIdentifier: String { CloudKitConfig.containerIdentifier }
  Dynamic-Risk Checklist: none flagged
- enableCloudKitSync (var) — OffshoreBudgeting/Services/CoreDataService.swift:34
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CoreDataService.swift:34
  Def: private var enableCloudKitSync: Bool {
  Dynamic-Risk Checklist: none flagged
- loadingTask (var) — OffshoreBudgeting/Services/CoreDataService.swift:38
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CoreDataService.swift:38
  Def: private var loadingTask: Task<Void, Never>?
  Dynamic-Risk Checklist: none flagged
- didSaveObserver (var) — OffshoreBudgeting/Services/CoreDataService.swift:46
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CoreDataService.swift:46
  Def: private var didSaveObserver: NSObjectProtocol?
  Dynamic-Risk Checklist: none flagged
- remoteChangeObserver (var) — OffshoreBudgeting/Services/CoreDataService.swift:47
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CoreDataService.swift:47
  Def: private var remoteChangeObserver: NSObjectProtocol?
  Dynamic-Risk Checklist: none flagged
- cloudKitEventObserver (var) — OffshoreBudgeting/Services/CoreDataService.swift:48
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CoreDataService.swift:48
  Def: private var cloudKitEventObserver: NSObjectProtocol?
  Dynamic-Risk Checklist: none flagged
- isRebuildingStores (var) — OffshoreBudgeting/Services/CoreDataService.swift:49
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CoreDataService.swift:49
  Def: private var isRebuildingStores: Bool = false
  Dynamic-Risk Checklist: none flagged
- storeModeDescription (var) — OffshoreBudgeting/Services/CoreDataService.swift:56
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CoreDataService.swift:56
  Def: public var storeModeDescription: String { _currentMode == .cloudKit ? "CloudKit" : "Local" }
  Dynamic-Risk Checklist: none flagged
- isCloudStoreActive (var) — OffshoreBudgeting/Services/CoreDataService.swift:58
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CoreDataService.swift:58
  Def: public var isCloudStoreActive: Bool { _currentMode == .cloudKit }
  Dynamic-Risk Checklist: none flagged
- cloudContainer (let) — OffshoreBudgeting/Services/CoreDataService.swift:65
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CoreDataService.swift:65
  Def: let cloudContainer = NSPersistentCloudKitContainer(name: modelName)
  Dynamic-Risk Checklist: none flagged
- storeURL (let) — OffshoreBudgeting/Services/CoreDataService.swift:68
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CoreDataService.swift:68
  Def: let storeURL = NSPersistentContainer.defaultDirectoryURL()
  Dynamic-Risk Checklist: none flagged
- initialMode (let) — OffshoreBudgeting/Services/CoreDataService.swift:82
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CoreDataService.swift:82
  Def: let initialMode: PersistentStoreMode = (enableCloudKitSync ? .cloudKit : .local)
  Dynamic-Risk Checklist: none flagged
- ensureLoaded (func) — OffshoreBudgeting/Services/CoreDataService.swift:107
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CoreDataService.swift:107
  Def: func ensureLoaded(file: StaticString = #file, line: UInt = #line) {
  Dynamic-Risk Checklist: none flagged
- postLoadConfiguration (func) — OffshoreBudgeting/Services/CoreDataService.swift:126
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CoreDataService.swift:126
  Def: private func postLoadConfiguration() {
  Dynamic-Risk Checklist: none flagged
- startObservingChanges (func) — OffshoreBudgeting/Services/CoreDataService.swift:148
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CoreDataService.swift:148
  Def: private func startObservingChanges() {
  Dynamic-Risk Checklist: none flagged
- startObservingRemoteChangesIfNeeded (func) — OffshoreBudgeting/Services/CoreDataService.swift:165
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CoreDataService.swift:165
  Def: private func startObservingRemoteChangesIfNeeded() {
  Dynamic-Risk Checklist: none flagged
- startObservingCloudKitEventsIfNeeded (func) — OffshoreBudgeting/Services/CoreDataService.swift:178
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CoreDataService.swift:178
  Def: private func startObservingCloudKitEventsIfNeeded() {
  Dynamic-Risk Checklist: none flagged
- performBackgroundTask (func) — OffshoreBudgeting/Services/CoreDataService.swift:212
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CoreDataService.swift:212
  Def: func performBackgroundTask(_ work: @escaping (NSManagedObjectContext) throws -> Void) {
  Dynamic-Risk Checklist: none flagged
- loadStores (func) — OffshoreBudgeting/Services/CoreDataService.swift:333
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CoreDataService.swift:333
  Def: func loadStores(file: StaticString, line: UInt) async {
  Dynamic-Risk Checklist: none flagged
- disableCloudSyncPreferences (func) — OffshoreBudgeting/Services/CoreDataService.swift:374
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CoreDataService.swift:374
  Def: func disableCloudSyncPreferences() {
  Dynamic-Risk Checklist: none flagged
- reconfigurePersistentStoresForLocalMode (func) — OffshoreBudgeting/Services/CoreDataService.swift:380
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CoreDataService.swift:380
  Def: func reconfigurePersistentStoresForLocalMode() async {
  Dynamic-Risk Checklist: none flagged
- PersistentStoreMode (enum) — OffshoreBudgeting/Services/CoreDataService.swift:384
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CoreDataService.swift:384
  Def: private enum PersistentStoreMode: Equatable { case local, cloudKit
  Dynamic-Risk Checklist: none flagged
- logDescription (var) — OffshoreBudgeting/Services/CoreDataService.swift:385
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CoreDataService.swift:385
  Def: var logDescription: String {
  Dynamic-Risk Checklist: none flagged
- configure (func) — OffshoreBudgeting/Services/CoreDataService.swift:393
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CoreDataService.swift:393
  Def: private func configure(description: NSPersistentStoreDescription, for mode: PersistentStoreMode) {
  Dynamic-Risk Checklist: none flagged
- rebuildPersistentStores (func) — OffshoreBudgeting/Services/CoreDataService.swift:406
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CoreDataService.swift:406
  Def: private func rebuildPersistentStores(for mode: PersistentStoreMode) async {
  Dynamic-Risk Checklist: none flagged
- initializeCloudKitSchemaIfNeeded (func) — OffshoreBudgeting/Services/CoreDataService.swift:469
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/CoreDataService.swift:469
  Def: func initializeCloudKitSchemaIfNeeded() async {
  Dynamic-Risk Checklist: none flagged
- ExpenseCategoryService (class) — OffshoreBudgeting/Services/ExpenseCategoryService.swift:16
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/ExpenseCategoryService.swift:16
  Def: final class ExpenseCategoryService {
  Dynamic-Risk Checklist: none flagged
- fetchAllCategories (func) — OffshoreBudgeting/Services/ExpenseCategoryService.swift:26
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/ExpenseCategoryService.swift:26
  Def: func fetchAllCategories(sortedByName: Bool = true) throws -> [ExpenseCategory] {
  Dynamic-Risk Checklist: none flagged
- findCategory (func) — OffshoreBudgeting/Services/ExpenseCategoryService.swift:45
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/ExpenseCategoryService.swift:45
  Def: func findCategory(byID id: UUID) throws -> ExpenseCategory? {
  Dynamic-Risk Checklist: none flagged
- findCategory (func) — OffshoreBudgeting/Services/ExpenseCategoryService.swift:61
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/ExpenseCategoryService.swift:61
  Def: func findCategory(named name: String) throws -> ExpenseCategory? {
  Dynamic-Risk Checklist: none flagged
- updateCategory (func) — OffshoreBudgeting/Services/ExpenseCategoryService.swift:103
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/ExpenseCategoryService.swift:103
  Def: func updateCategory(_ category: ExpenseCategory,
  Dynamic-Risk Checklist: none flagged
- deleteCategory (func) — OffshoreBudgeting/Services/ExpenseCategoryService.swift:114
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/ExpenseCategoryService.swift:114
  Def: func deleteCategory(_ category: ExpenseCategory) throws {
  Dynamic-Risk Checklist: none flagged
- deleteAllCategories (func) — OffshoreBudgeting/Services/ExpenseCategoryService.swift:121
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/ExpenseCategoryService.swift:121
  Def: func deleteAllCategories() throws {
  Dynamic-Risk Checklist: none flagged
- ForceReuploadHelper (enum) — OffshoreBudgeting/Services/ForceReuploadHelper.swift:39
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/ForceReuploadHelper.swift:39
  Def: enum ForceReuploadHelper {
  Dynamic-Risk Checklist: none flagged
- ForceReuploadError (enum) — OffshoreBudgeting/Services/ForceReuploadHelper.swift:41
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/ForceReuploadHelper.swift:41
  Def: enum ForceReuploadError: Error {
  Dynamic-Risk Checklist: none flagged
- updatedCounts (let) — OffshoreBudgeting/Services/ForceReuploadHelper.swift:47
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/ForceReuploadHelper.swift:47
  Def: let updatedCounts: [String: Int]
  Dynamic-Risk Checklist: none flagged
- totalUpdated (var) — OffshoreBudgeting/Services/ForceReuploadHelper.swift:48
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/ForceReuploadHelper.swift:48
  Def: var totalUpdated: Int {
  Dynamic-Risk Checklist: none flagged
- forceReuploadAll (func) — OffshoreBudgeting/Services/ForceReuploadHelper.swift:56
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/ForceReuploadHelper.swift:56
  Def: static func forceReuploadAll(reason: String = "manual") async throws -> Result {
  Dynamic-Risk Checklist: none flagged
- calendarUsed (var) — OffshoreBudgeting/Services/IncomeService.swift:51
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/IncomeService.swift:51
  Def: var calendarUsed: Calendar { calendar }
  Dynamic-Risk Checklist: none flagged
- fetchAllIncomes (func) — OffshoreBudgeting/Services/IncomeService.swift:58
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/IncomeService.swift:58
  Def: func fetchAllIncomes(sortedByDateAscending: Bool = true) throws -> [Income] {
  Dynamic-Risk Checklist: none flagged
- findIncome (func) — OffshoreBudgeting/Services/IncomeService.swift:96
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/IncomeService.swift:96
  Def: func findIncome(byID id: UUID) throws -> Income? {
  Dynamic-Risk Checklist: none flagged
- createIncome (func) — OffshoreBudgeting/Services/IncomeService.swift:120
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/IncomeService.swift:120
  Def: func createIncome(source: String,
  Dynamic-Risk Checklist: none flagged
- updateIncome (func) — OffshoreBudgeting/Services/IncomeService.swift:150
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/IncomeService.swift:150
  Def: func updateIncome(_ income: Income,
  Dynamic-Risk Checklist: none flagged
- deleteIncome (func) — OffshoreBudgeting/Services/IncomeService.swift:257
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/IncomeService.swift:257
  Def: func deleteIncome(_ income: Income, scope: RecurrenceScope = .all) throws {
  Dynamic-Risk Checklist: none flagged
- deleteAllIncomes (func) — OffshoreBudgeting/Services/IncomeService.swift:354
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/IncomeService.swift:354
  Def: func deleteAllIncomes() throws {
  Dynamic-Risk Checklist: none flagged
- totalAmount (func) — OffshoreBudgeting/Services/IncomeService.swift:404
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/IncomeService.swift:404
  Def: func totalAmount(in interval: DateInterval, includePlanned: Bool? = nil) throws -> Double {
  Dynamic-Risk Checklist: none flagged
- effectiveRecurrenceEndDate (func) — OffshoreBudgeting/Services/IncomeService.swift:416
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/IncomeService.swift:416
  Def: private func effectiveRecurrenceEndDate(for income: Income, fallback: Date) -> Date {
  Dynamic-Risk Checklist: none flagged
- monthInterval (func) — OffshoreBudgeting/Services/IncomeService.swift:423
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/IncomeService.swift:423
  Def: private func monthInterval(containing date: Date) -> DateInterval {
  Dynamic-Risk Checklist: none flagged
- setOptionalInt16IfAttributeExists (func) — OffshoreBudgeting/Services/IncomeService.swift:434
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/IncomeService.swift:434
  Def: private static func setOptionalInt16IfAttributeExists(on object: NSManagedObject,
  Dynamic-Risk Checklist: none flagged
- optionalInt16IfAttributeExists (func) — OffshoreBudgeting/Services/IncomeService.swift:448
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/IncomeService.swift:448
  Def: private static func optionalInt16IfAttributeExists(on object: NSManagedObject,
  Dynamic-Risk Checklist: none flagged
- dailyReminderPrefix (let) — OffshoreBudgeting/Services/LocalNotificationScheduler.swift:16
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/LocalNotificationScheduler.swift:16
  Def: private let dailyReminderPrefix = "dailyReminder-"
  Dynamic-Risk Checklist: none flagged
- plannedIncomePrefix (let) — OffshoreBudgeting/Services/LocalNotificationScheduler.swift:17
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/LocalNotificationScheduler.swift:17
  Def: private let plannedIncomePrefix = "plannedIncome-"
  Dynamic-Risk Checklist: none flagged
- presetExpensePrefix (let) — OffshoreBudgeting/Services/LocalNotificationScheduler.swift:18
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/LocalNotificationScheduler.swift:18
  Def: private let presetExpensePrefix = "presetExpense-"
  Dynamic-Risk Checklist: none flagged
- dailyLookaheadDays (let) — OffshoreBudgeting/Services/LocalNotificationScheduler.swift:19
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/LocalNotificationScheduler.swift:19
  Def: private let dailyLookaheadDays = 30
  Dynamic-Risk Checklist: none flagged
- plannedIncomeLookaheadDays (let) — OffshoreBudgeting/Services/LocalNotificationScheduler.swift:20
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/LocalNotificationScheduler.swift:20
  Def: private let plannedIncomeLookaheadDays = 45
  Dynamic-Risk Checklist: none flagged
- requestAuthorization (func) — OffshoreBudgeting/Services/LocalNotificationScheduler.swift:35
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/LocalNotificationScheduler.swift:35
  Def: func requestAuthorization() async -> Bool {
  Dynamic-Risk Checklist: none flagged
- recordAppOpen (func) — OffshoreBudgeting/Services/LocalNotificationScheduler.swift:43
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/LocalNotificationScheduler.swift:43
  Def: func recordAppOpen() {
  Dynamic-Risk Checklist: none flagged
- refreshPlannedIncomeReminders (func) — OffshoreBudgeting/Services/LocalNotificationScheduler.swift:76
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/LocalNotificationScheduler.swift:76
  Def: func refreshPlannedIncomeReminders() async {
  Dynamic-Risk Checklist: none flagged
- refreshPresetExpenseReminders (func) — OffshoreBudgeting/Services/LocalNotificationScheduler.swift:96
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/LocalNotificationScheduler.swift:96
  Def: func refreshPresetExpenseReminders() async {
  Dynamic-Risk Checklist: none flagged
- scheduleDailyReminder (func) — OffshoreBudgeting/Services/LocalNotificationScheduler.swift:121
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/LocalNotificationScheduler.swift:121
  Def: private func scheduleDailyReminder(on date: Date) {
  Dynamic-Risk Checklist: none flagged
- schedulePlannedIncomeReminder (func) — OffshoreBudgeting/Services/LocalNotificationScheduler.swift:134
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/LocalNotificationScheduler.swift:134
  Def: private func schedulePlannedIncomeReminder(on date: Date, day: Date) {
  Dynamic-Risk Checklist: none flagged
- schedulePresetExpenseReminder (func) — OffshoreBudgeting/Services/LocalNotificationScheduler.swift:147
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/LocalNotificationScheduler.swift:147
  Def: private func schedulePresetExpenseReminder(on date: Date, expense: PlannedExpense) {
  Dynamic-Risk Checklist: none flagged
- removePendingRequests (func) — OffshoreBudgeting/Services/LocalNotificationScheduler.swift:162
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/LocalNotificationScheduler.swift:162
  Def: private func removePendingRequests(prefix: String) async {
  Dynamic-Risk Checklist: none flagged
- pendingRequests (func) — OffshoreBudgeting/Services/LocalNotificationScheduler.swift:171
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/LocalNotificationScheduler.swift:171
  Def: private func pendingRequests() async -> [UNNotificationRequest] {
  Dynamic-Risk Checklist: none flagged
- reminderTimeComponents (func) — OffshoreBudgeting/Services/LocalNotificationScheduler.swift:179
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/LocalNotificationScheduler.swift:179
  Def: private func reminderTimeComponents() -> (hour: Int, minute: Int) {
  Dynamic-Risk Checklist: none flagged
- isSameDay (func) — OffshoreBudgeting/Services/LocalNotificationScheduler.swift:185
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/LocalNotificationScheduler.swift:185
  Def: private func isSameDay(_ storedValue: Any?, _ date: Date) -> Bool {
  Dynamic-Risk Checklist: none flagged
- dayIdentifier (func) — OffshoreBudgeting/Services/LocalNotificationScheduler.swift:190
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/LocalNotificationScheduler.swift:190
  Def: private func dayIdentifier(for date: Date) -> String {
  Dynamic-Risk Checklist: none flagged
- expenseIdentifier (func) — OffshoreBudgeting/Services/LocalNotificationScheduler.swift:198
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/LocalNotificationScheduler.swift:198
  Def: private func expenseIdentifier(_ expense: PlannedExpense) -> String {
  Dynamic-Risk Checklist: none flagged
- groupIncomesByDay (func) — OffshoreBudgeting/Services/LocalNotificationScheduler.swift:205
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/LocalNotificationScheduler.swift:205
  Def: private func groupIncomesByDay(_ incomes: [Income]) -> [Date: (hasPlanned: Bool, hasActual: Bool)] {
  Dynamic-Risk Checklist: none flagged
- MergeService (class) — OffshoreBudgeting/Services/MergeService.swift:8
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/MergeService.swift:8
  Def: final class MergeService {
  Dynamic-Risk Checklist: none flagged
- mergeLocalDataIntoCloud (func) — OffshoreBudgeting/Services/MergeService.swift:13
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/MergeService.swift:13
  Def: func mergeLocalDataIntoCloud() throws {
  Dynamic-Risk Checklist: none flagged
- mergeExpenseCategories (func) — OffshoreBudgeting/Services/MergeService.swift:45
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/MergeService.swift:45
  Def: private func mergeExpenseCategories(_ ctx: NSManagedObjectContext) throws -> Bool {
  Dynamic-Risk Checklist: none flagged
- mergeCards (func) — OffshoreBudgeting/Services/MergeService.swift:65
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/MergeService.swift:65
  Def: private func mergeCards(_ ctx: NSManagedObjectContext) throws -> Bool {
  Dynamic-Risk Checklist: none flagged
- mergeBudgets (func) — OffshoreBudgeting/Services/MergeService.swift:85
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/MergeService.swift:85
  Def: private func mergeBudgets(_ ctx: NSManagedObjectContext) throws -> Bool {
  Dynamic-Risk Checklist: none flagged
- mergeIncomes (func) — OffshoreBudgeting/Services/MergeService.swift:106
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/MergeService.swift:106
  Def: private func mergeIncomes(_ ctx: NSManagedObjectContext) throws -> Bool {
  Dynamic-Risk Checklist: none flagged
- mergePlannedExpenses (func) — OffshoreBudgeting/Services/MergeService.swift:128
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/MergeService.swift:128
  Def: private func mergePlannedExpenses(_ ctx: NSManagedObjectContext) throws -> Bool {
  Dynamic-Risk Checklist: none flagged
- mergeStrictTemplateChildren (func) — OffshoreBudgeting/Services/MergeService.swift:154
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/MergeService.swift:154
  Def: private func mergeStrictTemplateChildren(_ ctx: NSManagedObjectContext) throws -> Bool {
  Dynamic-Risk Checklist: none flagged
- mergeUnplannedExpenses (func) — OffshoreBudgeting/Services/MergeService.swift:195
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/MergeService.swift:195
  Def: private func mergeUnplannedExpenses(_ ctx: NSManagedObjectContext) throws -> Bool {
  Dynamic-Risk Checklist: none flagged
- find (func) — OffshoreBudgeting/Services/PlannedExpenseService.swift:96
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/PlannedExpenseService.swift:96
  Def: func find(byID id: UUID) throws -> PlannedExpense? {
  Dynamic-Risk Checklist: none flagged
- fetchTemplatesForCard (func) — OffshoreBudgeting/Services/PlannedExpenseService.swift:193
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/PlannedExpenseService.swift:193
  Def: func fetchTemplatesForCard(_ cardID: UUID,
  Dynamic-Risk Checklist: none flagged
- fetchTemplatesForCard (func) — OffshoreBudgeting/Services/PlannedExpenseService.swift:212
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/PlannedExpenseService.swift:212
  Def: func fetchTemplatesForCard(_ cardID: UUID,
  Dynamic-Risk Checklist: none flagged
- createGlobalTemplate (func) — OffshoreBudgeting/Services/PlannedExpenseService.swift:288
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/PlannedExpenseService.swift:288
  Def: func createGlobalTemplate(titleOrDescription: String,
  Dynamic-Risk Checklist: none flagged
- instantiateTemplate (func) — OffshoreBudgeting/Services/PlannedExpenseService.swift:316
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/PlannedExpenseService.swift:316
  Def: func instantiateTemplate(_ template: PlannedExpense,
  Dynamic-Risk Checklist: none flagged
- duplicate (func) — OffshoreBudgeting/Services/PlannedExpenseService.swift:340
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/PlannedExpenseService.swift:340
  Def: func duplicate(_ expense: PlannedExpense,
  Dynamic-Risk Checklist: none flagged
- update (func) — OffshoreBudgeting/Services/PlannedExpenseService.swift:361
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/PlannedExpenseService.swift:361
  Def: func update(_ expense: PlannedExpense,
  Dynamic-Risk Checklist: none flagged
- move (func) — OffshoreBudgeting/Services/PlannedExpenseService.swift:381
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/PlannedExpenseService.swift:381
  Def: func move(_ expense: PlannedExpense, toBudgetID budgetID: UUID) throws {
  Dynamic-Risk Checklist: none flagged
- adjustActualAmount (func) — OffshoreBudgeting/Services/PlannedExpenseService.swift:398
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/PlannedExpenseService.swift:398
  Def: func adjustActualAmount(_ expense: PlannedExpense, delta: Double) throws {
  Dynamic-Risk Checklist: none flagged
- deleteAllForBudget (func) — OffshoreBudgeting/Services/PlannedExpenseService.swift:414
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/PlannedExpenseService.swift:414
  Def: func deleteAllForBudget(_ budgetID: UUID) throws {
  Dynamic-Risk Checklist: none flagged
- totalsForBudget (func) — OffshoreBudgeting/Services/PlannedExpenseService.swift:433
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/PlannedExpenseService.swift:433
  Def: func totalsForBudget(_ budgetID: UUID,
  Dynamic-Risk Checklist: none flagged
- setTitleOrDescription (func) — OffshoreBudgeting/Services/PlannedExpenseService.swift:450
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/PlannedExpenseService.swift:450
  Def: private static func setTitleOrDescription(on object: NSManagedObject, value: String) {
  Dynamic-Risk Checklist: none flagged
- getTitleOrDescription (func) — OffshoreBudgeting/Services/PlannedExpenseService.swift:465
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/PlannedExpenseService.swift:465
  Def: private static func getTitleOrDescription(from object: NSManagedObject) -> String? {
  Dynamic-Risk Checklist: none flagged
- includesTemplate (var) — OffshoreBudgeting/Services/PlannedExpenseUpdateScope.swift:36
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/PlannedExpenseUpdateScope.swift:36
  Def: var includesTemplate: Bool {
  Dynamic-Risk Checklist: none flagged
- shouldIncludeChild (func) — OffshoreBudgeting/Services/PlannedExpenseUpdateScope.swift:50
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/PlannedExpenseUpdateScope.swift:50
  Def: func shouldIncludeChild(with date: Date?, fallbackReferenceDate _: Date?) -> Bool {
  Dynamic-Risk Checklist: none flagged
- isOnOrBeforeEndDay (func) — OffshoreBudgeting/Services/RecurrenceEngine.swift:10
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/RecurrenceEngine.swift:10
  Def: private static func isOnOrBeforeEndDay(_ date: Date, interval: DateInterval, calendar: Calendar) -> Bool {
  Dynamic-Risk Checklist: none flagged
- isOnOrAfterStartDay (func) — OffshoreBudgeting/Services/RecurrenceEngine.swift:17
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/RecurrenceEngine.swift:17
  Def: private static func isOnOrAfterStartDay(_ date: Date, interval: DateInterval, calendar: Calendar) -> Bool {
  Dynamic-Risk Checklist: none flagged
- strideDates (func) — OffshoreBudgeting/Services/RecurrenceEngine.swift:135
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/RecurrenceEngine.swift:135
  Def: private static func strideDates(start: Date, stepDays: Int, within interval: DateInterval, calendar: Calendar) -> [Date] {
  Dynamic-Risk Checklist: none flagged
- strideMonthly (func) — OffshoreBudgeting/Services/RecurrenceEngine.swift:151
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/RecurrenceEngine.swift:151
  Def: private static func strideMonthly(start: Date, stepMonths: Int, within interval: DateInterval, calendar: Calendar) -> [Date] {
  Dynamic-Risk Checklist: none flagged
- strideYearly (func) — OffshoreBudgeting/Services/RecurrenceEngine.swift:162
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/RecurrenceEngine.swift:162
  Def: private static func strideYearly(start: Date, within interval: DateInterval, calendar: Calendar) -> [Date] {
  Dynamic-Risk Checklist: none flagged
- alignedToInterval (func) — OffshoreBudgeting/Services/RecurrenceEngine.swift:208
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/RecurrenceEngine.swift:208
  Def: private static func alignedToInterval(start: Date,
  Dynamic-Risk Checklist: none flagged
- clampedDayInMonth (func) — OffshoreBudgeting/Services/RecurrenceEngine.swift:221
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/RecurrenceEngine.swift:221
  Def: private static func clampedDayInMonth(_ day: Int, near monthAnchor: Date, calendar: Calendar) -> Date? {
  Dynamic-Risk Checklist: none flagged
- regenerateIncomeRecurrences (func) — OffshoreBudgeting/Services/RecurrenceEngine.swift:237
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/RecurrenceEngine.swift:237
  Def: static func regenerateIncomeRecurrences(base income: Income,
  Dynamic-Risk Checklist: none flagged
- deleteAll (func) — OffshoreBudgeting/Services/Repository/CoreDataRepository.swift:98
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/Repository/CoreDataRepository.swift:98
  Def: func deleteAll(predicate: NSPredicate? = nil) throws {
  Dynamic-Risk Checklist: none flagged
- performBackgroundTask (func) — OffshoreBudgeting/Services/Repository/CoreDataRepository.swift:122
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/Repository/CoreDataRepository.swift:122
  Def: func performBackgroundTask(_ work: @escaping (NSManagedObjectContext) throws -> Void) {
  Dynamic-Risk Checklist: none flagged
- hasCloudData (func) — OffshoreBudgeting/Services/UbiquitousFlags.swift:6
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/UbiquitousFlags.swift:6
  Def: static func hasCloudData() -> Bool {
  Dynamic-Risk Checklist: none flagged
- setHasCloudDataTrue (func) — OffshoreBudgeting/Services/UbiquitousFlags.swift:10
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/UbiquitousFlags.swift:10
  Def: static func setHasCloudDataTrue() {
  Dynamic-Risk Checklist: none flagged
- clearHasCloudData (func) — OffshoreBudgeting/Services/UbiquitousFlags.swift:17
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/UbiquitousFlags.swift:17
  Def: static func clearHasCloudData() {
  Dynamic-Risk Checklist: none flagged
- categoryRepo (let) — OffshoreBudgeting/Services/UnplannedExpenseService.swift:57
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/UnplannedExpenseService.swift:57
  Def: private let categoryRepo: CoreDataRepository<ExpenseCategory>
  Dynamic-Risk Checklist: none flagged
- find (func) — OffshoreBudgeting/Services/UnplannedExpenseService.swift:89
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/UnplannedExpenseService.swift:89
  Def: func find(byID id: UUID) throws -> UnplannedExpense? {
  Dynamic-Risk Checklist: none flagged
- fetchForCategory (func) — OffshoreBudgeting/Services/UnplannedExpenseService.swift:126
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/UnplannedExpenseService.swift:126
  Def: func fetchForCategory(_ categoryID: UUID,
  Dynamic-Risk Checklist: none flagged
- update (func) — OffshoreBudgeting/Services/UnplannedExpenseService.swift:241
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/UnplannedExpenseService.swift:241
  Def: func update(_ expense: UnplannedExpense,
  Dynamic-Risk Checklist: none flagged
- deleteAllForCard (func) — OffshoreBudgeting/Services/UnplannedExpenseService.swift:321
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/UnplannedExpenseService.swift:321
  Def: func deleteAllForCard(_ cardID: UUID) throws {
  Dynamic-Risk Checklist: none flagged
- totalForCard (func) — OffshoreBudgeting/Services/UnplannedExpenseService.swift:335
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/UnplannedExpenseService.swift:335
  Def: func totalForCard(_ cardID: UUID, in interval: DateInterval) throws -> Double {
  Dynamic-Risk Checklist: none flagged
- totalForBudget (func) — OffshoreBudgeting/Services/UnplannedExpenseService.swift:342
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/UnplannedExpenseService.swift:342
  Def: func totalForBudget(_ budgetID: UUID, in interval: DateInterval) throws -> Double {
  Dynamic-Risk Checklist: none flagged
- addChild (func) — OffshoreBudgeting/Services/UnplannedExpenseService.swift:351
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/UnplannedExpenseService.swift:351
  Def: func addChild(_ parent: UnplannedExpense, child: UnplannedExpense) throws {
  Dynamic-Risk Checklist: none flagged
- SplitPart (struct) — OffshoreBudgeting/Services/UnplannedExpenseService.swift:374
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/UnplannedExpenseService.swift:374
  Def: struct SplitPart {
  Dynamic-Risk Checklist: none flagged
- descriptionSuffix (let) — OffshoreBudgeting/Services/UnplannedExpenseService.swift:378
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/UnplannedExpenseService.swift:378
  Def: let descriptionSuffix: String?  // e.g., "(groceries)", "(household)"
  Dynamic-Risk Checklist: none flagged
- fetchRange (func) — OffshoreBudgeting/Services/UnplannedExpenseService.swift:478
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/UnplannedExpenseService.swift:478
  Def: private func fetchRange(_ interval: DateInterval) throws -> [UnplannedExpense] {
  Dynamic-Risk Checklist: none flagged
- effectiveRecurrenceEndDate (func) — OffshoreBudgeting/Services/UnplannedExpenseService.swift:491
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/UnplannedExpenseService.swift:491
  Def: private func effectiveRecurrenceEndDate(for expense: UnplannedExpense, fallback: Date) -> Date {
  Dynamic-Risk Checklist: none flagged
- monthInterval (func) — OffshoreBudgeting/Services/UnplannedExpenseService.swift:496
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/UnplannedExpenseService.swift:496
  Def: private func monthInterval(containing date: Date) -> DateInterval {
  Dynamic-Risk Checklist: none flagged
- setDescription (func) — OffshoreBudgeting/Services/UnplannedExpenseService.swift:506
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/UnplannedExpenseService.swift:506
  Def: private static func setDescription(on object: NSManagedObject, value: String) {
  Dynamic-Risk Checklist: none flagged
- getDescription (func) — OffshoreBudgeting/Services/UnplannedExpenseService.swift:515
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/UnplannedExpenseService.swift:515
  Def: private static func getDescription(from object: NSManagedObject) -> String? {
  Dynamic-Risk Checklist: none flagged
- setSecondBiMonthly (func) — OffshoreBudgeting/Services/UnplannedExpenseService.swift:526
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/UnplannedExpenseService.swift:526
  Def: private static func setSecondBiMonthly(on object: NSManagedObject,
  Dynamic-Risk Checklist: none flagged
- readSecondBiMonthly (func) — OffshoreBudgeting/Services/UnplannedExpenseService.swift:542
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/UnplannedExpenseService.swift:542
  Def: private static func readSecondBiMonthly(on object: NSManagedObject) -> (Int16?, Date?) {
  Dynamic-Risk Checklist: none flagged
- defaultsLocalKey (let) — OffshoreBudgeting/Services/WorkspaceService.swift:12
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:12
  Def: private let defaultsLocalKey = "workspace.active.local"
  Dynamic-Risk Checklist: none flagged
- defaultsCloudKey (let) — OffshoreBudgeting/Services/WorkspaceService.swift:13
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:13
  Def: private let defaultsCloudKey = "workspace.active.cloud"
  Dynamic-Risk Checklist: none flagged
- ubiquitousKey (let) — OffshoreBudgeting/Services/WorkspaceService.swift:14
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:14
  Def: private let ubiquitousKey = "workspace.active.id"
  Dynamic-Risk Checklist: none flagged
- defaultsActiveKey (let) — OffshoreBudgeting/Services/WorkspaceService.swift:15
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:15
  Def: private let defaultsActiveKey = AppSettingsKeys.activeWorkspaceID.rawValue
  Dynamic-Risk Checklist: none flagged
- defaultsSeedPersonalKey (let) — OffshoreBudgeting/Services/WorkspaceService.swift:16
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:16
  Def: private let defaultsSeedPersonalKey = "workspace.seed.personal"
  Dynamic-Risk Checklist: none flagged
- defaultsSeedWorkKey (let) — OffshoreBudgeting/Services/WorkspaceService.swift:17
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:17
  Def: private let defaultsSeedWorkKey = "workspace.seed.work"
  Dynamic-Risk Checklist: none flagged
- defaultsSeedEducationKey (let) — OffshoreBudgeting/Services/WorkspaceService.swift:18
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:18
  Def: private let defaultsSeedEducationKey = "workspace.seed.education"
  Dynamic-Risk Checklist: none flagged
- assignWorkspaceIDIfMissing (func) — OffshoreBudgeting/Services/WorkspaceService.swift:62
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:62
  Def: func assignWorkspaceIDIfMissing(to workspaceID: UUID) async {
  Dynamic-Risk Checklist: none flagged
- initializeOnLaunch (func) — OffshoreBudgeting/Services/WorkspaceService.swift:94
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:94
  Def: func initializeOnLaunch() async {
  Dynamic-Risk Checklist: none flagged
- fetchOrCreateWorkspace (func) — OffshoreBudgeting/Services/WorkspaceService.swift:108
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:108
  Def: func fetchOrCreateWorkspace(in context: NSManagedObjectContext = CoreDataService.shared.viewContext) -> NSManagedObject? {
  Dynamic-Risk Checklist: none flagged
- currentBudgetPeriod (func) — OffshoreBudgeting/Services/WorkspaceService.swift:139
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:139
  Def: func currentBudgetPeriod(in context: NSManagedObjectContext = CoreDataService.shared.viewContext) -> BudgetPeriod {
  Dynamic-Risk Checklist: none flagged
- setBudgetPeriod (func) — OffshoreBudgeting/Services/WorkspaceService.swift:150
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:150
  Def: func setBudgetPeriod(_ period: BudgetPeriod, in context: NSManagedObjectContext = CoreDataService.shared.viewContext) {
  Dynamic-Risk Checklist: none flagged
- seedBudgetPeriodIfNeeded (func) — OffshoreBudgeting/Services/WorkspaceService.swift:162
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:162
  Def: func seedBudgetPeriodIfNeeded() {
  Dynamic-Risk Checklist: none flagged
- workspacePredicate (let) — OffshoreBudgeting/Services/WorkspaceService.swift:191
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:191
  Def: let workspacePredicate = Self.predicate(for: workspaceID)
  Dynamic-Risk Checklist: none flagged
- defaultsKey (var) — OffshoreBudgeting/Services/WorkspaceService.swift:219
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:219
  Def: var defaultsKey: String {
  Dynamic-Risk Checklist: none flagged
- fetchAllWorkspaces (func) — OffshoreBudgeting/Services/WorkspaceService.swift:236
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:236
  Def: func fetchAllWorkspaces(in context: NSManagedObjectContext = CoreDataService.shared.viewContext) -> [Workspace] {
  Dynamic-Risk Checklist: none flagged
- fetchWorkspace (func) — OffshoreBudgeting/Services/WorkspaceService.swift:244
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:244
  Def: func fetchWorkspace(byID id: UUID, in context: NSManagedObjectContext = CoreDataService.shared.viewContext) -> Workspace? {
  Dynamic-Risk Checklist: none flagged
- createWorkspace (func) — OffshoreBudgeting/Services/WorkspaceService.swift:251
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:251
  Def: func createWorkspace(named name: String, in context: NSManagedObjectContext = CoreDataService.shared.viewContext) -> Workspace? {
  Dynamic-Risk Checklist: none flagged
- renameWorkspace (func) — OffshoreBudgeting/Services/WorkspaceService.swift:269
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:269
  Def: func renameWorkspace(_ workspace: Workspace, to name: String, in context: NSManagedObjectContext = CoreDataService.shared.viewContext) -> Bool {
  Dynamic-Risk Checklist: none flagged
- deleteWorkspace (func) — OffshoreBudgeting/Services/WorkspaceService.swift:282
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:282
  Def: func deleteWorkspace(_ workspace: Workspace, in context: NSManagedObjectContext = CoreDataService.shared.viewContext) -> Bool {
  Dynamic-Risk Checklist: none flagged
- personalWorkspace (func) — OffshoreBudgeting/Services/WorkspaceService.swift:304
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:304
  Def: func personalWorkspace(in context: NSManagedObjectContext = CoreDataService.shared.viewContext) -> Workspace? {
  Dynamic-Risk Checklist: none flagged
- isPersonalWorkspace (func) — OffshoreBudgeting/Services/WorkspaceService.swift:317
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:317
  Def: func isPersonalWorkspace(_ workspace: Workspace) -> Bool {
  Dynamic-Risk Checklist: none flagged
- isWorkspaceNameAvailable (func) — OffshoreBudgeting/Services/WorkspaceService.swift:333
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:333
  Def: func isWorkspaceNameAvailable(_ name: String, excluding workspace: Workspace?, in context: NSManagedObjectContext) -> Bool {
  Dynamic-Risk Checklist: none flagged
- workspaceNameExists (func) — OffshoreBudgeting/Services/WorkspaceService.swift:363
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:363
  Def: func workspaceNameExists(_ name: String, excluding workspace: Workspace?, in context: NSManagedObjectContext) -> Bool {
  Dynamic-Risk Checklist: none flagged
- cleanupDuplicateWorkspaces (func) — OffshoreBudgeting/Services/WorkspaceService.swift:374
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:374
  Def: func cleanupDuplicateWorkspaces(in context: NSManagedObjectContext) {
  Dynamic-Risk Checklist: none flagged
- preferredWorkspace (func) — OffshoreBudgeting/Services/WorkspaceService.swift:502
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:502
  Def: func preferredWorkspace(from candidates: [Workspace], seedIDs: [UUID]) -> Workspace {
  Dynamic-Risk Checklist: none flagged
- defaultWorkspaceName (func) — OffshoreBudgeting/Services/WorkspaceService.swift:518
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:518
  Def: func defaultWorkspaceName(for id: UUID) -> String {
  Dynamic-Risk Checklist: none flagged
- seedColorHex (func) — OffshoreBudgeting/Services/WorkspaceService.swift:523
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:523
  Def: func seedColorHex(for seed: WorkspaceSeed) -> String {
  Dynamic-Risk Checklist: none flagged
- defaultWorkspaceColorHex (func) — OffshoreBudgeting/Services/WorkspaceService.swift:534
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:534
  Def: func defaultWorkspaceColorHex(for id: UUID) -> String {
  Dynamic-Risk Checklist: none flagged
- applySeedColorIfNeeded (func) — OffshoreBudgeting/Services/WorkspaceService.swift:541
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:541
  Def: func applySeedColorIfNeeded(_ workspace: Workspace, seed: WorkspaceSeed) {
  Dynamic-Risk Checklist: none flagged
- ensureDefaultWorkspaces (func) — OffshoreBudgeting/Services/WorkspaceService.swift:549
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:549
  Def: func ensureDefaultWorkspaces(in context: NSManagedObjectContext) -> [Workspace] {
  Dynamic-Risk Checklist: none flagged
- readSeedWorkspaceID (func) — OffshoreBudgeting/Services/WorkspaceService.swift:598
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:598
  Def: func readSeedWorkspaceID(for seed: WorkspaceSeed) -> UUID? {
  Dynamic-Risk Checklist: none flagged
- seedName (func) — OffshoreBudgeting/Services/WorkspaceService.swift:613
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:613
  Def: func seedName(for id: UUID) -> String? {
  Dynamic-Risk Checklist: none flagged
- persistSeedWorkspaceID (func) — OffshoreBudgeting/Services/WorkspaceService.swift:622
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:622
  Def: func persistSeedWorkspaceID(_ id: UUID, for seed: WorkspaceSeed) {
  Dynamic-Risk Checklist: none flagged
- legacyActiveWorkspaceID (func) — OffshoreBudgeting/Services/WorkspaceService.swift:633
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/WorkspaceService.swift:633
  Def: func legacyActiveWorkspaceID() -> UUID? {
  Dynamic-Risk Checklist: none flagged
- verboseKey (let) — OffshoreBudgeting/Support/Logging.swift:17
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Support/Logging.swift:17
  Def: private static let verboseKey = "AppLog.verbose"
  Dynamic-Risk Checklist: none flagged
- setVerbose (func) — OffshoreBudgeting/Support/Logging.swift:25
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Support/Logging.swift:25
  Def: static func setVerbose(_ enabled: Bool) { isVerbose = enabled }
  Dynamic-Risk Checklist: none flagged
- OffshoreAppDelegate (class) — OffshoreBudgeting/Systems/AppDelegate.swift:7
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppDelegate.swift:7
  Def: final class OffshoreAppDelegate: NSObject, UIApplicationDelegate {
  Dynamic-Risk Checklist: none flagged
- disableAppThemeSync (func) — OffshoreBudgeting/Systems/AppTheme.swift:67
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:67
  Def: static func disableAppThemeSync(in defaults: UserDefaults) { /* no-op */ }
  Dynamic-Risk Checklist: none flagged
- systemNeutralAccent (var) — OffshoreBudgeting/Systems/AppTheme.swift:96
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:96
  Def: private static var systemNeutralAccent: Color {
  Dynamic-Risk Checklist: none flagged
- toggleTint (var) — OffshoreBudgeting/Systems/AppTheme.swift:127
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:127
  Def: var toggleTint: Color { Color(UIColor.systemGreen) }
  Dynamic-Risk Checklist: none flagged
- secondaryAccent (var) — OffshoreBudgeting/Systems/AppTheme.swift:130
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:130
  Def: var secondaryAccent: Color {
  Dynamic-Risk Checklist: none flagged
- h (var) — OffshoreBudgeting/Systems/AppTheme.swift:132
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:132
  Def: var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
  Dynamic-Risk Checklist: none flagged
- secondaryBackground (var) — OffshoreBudgeting/Systems/AppTheme.swift:142
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:142
  Def: var secondaryBackground: Color { Color(UIColor.secondarySystemBackground) }
  Dynamic-Risk Checklist: none flagged
- tertiaryBackground (var) — OffshoreBudgeting/Systems/AppTheme.swift:145
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:145
  Def: var tertiaryBackground: Color { Color(UIColor.tertiarySystemBackground) }
  Dynamic-Risk Checklist: none flagged
- sheetBackground (var) — OffshoreBudgeting/Systems/AppTheme.swift:148
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:148
  Def: var sheetBackground: Color { Color(UIColor.systemGroupedBackground) }
  Dynamic-Risk Checklist: none flagged
- formRowBackground (func) — OffshoreBudgeting/Systems/AppTheme.swift:153
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:153
  Def: func formRowBackground(for colorScheme: ColorScheme) -> Color {
  Dynamic-Risk Checklist: none flagged
- primaryTextColor (func) — OffshoreBudgeting/Systems/AppTheme.swift:163
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:163
  Def: func primaryTextColor(for colorScheme: ColorScheme) -> Color {
  Dynamic-Risk Checklist: none flagged
- baseGlassConfiguration (var) — OffshoreBudgeting/Systems/AppTheme.swift:174
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:174
  Def: var baseGlassConfiguration: GlassConfiguration {
  Dynamic-Risk Checklist: none flagged
- glassBaseColor (var) — OffshoreBudgeting/Systems/AppTheme.swift:179
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:179
  Def: var glassBaseColor: Color { AppTheme.systemGlassBaseColor(resolvedTint: resolvedTint) }
  Dynamic-Risk Checklist: none flagged
- neutralAccent (let) — OffshoreBudgeting/Systems/AppTheme.swift:187
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:187
  Def: let neutralAccent = Color(UIColor { trait in
  Dynamic-Risk Checklist: none flagged
- neutralShadow (let) — OffshoreBudgeting/Systems/AppTheme.swift:194
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:194
  Def: let neutralShadow = Color(UIColor { trait in
  Dynamic-Risk Checklist: none flagged
- neutralSpecular (let) — OffshoreBudgeting/Systems/AppTheme.swift:201
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:201
  Def: let neutralSpecular = Color(UIColor { trait in
  Dynamic-Risk Checklist: none flagged
- neutralRim (let) — OffshoreBudgeting/Systems/AppTheme.swift:208
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:208
  Def: let neutralRim = Color(UIColor { trait in
  Dynamic-Risk Checklist: none flagged
- accentTone (let) — OffshoreBudgeting/Systems/AppTheme.swift:216
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:216
  Def: let accentTone = AppThemeColorUtilities.adjust(
  Dynamic-Risk Checklist: none flagged
- shadowTone (let) — OffshoreBudgeting/Systems/AppTheme.swift:222
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:222
  Def: let shadowTone = AppThemeColorUtilities.adjust(
  Dynamic-Risk Checklist: none flagged
- specularTone (let) — OffshoreBudgeting/Systems/AppTheme.swift:228
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:228
  Def: let specularTone = AppThemeColorUtilities.adjust(
  Dynamic-Risk Checklist: none flagged
- rimTone (let) — OffshoreBudgeting/Systems/AppTheme.swift:234
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:234
  Def: let rimTone = AppThemeColorUtilities.adjust(
  Dynamic-Risk Checklist: none flagged
- tabBarPalette (var) — OffshoreBudgeting/Systems/AppTheme.swift:250
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:250
  Def: var tabBarPalette: TabBarPalette {
  Dynamic-Risk Checklist: none flagged
- badgeBrightness (let) — OffshoreBudgeting/Systems/AppTheme.swift:274
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:274
  Def: let badgeBrightness = AppThemeColorUtilities.hsba(from: resolvedTint)?.brightness ?? 0.85
  Dynamic-Risk Checklist: none flagged
- isDark (let) — OffshoreBudgeting/Systems/AppTheme.swift:313
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:313
  Def: let isDark = trait.userInterfaceStyle == .dark
  Dynamic-Risk Checklist: none flagged
- legacyUIKitChromeBackgroundColor (func) — OffshoreBudgeting/Systems/AppTheme.swift:319
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:319
  Def: func legacyUIKitChromeBackgroundColor(colorScheme: ColorScheme?) -> UIColor {
  Dynamic-Risk Checklist: none flagged
- systemGlassConfiguration (func) — OffshoreBudgeting/Systems/AppTheme.swift:336
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:336
  Def: static func systemGlassConfiguration(resolvedTint: Color) -> GlassConfiguration {
  Dynamic-Risk Checklist: none flagged
- systemGlassBaseColor (func) — OffshoreBudgeting/Systems/AppTheme.swift:424
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:424
  Def: static func systemGlassBaseColor(resolvedTint: Color) -> Color {
  Dynamic-Risk Checklist: none flagged
- LiquidSettings (struct) — OffshoreBudgeting/Systems/AppTheme.swift:466
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:466
  Def: struct LiquidSettings {
  Dynamic-Risk Checklist: none flagged
- shapeStyle (var) — OffshoreBudgeting/Systems/AppTheme.swift:484
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:484
  Def: var shapeStyle: AnyShapeStyle {
  Dynamic-Risk Checklist: none flagged
- uiBlurEffectStyle (var) — OffshoreBudgeting/Systems/AppTheme.swift:495
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:495
  Def: var uiBlurEffectStyle: UIBlurEffect.Style {
  Dynamic-Risk Checklist: none flagged
- highlightColor (var) — OffshoreBudgeting/Systems/AppTheme.swift:506
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:506
  Def: var highlightColor: Color
  Dynamic-Risk Checklist: none flagged
- TranslucentDefaults (enum) — OffshoreBudgeting/Systems/AppTheme.swift:537
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:537
  Def: enum TranslucentDefaults {
  Dynamic-Risk Checklist: none flagged
- liquidAmount (let) — OffshoreBudgeting/Systems/AppTheme.swift:538
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:538
  Def: static let liquidAmount: Double = 0.7
  Dynamic-Risk Checklist: none flagged
- glassAmount (let) — OffshoreBudgeting/Systems/AppTheme.swift:539
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:539
  Def: static let glassAmount: Double = 0.68
  Dynamic-Risk Checklist: none flagged
- translucent (func) — OffshoreBudgeting/Systems/AppTheme.swift:583
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:583
  Def: static func translucent(
  Dynamic-Risk Checklist: none flagged
- legacyLiquidGlassIdentifier (let) — OffshoreBudgeting/Systems/AppTheme.swift:795
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:795
  Def: private static let legacyLiquidGlassIdentifier = "tahoe"
  Dynamic-Risk Checklist: none flagged
- cachedUbiquitousStore (var) — OffshoreBudgeting/Systems/AppTheme.swift:797
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:797
  Def: private var cachedUbiquitousStore: UbiquitousKeyValueStoring?
  Dynamic-Risk Checklist: none flagged
- defaultCloudStatusProviderFactory (let) — OffshoreBudgeting/Systems/AppTheme.swift:799
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:799
  Def: private let defaultCloudStatusProviderFactory: () -> CloudAvailabilityProviding
  Dynamic-Risk Checklist: none flagged
- isApplyingRemoteChange (var) — OffshoreBudgeting/Systems/AppTheme.swift:806
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:806
  Def: private var isApplyingRemoteChange = false
  Dynamic-Risk Checklist: none flagged
- refreshSystemAppearance (func) — OffshoreBudgeting/Systems/AppTheme.swift:858
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:858
  Def: func refreshSystemAppearance(_ colorScheme: ColorScheme) {
  Dynamic-Risk Checklist: none flagged
- resolveTheme (func) — OffshoreBudgeting/Systems/AppTheme.swift:879
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:879
  Def: private static func resolveTheme(from raw: String?) -> AppTheme {
  Dynamic-Risk Checklist: none flagged
- isThemeSyncEnabled (func) — OffshoreBudgeting/Systems/AppTheme.swift:887
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:887
  Def: private static func isThemeSyncEnabled(in defaults: UserDefaults) -> Bool {
  Dynamic-Risk Checklist: none flagged
- isCloudAvailable (func) — OffshoreBudgeting/Systems/AppTheme.swift:893
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:893
  Def: private static func isCloudAvailable(from provider: CloudAvailabilityProviding) -> Bool {
  Dynamic-Risk Checklist: none flagged
- resolveCloudStatusProvider (func) — OffshoreBudgeting/Systems/AppTheme.swift:899
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:899
  Def: private func resolveCloudStatusProvider() -> CloudAvailabilityProviding {
  Dynamic-Risk Checklist: none flagged
- scheduleAvailabilityCheckIfNeeded (func) — OffshoreBudgeting/Systems/AppTheme.swift:920
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:920
  Def: private func scheduleAvailabilityCheckIfNeeded(for provider: CloudAvailabilityProviding) {
  Dynamic-Risk Checklist: none flagged
- shouldUseICloud (var) — OffshoreBudgeting/Systems/AppTheme.swift:929
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:929
  Def: private var shouldUseICloud: Bool {
  Dynamic-Risk Checklist: none flagged
- handleCloudAvailabilityChange (func) — OffshoreBudgeting/Systems/AppTheme.swift:936
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:936
  Def: private func handleCloudAvailabilityChange(_ availability: CloudAccountStatusProvider.Availability) {
  Dynamic-Risk Checklist: none flagged
- loadThemeFromCloud (func) — OffshoreBudgeting/Systems/AppTheme.swift:951
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:951
  Def: private func loadThemeFromCloud() {
  Dynamic-Risk Checklist: none flagged
- applyThemeFromUserDefaultsIfNeeded (func) — OffshoreBudgeting/Systems/AppTheme.swift:965
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:965
  Def: private func applyThemeFromUserDefaultsIfNeeded() {
  Dynamic-Risk Checklist: none flagged
- applyThemeIfNeeded (func) — OffshoreBudgeting/Systems/AppTheme.swift:971
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:971
  Def: private func applyThemeIfNeeded(from raw: String?) {
  Dynamic-Risk Checklist: none flagged
- startObservingUbiquitousStoreIfNeeded (func) — OffshoreBudgeting/Systems/AppTheme.swift:982
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:982
  Def: private func startObservingUbiquitousStoreIfNeeded() {
  Dynamic-Risk Checklist: none flagged
- handleUbiquitousStoreChange (func) — OffshoreBudgeting/Systems/AppTheme.swift:1005
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:1005
  Def: private func handleUbiquitousStoreChange(_ note: Notification) {
  Dynamic-Risk Checklist: none flagged
- instantiateUbiquitousStore (func) — OffshoreBudgeting/Systems/AppTheme.swift:1022
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:1022
  Def: private func instantiateUbiquitousStore() -> UbiquitousKeyValueStoring {
  Dynamic-Risk Checklist: none flagged
- ubiquitousStoreIfAvailable (func) — OffshoreBudgeting/Systems/AppTheme.swift:1032
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:1032
  Def: private func ubiquitousStoreIfAvailable() -> UbiquitousKeyValueStoring? {
  Dynamic-Risk Checklist: none flagged
- configureObserverIfNeeded (func) — OffshoreBudgeting/Systems/CardPickerStore.swift:56
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/CardPickerStore.swift:56
  Def: private func configureObserverIfNeeded() {
  Dynamic-Risk Checklist: none flagged
- makeFetchRequest (func) — OffshoreBudgeting/Systems/CardPickerStore.swift:70
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/CardPickerStore.swift:70
  Def: private func makeFetchRequest() -> NSFetchRequest<Card> {
  Dynamic-Risk Checklist: none flagged
- labelCGColor (func) — OffshoreBudgeting/Systems/CardTheme.swift:18
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/CardTheme.swift:18
  Def: private func labelCGColor(_ alpha: CGFloat) -> CGColor {
  Dynamic-Risk Checklist: none flagged
- rgbaComponents (func) — OffshoreBudgeting/Systems/CardTheme.swift:22
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/CardTheme.swift:22
  Def: private func rgbaComponents(from color: Color) -> (Double, Double, Double, Double)? {
  Dynamic-Risk Checklist: none flagged
- relativeLuminance (func) — OffshoreBudgeting/Systems/CardTheme.swift:32
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/CardTheme.swift:32
  Def: private func relativeLuminance(red: Double, green: Double, blue: Double) -> Double {
  Dynamic-Risk Checklist: none flagged
- mixComponent (func) — OffshoreBudgeting/Systems/CardTheme.swift:47
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/CardTheme.swift:47
  Def: private func mixComponent(_ value: Double, toward target: Double, amount: Double) -> Double {
  Dynamic-Risk Checklist: none flagged
- stripeColor (var) — OffshoreBudgeting/Systems/CardTheme.swift:122
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/CardTheme.swift:122
  Def: var stripeColor: Color {
  Dynamic-Risk Checklist: none flagged
- luminance (let) — OffshoreBudgeting/Systems/CardTheme.swift:137
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/CardTheme.swift:137
  Def: let luminance = relativeLuminance(red: components.0, green: components.1, blue: components.2)
  Dynamic-Risk Checklist: none flagged
- luminance (let) — OffshoreBudgeting/Systems/CardTheme.swift:151
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/CardTheme.swift:151
  Def: let luminance = relativeLuminance(red: components.0, green: components.1, blue: components.2)
  Dynamic-Risk Checklist: none flagged
- selectionAssistStrokeColor (var) — OffshoreBudgeting/Systems/CardTheme.swift:156
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/CardTheme.swift:156
  Def: var selectionAssistStrokeColor: Color {
  Dynamic-Risk Checklist: none flagged
- selectionAccentBlendMode (var) — OffshoreBudgeting/Systems/CardTheme.swift:165
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/CardTheme.swift:165
  Def: var selectionAccentBlendMode: BlendMode {
  Dynamic-Risk Checklist: none flagged
- selectionGlyphColor (var) — OffshoreBudgeting/Systems/CardTheme.swift:170
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/CardTheme.swift:170
  Def: var selectionGlyphColor: Color {
  Dynamic-Risk Checklist: none flagged
- flatColor (var) — OffshoreBudgeting/Systems/CardTheme.swift:175
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/CardTheme.swift:175
  Def: var flatColor: Color {
  Dynamic-Risk Checklist: none flagged
- BackgroundPattern (enum) — OffshoreBudgeting/Systems/CardTheme.swift:218
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/CardTheme.swift:218
  Def: private enum BackgroundPattern {
  Dynamic-Risk Checklist: none flagged
- backgroundPattern (var) — OffshoreBudgeting/Systems/CardTheme.swift:228
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/CardTheme.swift:228
  Def: var backgroundPattern: BackgroundPattern {
  Dynamic-Risk Checklist: none flagged
- adaptiveOverlay (func) — OffshoreBudgeting/Systems/CardTheme.swift:280
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/CardTheme.swift:280
  Def: func adaptiveOverlay(for colorScheme: ColorScheme, isHighContrast: Bool) -> Color {
  Dynamic-Risk Checklist: none flagged
- DiagonalStripesOverlay (struct) — OffshoreBudgeting/Systems/CardTheme.swift:295
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/CardTheme.swift:295
  Def: private struct DiagonalStripesOverlay: View {
  Dynamic-Risk Checklist: none flagged
- diag (let) — OffshoreBudgeting/Systems/CardTheme.swift:313
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/CardTheme.swift:313
  Def: let diag = hypot(size.width, size.height)
  Dynamic-Risk Checklist: none flagged
- CrossHatchOverlay (struct) — OffshoreBudgeting/Systems/CardTheme.swift:330
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/CardTheme.swift:330
  Def: private struct CrossHatchOverlay: View {
  Dynamic-Risk Checklist: none flagged
- GridOverlay (struct) — OffshoreBudgeting/Systems/CardTheme.swift:349
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/CardTheme.swift:349
  Def: private struct GridOverlay: View {
  Dynamic-Risk Checklist: none flagged
- DotsOverlay (struct) — OffshoreBudgeting/Systems/CardTheme.swift:388
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/CardTheme.swift:388
  Def: private struct DotsOverlay: View {
  Dynamic-Risk Checklist: none flagged
- cols (let) — OffshoreBudgeting/Systems/CardTheme.swift:404
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/CardTheme.swift:404
  Def: let cols = Int(ceil(size.width / spacing))
  Dynamic-Risk Checklist: none flagged
- dotRect (let) — OffshoreBudgeting/Systems/CardTheme.swift:410
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/CardTheme.swift:410
  Def: let dotRect = CGRect(x: x, y: y, width: diameter, height: diameter)
  Dynamic-Risk Checklist: none flagged
- NoiseOverlay (struct) — OffshoreBudgeting/Systems/CardTheme.swift:425
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/CardTheme.swift:425
  Def: private struct NoiseOverlay: View {
  Dynamic-Risk Checklist: none flagged
- shouldUseGlassSurfaces (func) — OffshoreBudgeting/Systems/Compatibility.swift:36
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:36
  Def: static func shouldUseGlassSurfaces(
  Dynamic-Risk Checklist: none flagged
- shouldUseSystemChrome (func) — OffshoreBudgeting/Systems/Compatibility.swift:49
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:49
  Def: static func shouldUseSystemChrome(capabilities: PlatformCapabilities) -> Bool {
  Dynamic-Risk Checklist: none flagged
- ub_rootNavigationChrome (func) — OffshoreBudgeting/Systems/Compatibility.swift:62
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:62
  Def: func ub_rootNavigationChrome() -> some View {
  Dynamic-Risk Checklist: none flagged
- ub_cardTitleShadow (func) — OffshoreBudgeting/Systems/Compatibility.swift:70
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:70
  Def: func ub_cardTitleShadow() -> some View {
  Dynamic-Risk Checklist: none flagged
- ub_surfaceBackground (func) — OffshoreBudgeting/Systems/Compatibility.swift:87
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:87
  Def: func ub_surfaceBackground(
  Dynamic-Risk Checklist: none flagged
- ub_disableHorizontalBounce (func) — OffshoreBudgeting/Systems/Compatibility.swift:127
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:127
  Def: func ub_disableHorizontalBounce() -> some View {
  Dynamic-Risk Checklist: none flagged
- ub_listStyleLiquidAware (func) — OffshoreBudgeting/Systems/Compatibility.swift:141
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:141
  Def: func ub_listStyleLiquidAware() -> some View {
  Dynamic-Risk Checklist: none flagged
- UBHorizontalBounceDisabler (struct) — OffshoreBudgeting/Systems/Compatibility.swift:172
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:172
  Def: private struct UBHorizontalBounceDisabler: UIViewRepresentable {
  Dynamic-Risk Checklist: none flagged
- makeUIView (func) — OffshoreBudgeting/Systems/Compatibility.swift:174
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:174
  Def: func makeUIView(context: Context) -> UBHorizontalBounceDisablingView {
  Dynamic-Risk Checklist: none flagged
- updateUIView (func) — OffshoreBudgeting/Systems/Compatibility.swift:179
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:179
  Def: func updateUIView(_ uiView: UBHorizontalBounceDisablingView, context: Context) {
  Dynamic-Risk Checklist: none flagged
- UBHorizontalBounceDisablingView (class) — OffshoreBudgeting/Systems/Compatibility.swift:186
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:186
  Def: private final class UBHorizontalBounceDisablingView: UIView {
  Dynamic-Risk Checklist: none flagged
- findEnclosingScrollView (func) — OffshoreBudgeting/Systems/Compatibility.swift:209
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:209
  Def: private func findEnclosingScrollView() -> UIScrollView? {
  Dynamic-Risk Checklist: none flagged
- UBListStyleLiquidAwareModifier (struct) — OffshoreBudgeting/Systems/Compatibility.swift:224
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:224
  Def: private struct UBListStyleLiquidAwareModifier: ViewModifier {
  Dynamic-Risk Checklist: none flagged
- ub_applyCompactSectionSpacingIfAvailable (func) — OffshoreBudgeting/Systems/Compatibility.swift:274
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:274
  Def: func ub_applyCompactSectionSpacingIfAvailable() -> some View {
  Dynamic-Risk Checklist: none flagged
- ub_applyZeroRowSpacingIfAvailable (func) — OffshoreBudgeting/Systems/Compatibility.swift:288
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:288
  Def: func ub_applyZeroRowSpacingIfAvailable() -> some View {
  Dynamic-Risk Checklist: none flagged
- UBListStyleSeparators (enum) — OffshoreBudgeting/Systems/Compatibility.swift:302
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:302
  Def: private enum UBListStyleSeparators {
  Dynamic-Risk Checklist: none flagged
- separatorColor (var) — OffshoreBudgeting/Systems/Compatibility.swift:304
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:304
  Def: static var separatorColor: Color {
  Dynamic-Risk Checklist: none flagged
- UBPreOS26ListRowBackgroundModifier (struct) — OffshoreBudgeting/Systems/Compatibility.swift:310
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:310
  Def: private struct UBPreOS26ListRowBackgroundModifier: ViewModifier {
  Dynamic-Risk Checklist: none flagged
- UBRootNavigationChromeModifier (struct) — OffshoreBudgeting/Systems/Compatibility.swift:325
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:325
  Def: private struct UBRootNavigationChromeModifier: ViewModifier {
  Dynamic-Risk Checklist: none flagged
- UBSurfaceBackgroundModifier (struct) — OffshoreBudgeting/Systems/Compatibility.swift:345
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:345
  Def: private struct UBSurfaceBackgroundModifier: ViewModifier {
  Dynamic-Risk Checklist: none flagged
- ignoresSafeAreaEdges (let) — OffshoreBudgeting/Systems/Compatibility.swift:350
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:350
  Def: let ignoresSafeAreaEdges: Edge.Set // Edges to extend through safe areas when painting.
  Dynamic-Risk Checklist: none flagged
- UBNavigationGlassModifier (struct) — OffshoreBudgeting/Systems/Compatibility.swift:366
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:366
  Def: private struct UBNavigationGlassModifier: ViewModifier {
  Dynamic-Risk Checklist: none flagged
- gradientStyle (var) — OffshoreBudgeting/Systems/Compatibility.swift:389
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:389
  Def: private var gradientStyle: AnyShapeStyle {
  Dynamic-Risk Checklist: none flagged
- highlight (let) — OffshoreBudgeting/Systems/Compatibility.swift:390
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:390
  Def: let highlight = Color.white.opacity(min(configuration.glass.highlightOpacity * 0.6, 0.28))
  Dynamic-Risk Checklist: none flagged
- UBNavigationBackgroundModifier (struct) — OffshoreBudgeting/Systems/Compatibility.swift:407
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:407
  Def: private struct UBNavigationBackgroundModifier: ViewModifier {
  Dynamic-Risk Checklist: none flagged
- UBWindowTitleUpdater (enum) — OffshoreBudgeting/Systems/Compatibility.swift:437
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:437
  Def: private enum UBWindowTitleUpdater {
  Dynamic-Risk Checklist: none flagged
- update (func) — OffshoreBudgeting/Systems/Compatibility.swift:438
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:438
  Def: static func update(_ title: String) {
  Dynamic-Risk Checklist: none flagged
- ub_ignoreSafeArea (func) — OffshoreBudgeting/Systems/Compatibility.swift:461
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:461
  Def: func ub_ignoreSafeArea(edges: Edge.Set) -> some View {
  Dynamic-Risk Checklist: none flagged
- UBCoreMotionProvider (class) — OffshoreBudgeting/Systems/Compatibility.swift:498
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:498
  Def: final class UBCoreMotionProvider: UBMotionsProviding {
  Dynamic-Risk Checklist: none flagged
- UBNoopMotionProvider (class) — OffshoreBudgeting/Systems/Compatibility.swift:530
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:530
  Def: final class UBNoopMotionProvider: UBMotionsProviding {
  Dynamic-Risk Checklist: none flagged
- UBPlatform (enum) — OffshoreBudgeting/Systems/Compatibility.swift:538
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:538
  Def: enum UBPlatform {
  Dynamic-Risk Checklist: none flagged
- makeMotionProvider (func) — OffshoreBudgeting/Systems/Compatibility.swift:539
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:539
  Def: static func makeMotionProvider() -> UBMotionsProviding {
  Dynamic-Risk Checklist: none flagged
- outputMilliseconds (func) — OffshoreBudgeting/Systems/DataChangeDebounce.swift:21
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/DataChangeDebounce.swift:21
  Def: static func outputMilliseconds() -> Int {
  Dynamic-Risk Checklist: none flagged
- cardBackgroundAmplitudeScale (let) — OffshoreBudgeting/Systems/DesignSystem+Motion.swift:16
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/DesignSystem+Motion.swift:16
  Def: static let cardBackgroundAmplitudeScale: Double = 0.22
  Dynamic-Risk Checklist: none flagged
- xl (let) — OffshoreBudgeting/Systems/DesignSystem.swift:32
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/DesignSystem.swift:32
  Def: static let xl: CGFloat = 24
  Dynamic-Risk Checklist: none flagged
- xxl (let) — OffshoreBudgeting/Systems/DesignSystem.swift:33
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/DesignSystem.swift:33
  Def: static let xxl: CGFloat = 32
  Dynamic-Risk Checklist: none flagged
- savingsGood (let) — OffshoreBudgeting/Systems/DesignSystem.swift:53
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/DesignSystem.swift:53
  Def: static let savingsGood    = Color.green
  Dynamic-Risk Checklist: none flagged
- savingsBad (let) — OffshoreBudgeting/Systems/DesignSystem.swift:55
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/DesignSystem.swift:55
  Def: static let savingsBad     = Color.red
  Dynamic-Risk Checklist: none flagged
- cardFill (let) — OffshoreBudgeting/Systems/DesignSystem.swift:59
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/DesignSystem.swift:59
  Def: static let cardFill       = Color.gray.opacity(0.08)
  Dynamic-Risk Checklist: none flagged
- chipSelectedFill (var) — OffshoreBudgeting/Systems/DesignSystem.swift:86
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/DesignSystem.swift:86
  Def: static var chipSelectedFill: Color {
  Dynamic-Risk Checklist: none flagged
- chipSelectedStroke (var) — OffshoreBudgeting/Systems/DesignSystem.swift:94
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/DesignSystem.swift:94
  Def: static var chipSelectedStroke: Color {
  Dynamic-Risk Checklist: none flagged
- dynamicChipNeutral (func) — OffshoreBudgeting/Systems/DesignSystem.swift:105
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/DesignSystem.swift:105
  Def: private static func dynamicChipNeutral(opacity: CGFloat) -> Color {
  Dynamic-Risk Checklist: none flagged
- ds_blend (func) — OffshoreBudgeting/Systems/DesignSystem.swift:141
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/DesignSystem.swift:141
  Def: static func ds_blend(_ base: UIColor, with other: UIColor, fraction: CGFloat) -> UIColor? {
  Dynamic-Risk Checklist: none flagged
- walkthroughContent (func) — OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:57
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:57
  Def: private static func walkthroughContent(for screen: TipsScreen) -> TipsContent? {
  Dynamic-Risk Checklist: none flagged
- whatsNewContent (func) — OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:199
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:199
  Def: private static func whatsNewContent(for screen: TipsScreen, versionToken: String?) -> TipsContent? {
  Dynamic-Risk Checklist: none flagged
- shouldShowTips (func) — OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:222
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:222
  Def: func shouldShowTips(for screen: TipsScreen, kind: TipsKind = .walkthrough, versionToken: String? = nil) -> Bool {
  Dynamic-Risk Checklist: none flagged
- markSeen (func) — OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:235
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:235
  Def: func markSeen(for screen: TipsScreen, kind: TipsKind = .walkthrough, versionToken: String? = nil) {
  Dynamic-Risk Checklist: none flagged
- seenKey (func) — OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:243
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:243
  Def: private func seenKey(for screen: TipsScreen, kind: TipsKind, versionToken: String?) -> String {
  Dynamic-Risk Checklist: none flagged
- legacyWhatsNewKey (func) — OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:254
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:254
  Def: private func legacyWhatsNewKey(for screen: TipsScreen, versionToken: String?) -> String? {
  Dynamic-Risk Checklist: none flagged
- ensureResetToken (func) — OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:260
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:260
  Def: private func ensureResetToken() -> String {
  Dynamic-Risk Checklist: none flagged
- migrateDefaultsToUbiquitousIfNeeded (func) — OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:295
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:295
  Def: private func migrateDefaultsToUbiquitousIfNeeded() {
  Dynamic-Risk Checklist: none flagged
- migrateWhatsNewVersionTokens (func) — OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:323
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:323
  Def: private func migrateWhatsNewVersionTokens() -> [String] {
  Dynamic-Risk Checklist: none flagged
- currentWhatsNewVersionToken (func) — OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:331
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:331
  Def: private func currentWhatsNewVersionToken() -> String? {
  Dynamic-Risk Checklist: none flagged
- TipsAndHintsOverlayModifier (struct) — OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:341
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:341
  Def: struct TipsAndHintsOverlayModifier: ViewModifier {
  Dynamic-Risk Checklist: none flagged
- isVisible (var) — OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:348
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:348
  Def: @State private var isVisible = false
  Dynamic-Risk Checklist: none flagged
- resetToken (var) — OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:349
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:349
  Def: @AppStorage(AppSettingsKeys.tipsHintsResetToken.rawValue) private var resetToken: String = ""
  Dynamic-Risk Checklist: none flagged
- markSeenOnDismiss (func) — OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:392
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:392
  Def: private func markSeenOnDismiss() {
  Dynamic-Risk Checklist: none flagged
- TipsPresentationCoordinator (class) — OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:399
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:399
  Def: final class TipsPresentationCoordinator: ObservableObject {
  Dynamic-Risk Checklist: none flagged
- tipsAndHintsOverlay (func) — OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:405
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:405
  Def: func tipsAndHintsOverlay(for screen: TipsScreen, kind: TipsKind = .walkthrough, versionToken: String? = nil) -> some View {
  Dynamic-Risk Checklist: none flagged
- TipsAndHintsSheet (struct) — OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:411
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:411
  Def: struct TipsAndHintsSheet: View {
  Dynamic-Risk Checklist: none flagged
- continueButton (var) — OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:441
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:441
  Def: private var continueButton: some View {
  Dynamic-Risk Checklist: none flagged
- closeButton (var) — OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:470
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:470
  Def: private var closeButton: some View {
  Dynamic-Risk Checklist: none flagged
- TipsItemRow (struct) — OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:475
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift:475
  Def: private struct TipsItemRow: View {
  Dynamic-Risk Checklist: none flagged
- UBMonthLabel (struct) — OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:13
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:13
  Def: struct UBMonthLabel: MonthLabel {
  Dynamic-Risk Checklist: none flagged
- monthLabelScale (var) — OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:19
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:19
  Def: @ScaledMetric(relativeTo: .headline) private var monthLabelScale: CGFloat = 1
  Dynamic-Risk Checklist: none flagged
- createContent (func) — OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:21
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:21
  Def: func createContent() -> AnyView {
  Dynamic-Risk Checklist: none flagged
- resolvedBaseFontSize (func) — OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:31
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:31
  Def: private func resolvedBaseFontSize(in context: ResponsiveLayoutContext) -> CGFloat {
  Dynamic-Risk Checklist: none flagged
- UBDayView (struct) — OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:41
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:41
  Def: struct UBDayView: DayView {
  Dynamic-Risk Checklist: none flagged
- selectedOverride (let) — OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:49
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:49
  Def: let selectedOverride: Date?
  Dynamic-Risk Checklist: none flagged
- daySpacingBase (var) — OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:54
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:54
  Def: @ScaledMetric(relativeTo: .caption) private var daySpacingBase: CGFloat = 2
  Dynamic-Risk Checklist: none flagged
- daySpacingMin (var) — OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:55
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:55
  Def: @ScaledMetric(relativeTo: .caption) private var daySpacingMin: CGFloat = 1
  Dynamic-Risk Checklist: none flagged
- incomeSpacingBase (var) — OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:56
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:56
  Def: @ScaledMetric(relativeTo: .caption) private var incomeSpacingBase: CGFloat = 1
  Dynamic-Risk Checklist: none flagged
- incomeSpacingMin (var) — OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:57
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:57
  Def: @ScaledMetric(relativeTo: .caption) private var incomeSpacingMin: CGFloat = 1
  Dynamic-Risk Checklist: none flagged
- incomeFontBase (var) — OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:58
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:58
  Def: @ScaledMetric(relativeTo: .caption) private var incomeFontBase: CGFloat = 8
  Dynamic-Risk Checklist: none flagged
- incomeFontMin (var) — OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:59
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:59
  Def: @ScaledMetric(relativeTo: .caption) private var incomeFontMin: CGFloat = 7
  Dynamic-Risk Checklist: none flagged
- incomeStackBase (var) — OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:60
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:60
  Def: @ScaledMetric(relativeTo: .caption) private var incomeStackBase: CGFloat = 20
  Dynamic-Risk Checklist: none flagged
- incomeStackMin (var) — OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:61
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:61
  Def: @ScaledMetric(relativeTo: .caption) private var incomeStackMin: CGFloat = 16
  Dynamic-Risk Checklist: none flagged
- dayLabelBase (var) — OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:62
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:62
  Def: @ScaledMetric(relativeTo: .subheadline) private var dayLabelBase: CGFloat = 16
  Dynamic-Risk Checklist: none flagged
- dayLabelMin (var) — OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:63
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:63
  Def: @ScaledMetric(relativeTo: .subheadline) private var dayLabelMin: CGFloat = 12
  Dynamic-Risk Checklist: none flagged
- selectionSizeBase (var) — OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:64
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:64
  Def: @ScaledMetric(relativeTo: .caption) private var selectionSizeBase: CGFloat = 32
  Dynamic-Risk Checklist: none flagged
- selectionSizeMin (var) — OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:65
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:65
  Def: @ScaledMetric(relativeTo: .caption) private var selectionSizeMin: CGFloat = 22
  Dynamic-Risk Checklist: none flagged
- createContent (func) — OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:68
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:68
  Def: func createContent() -> AnyView {
  Dynamic-Risk Checklist: none flagged
- createDayLabel (func) — OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:133
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:133
  Def: func createDayLabel() -> AnyView {
  Dynamic-Risk Checklist: none flagged
- createSelectionView (func) — OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:149
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:149
  Def: func createSelectionView() -> AnyView {
  Dynamic-Risk Checklist: none flagged
- createRangeSelectionView (func) — OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:161
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:161
  Def: func createRangeSelectionView() -> AnyView { AnyView(EmptyView()) }
  Dynamic-Risk Checklist: none flagged
- isSelectedDay (func) — OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:163
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:163
  Def: private func isSelectedDay() -> Bool {
  Dynamic-Risk Checklist: none flagged
- ymdString (func) — OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:178
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:178
  Def: private func ymdString(_ d: Date) -> String {
  Dynamic-Risk Checklist: none flagged
- cardTitleShadowColor (var) — OffshoreBudgeting/Systems/MetallicTextStyles.swift:13
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/MetallicTextStyles.swift:13
  Def: static var cardTitleShadowColor: Color {
  Dynamic-Risk Checklist: none flagged
- metallicSilverLinear (func) — OffshoreBudgeting/Systems/MetallicTextStyles.swift:26
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/MetallicTextStyles.swift:26
  Def: static func metallicSilverLinear(angle: Angle) -> AnyShapeStyle {
  Dynamic-Risk Checklist: none flagged
- holographicGradient (func) — OffshoreBudgeting/Systems/MetallicTextStyles.swift:46
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/MetallicTextStyles.swift:46
  Def: static func holographicGradient(angle: Angle) -> AnyShapeStyle {
  Dynamic-Risk Checklist: none flagged
- holographicShine (func) — OffshoreBudgeting/Systems/MetallicTextStyles.swift:69
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/MetallicTextStyles.swift:69
  Def: static func holographicShine(angle: Angle, intensity: Double) -> AnyShapeStyle {
  Dynamic-Risk Checklist: none flagged
- metallicShine (func) — OffshoreBudgeting/Systems/MetallicTextStyles.swift:88
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/MetallicTextStyles.swift:88
  Def: static func metallicShine(angle: Angle, intensity: Double) -> AnyShapeStyle {
  Dynamic-Risk Checklist: none flagged
- smoothingAlpha (var) — OffshoreBudgeting/Systems/MotionSupport.swift:44
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/MotionSupport.swift:44
  Def: private var smoothingAlpha: Double = DS.Motion.smoothingAlpha
  Dynamic-Risk Checklist: none flagged
- amplitudeScale (var) — OffshoreBudgeting/Systems/MotionSupport.swift:46
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/MotionSupport.swift:46
  Def: private var amplitudeScale: Double = DS.Motion.cardBackgroundAmplitudeScale
  Dynamic-Risk Checklist: none flagged
- lifecycleObservers (var) — OffshoreBudgeting/Systems/MotionSupport.swift:51
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/MotionSupport.swift:51
  Def: private var lifecycleObservers: [NSObjectProtocol] = []
  Dynamic-Risk Checklist: none flagged
- smooth (func) — OffshoreBudgeting/Systems/MotionSupport.swift:96
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/MotionSupport.swift:96
  Def: private func smooth(_ raw: Double, into current: inout Double, scale: Double = 1.0) {
  Dynamic-Risk Checklist: none flagged
- updateTuning (func) — OffshoreBudgeting/Systems/MotionSupport.swift:117
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/MotionSupport.swift:117
  Def: func updateTuning(smoothing: Double? = nil, scale: Double? = nil) {
  Dynamic-Risk Checklist: none flagged
- OnboardingPresentationKey (struct) — OffshoreBudgeting/Systems/OnboardingEnvironment.swift:7
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/OnboardingEnvironment.swift:7
  Def: struct OnboardingPresentationKey: EnvironmentKey {
  Dynamic-Risk Checklist: none flagged
- onboardingPresentation (func) — OffshoreBudgeting/Systems/OnboardingEnvironment.swift:26
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/OnboardingEnvironment.swift:26
  Def: func onboardingPresentation(_ isOnboarding: Bool = true) -> some View {
  Dynamic-Risk Checklist: none flagged
- forceLegacyByEnv (let) — OffshoreBudgeting/Systems/PlatformCapabilities.swift:38
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/PlatformCapabilities.swift:38
  Def: let forceLegacyByEnv = ProcessInfo.processInfo.environment["UB_FORCE_LEGACY_CHROME"] == "1" // CI/dev knob
  Dynamic-Risk Checklist: none flagged
- forceLegacyByDefaults (let) — OffshoreBudgeting/Systems/PlatformCapabilities.swift:39
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/PlatformCapabilities.swift:39
  Def: let forceLegacyByDefaults = UserDefaults.standard.bool(forKey: "UBForceLegacyChrome")
  Dynamic-Risk Checklist: none flagged
- resolveOS26TranslucencySupport (func) — OffshoreBudgeting/Systems/PlatformCapabilities.swift:59
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/PlatformCapabilities.swift:59
  Def: private static func resolveOS26TranslucencySupport() -> Bool {
  Dynamic-Risk Checklist: none flagged
- fallbackMacCatalyst26Support (func) — OffshoreBudgeting/Systems/PlatformCapabilities.swift:79
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/PlatformCapabilities.swift:79
  Def: private static func fallbackMacCatalyst26Support(
  Dynamic-Risk Checklist: none flagged
- runtimeVersionIndicatesOS26 (func) — OffshoreBudgeting/Systems/PlatformCapabilities.swift:98
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/PlatformCapabilities.swift:98
  Def: private static func runtimeVersionIndicatesOS26(_ version: String) -> Bool {
  Dynamic-Risk Checklist: none flagged
- PlatformCapabilitiesKey (struct) — OffshoreBudgeting/Systems/PlatformCapabilities.swift:114
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/PlatformCapabilities.swift:114
  Def: private struct PlatformCapabilitiesKey: EnvironmentKey {
  Dynamic-Risk Checklist: none flagged
- qaLogLiquidGlassDecision (func) — OffshoreBudgeting/Systems/PlatformCapabilities.swift:131
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/PlatformCapabilities.swift:131
  Def: func qaLogLiquidGlassDecision(component: String, path: String) {
  Dynamic-Risk Checklist: none flagged
- ResponsiveLayoutContextKey (struct) — OffshoreBudgeting/Systems/ResponsiveLayoutContext.swift:73
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/ResponsiveLayoutContext.swift:73
  Def: private struct ResponsiveLayoutContextKey: EnvironmentKey {
  Dynamic-Risk Checklist: none flagged
- hasNonZeroInsets (var) — OffshoreBudgeting/Systems/ResponsiveLayoutContext.swift:97
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/ResponsiveLayoutContext.swift:97
  Def: var hasNonZeroInsets: Bool {
  Dynamic-Risk Checklist: none flagged
- ResponsiveLayoutReader (struct) — OffshoreBudgeting/Systems/ResponsiveLayoutContext.swift:107
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/ResponsiveLayoutContext.swift:107
  Def: struct ResponsiveLayoutReader<Content: View>: View {
  Dynamic-Risk Checklist: none flagged
- legacySafeAreaInsets (var) — OffshoreBudgeting/Systems/ResponsiveLayoutContext.swift:111
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/ResponsiveLayoutContext.swift:111
  Def: @Environment(\.ub_safeAreaInsets) private var legacySafeAreaInsets
  Dynamic-Risk Checklist: none flagged
- makeContext (func) — OffshoreBudgeting/Systems/ResponsiveLayoutContext.swift:132
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/ResponsiveLayoutContext.swift:132
  Def: private func makeContext(using proxy: GeometryProxy) -> ResponsiveLayoutContext {
  Dynamic-Risk Checklist: none flagged
- resolvedSafeAreaInsets (func) — OffshoreBudgeting/Systems/ResponsiveLayoutContext.swift:146
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/ResponsiveLayoutContext.swift:146
  Def: private func resolvedSafeAreaInsets(from proxy: GeometryProxy) -> EdgeInsets {
  Dynamic-Risk Checklist: none flagged
- LegacySafeAreaCapture (struct) — OffshoreBudgeting/Systems/ResponsiveLayoutContext.swift:156
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/ResponsiveLayoutContext.swift:156
  Def: private struct LegacySafeAreaCapture: ViewModifier {
  Dynamic-Risk Checklist: none flagged
- startTabIdentifier (var) — OffshoreBudgeting/Systems/RootTabView.swift:51
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/RootTabView.swift:51
  Def: @Environment(\.startTabIdentifier) private var startTabIdentifier
  Dynamic-Risk Checklist: none flagged
- appliedStartTab (var) — OffshoreBudgeting/Systems/RootTabView.swift:53
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/RootTabView.swift:53
  Def: @State private var appliedStartTab: Bool = false
  Dynamic-Risk Checklist: none flagged
- usesCompactTabsOverride (var) — OffshoreBudgeting/Systems/RootTabView.swift:55
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/RootTabView.swift:55
  Def: @State private var usesCompactTabsOverride: Bool = false
  Dynamic-Risk Checklist: none flagged
- recentBudgets (var) — OffshoreBudgeting/Systems/RootTabView.swift:56
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/RootTabView.swift:56
  Def: @State private var recentBudgets: [Budget] = []
  Dynamic-Risk Checklist: none flagged
- sidebarPath (var) — OffshoreBudgeting/Systems/RootTabView.swift:57
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/RootTabView.swift:57
  Def: @State private var sidebarPath = NavigationPath()
  Dynamic-Risk Checklist: none flagged
- prefersCompactTabs (var) — OffshoreBudgeting/Systems/RootTabView.swift:66
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/RootTabView.swift:66
  Def: private var prefersCompactTabs: Bool {
  Dynamic-Risk Checklist: none flagged
- shouldUseCompactTabs (var) — OffshoreBudgeting/Systems/RootTabView.swift:74
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/RootTabView.swift:74
  Def: private var shouldUseCompactTabs: Bool {
  Dynamic-Risk Checklist: none flagged
- showsSidebarRestoreControl (var) — OffshoreBudgeting/Systems/RootTabView.swift:78
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/RootTabView.swift:78
  Def: private var showsSidebarRestoreControl: Bool {
  Dynamic-Risk Checklist: none flagged
- isNarrowLayout (var) — OffshoreBudgeting/Systems/RootTabView.swift:82
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/RootTabView.swift:82
  Def: private var isNarrowLayout: Bool {
  Dynamic-Risk Checklist: none flagged
- rootBody (var) — OffshoreBudgeting/Systems/RootTabView.swift:94
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/RootTabView.swift:94
  Def: private var rootBody: some View {
  Dynamic-Risk Checklist: none flagged
- tabViewBody (var) — OffshoreBudgeting/Systems/RootTabView.swift:105
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/RootTabView.swift:105
  Def: private var tabViewBody: some View {
  Dynamic-Risk Checklist: none flagged
- adaptiveTabView (var) — OffshoreBudgeting/Systems/RootTabView.swift:115
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/RootTabView.swift:115
  Def: private var adaptiveTabView: some View {
  Dynamic-Risk Checklist: none flagged
- baseTabView (var) — OffshoreBudgeting/Systems/RootTabView.swift:155
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/RootTabView.swift:155
  Def: private var baseTabView: some View {
  Dynamic-Risk Checklist: none flagged
- splitViewBody (var) — OffshoreBudgeting/Systems/RootTabView.swift:167
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/RootTabView.swift:167
  Def: private var splitViewBody: some View {
  Dynamic-Risk Checklist: none flagged
- legacyTabViewItem (func) — OffshoreBudgeting/Systems/RootTabView.swift:196
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/RootTabView.swift:196
  Def: private func legacyTabViewItem(for tab: Tab) -> some View {
  Dynamic-Risk Checklist: none flagged
- sidebarList (var) — OffshoreBudgeting/Systems/RootTabView.swift:208
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/RootTabView.swift:208
  Def: private var sidebarList: some View {
  Dynamic-Risk Checklist: none flagged
- plannedItem (let) — OffshoreBudgeting/Systems/RootTabView.swift:220
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/RootTabView.swift:220
  Def: let plannedItem = SidebarItem.addPlannedExpense
  Dynamic-Risk Checklist: none flagged
- variableItem (let) — OffshoreBudgeting/Systems/RootTabView.swift:224
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/RootTabView.swift:224
  Def: let variableItem = SidebarItem.addVariableExpense
  Dynamic-Risk Checklist: none flagged
- presetsItem (let) — OffshoreBudgeting/Systems/RootTabView.swift:231
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/RootTabView.swift:231
  Def: let presetsItem = SidebarItem.managePresets
  Dynamic-Risk Checklist: none flagged
- categoriesItem (let) — OffshoreBudgeting/Systems/RootTabView.swift:235
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/RootTabView.swift:235
  Def: let categoriesItem = SidebarItem.manageCategories
  Dynamic-Risk Checklist: none flagged
- sidebarDetail (var) — OffshoreBudgeting/Systems/RootTabView.swift:261
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/RootTabView.swift:261
  Def: private var sidebarDetail: some View {
  Dynamic-Risk Checklist: none flagged
- decoratedTabContent (func) — OffshoreBudgeting/Systems/RootTabView.swift:295
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/RootTabView.swift:295
  Def: private func decoratedTabContent(for tab: Tab) -> some View {
  Dynamic-Risk Checklist: none flagged
- decoratedRootContent (func) — OffshoreBudgeting/Systems/RootTabView.swift:300
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/RootTabView.swift:300
  Def: private func decoratedRootContent<Content: View>(_ content: Content) -> some View {
  Dynamic-Risk Checklist: none flagged
- tabContent (func) — OffshoreBudgeting/Systems/RootTabView.swift:333
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/RootTabView.swift:333
  Def: private func tabContent(for tab: Tab) -> some View {
  Dynamic-Risk Checklist: none flagged
- readyTabContent (func) — OffshoreBudgeting/Systems/RootTabView.swift:342
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/RootTabView.swift:342
  Def: private func readyTabContent(for tab: Tab) -> some View {
  Dynamic-Risk Checklist: none flagged
- loadingPlaceholder (func) — OffshoreBudgeting/Systems/RootTabView.swift:375
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/RootTabView.swift:375
  Def: private func loadingPlaceholder() -> some View {
  Dynamic-Risk Checklist: none flagged
- refreshRecentBudgets (func) — OffshoreBudgeting/Systems/RootTabView.swift:381
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/RootTabView.swift:381
  Def: private func refreshRecentBudgets() {
  Dynamic-Risk Checklist: none flagged
- sidebarRowBackground (func) — OffshoreBudgeting/Systems/RootTabView.swift:394
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/RootTabView.swift:394
  Def: private func sidebarRowBackground(isSelected: Bool) -> some View {
  Dynamic-Risk Checklist: none flagged
- selectedSidebarTint (var) — OffshoreBudgeting/Systems/RootTabView.swift:429
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/RootTabView.swift:429
  Def: private var selectedSidebarTint: Color {
  Dynamic-Risk Checklist: none flagged
- mapStartTab (func) — OffshoreBudgeting/Systems/RootTabView.swift:480
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/RootTabView.swift:480
  Def: func mapStartTab(key: String) -> Tab? {
  Dynamic-Risk Checklist: none flagged
- UBSafeAreaInsetsEnvironmentKey (struct) — OffshoreBudgeting/Systems/SafeAreaInsetsCompatibility.swift:14
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/SafeAreaInsetsCompatibility.swift:14
  Def: private struct UBSafeAreaInsetsEnvironmentKey: EnvironmentKey {
  Dynamic-Risk Checklist: none flagged
- UBSafeAreaInsetsReader (struct) — OffshoreBudgeting/Systems/SafeAreaInsetsCompatibility.swift:44
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/SafeAreaInsetsCompatibility.swift:44
  Def: private struct UBSafeAreaInsetsReader: ViewModifier {
  Dynamic-Risk Checklist: none flagged
- ub_captureSafeAreaInsets (func) — OffshoreBudgeting/Systems/SafeAreaInsetsCompatibility.swift:69
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/SafeAreaInsetsCompatibility.swift:69
  Def: func ub_captureSafeAreaInsets() -> some View {
  Dynamic-Risk Checklist: none flagged
- Flavor (enum) — OffshoreBudgeting/Systems/SystemTheme.swift:15
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/SystemTheme.swift:15
  Def: enum Flavor { case liquid, classic }
  Dynamic-Risk Checklist: none flagged
- currentFlavor (var) — OffshoreBudgeting/Systems/SystemTheme.swift:18
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/SystemTheme.swift:18
  Def: static var currentFlavor: Flavor { flavor() }
  Dynamic-Risk Checklist: none flagged
- flavor (func) — OffshoreBudgeting/Systems/SystemTheme.swift:23
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/SystemTheme.swift:23
  Def: static func flavor(for capabilities: PlatformCapabilities = .current) -> Flavor {
  Dynamic-Risk Checklist: none flagged
- resolvedForegroundColor (func) — OffshoreBudgeting/Systems/SystemTheme.swift:80
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/SystemTheme.swift:80
  Def: private static func resolvedForegroundColor(
  Dynamic-Risk Checklist: none flagged
- UITestingFlagsKey (struct) — OffshoreBudgeting/Systems/UITestingEnvironment.swift:9
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/UITestingEnvironment.swift:9
  Def: private struct UITestingFlagsKey: EnvironmentKey {
  Dynamic-Risk Checklist: none flagged
- StartTabIdentifierKey (struct) — OffshoreBudgeting/Systems/UITestingEnvironment.swift:21
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/UITestingEnvironment.swift:21
  Def: private struct StartTabIdentifierKey: EnvironmentKey {
  Dynamic-Risk Checklist: none flagged
- incomeWidgetKind (let) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:11
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:11
  Def: static let incomeWidgetKind = "com.mb.offshore.income.widget"
  Dynamic-Risk Checklist: none flagged
- expenseToIncomeKeyPrefix (let) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:12
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:12
  Def: private static let expenseToIncomeKeyPrefix = "widget.expenseToIncome.snapshot."
  Dynamic-Risk Checklist: none flagged
- expenseToIncomeDefaultPeriodKey (let) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:13
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:13
  Def: private static let expenseToIncomeDefaultPeriodKey = "widget.expenseToIncome.defaultPeriod"
  Dynamic-Risk Checklist: none flagged
- expenseToIncomeWidgetKind (let) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:14
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:14
  Def: static let expenseToIncomeWidgetKind = "com.mb.offshore.expenseToIncome.widget"
  Dynamic-Risk Checklist: none flagged
- savingsOutlookKeyPrefix (let) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:15
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:15
  Def: private static let savingsOutlookKeyPrefix = "widget.savingsOutlook.snapshot."
  Dynamic-Risk Checklist: none flagged
- savingsOutlookDefaultPeriodKey (let) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:16
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:16
  Def: private static let savingsOutlookDefaultPeriodKey = "widget.savingsOutlook.defaultPeriod"
  Dynamic-Risk Checklist: none flagged
- savingsOutlookWidgetKind (let) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:17
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:17
  Def: static let savingsOutlookWidgetKind = "com.mb.offshore.savingsOutlook.widget"
  Dynamic-Risk Checklist: none flagged
- categorySpotlightWidgetKind (let) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:20
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:20
  Def: static let categorySpotlightWidgetKind = "com.mb.offshore.categorySpotlight.widget"
  Dynamic-Risk Checklist: none flagged
- dayOfWeekWidgetKind (let) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:23
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:23
  Def: static let dayOfWeekWidgetKind = "com.mb.offshore.dayOfWeek.widget"
  Dynamic-Risk Checklist: none flagged
- categoryAvailabilityKeyPrefix (let) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:24
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:24
  Def: private static let categoryAvailabilityKeyPrefix = "widget.categoryAvailability.snapshot."
  Dynamic-Risk Checklist: none flagged
- categoryAvailabilityDefaultPeriodKey (let) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:25
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:25
  Def: private static let categoryAvailabilityDefaultPeriodKey = "widget.categoryAvailability.defaultPeriod"
  Dynamic-Risk Checklist: none flagged
- categoryAvailabilityDefaultSegmentKey (let) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:26
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:26
  Def: private static let categoryAvailabilityDefaultSegmentKey = "widget.categoryAvailability.defaultSegment"
  Dynamic-Risk Checklist: none flagged
- categoryAvailabilityDefaultSortKey (let) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:27
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:27
  Def: private static let categoryAvailabilityDefaultSortKey = "widget.categoryAvailability.defaultSort"
  Dynamic-Risk Checklist: none flagged
- categoryAvailabilityCategoriesKey (let) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:28
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:28
  Def: private static let categoryAvailabilityCategoriesKey = "widget.categoryAvailability.categories"
  Dynamic-Risk Checklist: none flagged
- categoryAvailabilityWidgetKind (let) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:29
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:29
  Def: static let categoryAvailabilityWidgetKind = "com.mb.offshore.categoryAvailability.widget"
  Dynamic-Risk Checklist: none flagged
- cardWidgetKeyPrefix (let) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:30
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:30
  Def: private static let cardWidgetKeyPrefix = "widget.card.snapshot."
  Dynamic-Risk Checklist: none flagged
- cardWidgetDefaultPeriodKey (let) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:31
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:31
  Def: private static let cardWidgetDefaultPeriodKey = "widget.card.defaultPeriod"
  Dynamic-Risk Checklist: none flagged
- cardWidgetCardsKey (let) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:32
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:32
  Def: private static let cardWidgetCardsKey = "widget.card.cards"
  Dynamic-Risk Checklist: none flagged
- themeName (let) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:113
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:113
  Def: let themeName: String?
  Dynamic-Risk Checklist: none flagged
- patternName (let) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:116
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:116
  Def: let patternName: String?
  Dynamic-Risk Checklist: none flagged
- writeIncomeSnapshot (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:140
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:140
  Def: static func writeIncomeSnapshot(_ snapshot: IncomeSnapshot, periodRaw: String) {
  Dynamic-Risk Checklist: none flagged
- writeIncomeDefaultPeriod (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:151
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:151
  Def: static func writeIncomeDefaultPeriod(_ periodRaw: String) {
  Dynamic-Risk Checklist: none flagged
- readIncomeSnapshot (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:156
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:156
  Def: static func readIncomeSnapshot(periodRaw: String) -> IncomeSnapshot? {
  Dynamic-Risk Checklist: none flagged
- readIncomeDefaultPeriod (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:164
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:164
  Def: static func readIncomeDefaultPeriod() -> String? {
  Dynamic-Risk Checklist: none flagged
- writeExpenseToIncomeSnapshot (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:169
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:169
  Def: static func writeExpenseToIncomeSnapshot(_ snapshot: ExpenseToIncomeSnapshot, periodRaw: String) {
  Dynamic-Risk Checklist: none flagged
- writeExpenseToIncomeDefaultPeriod (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:180
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:180
  Def: static func writeExpenseToIncomeDefaultPeriod(_ periodRaw: String) {
  Dynamic-Risk Checklist: none flagged
- readExpenseToIncomeSnapshot (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:185
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:185
  Def: static func readExpenseToIncomeSnapshot(periodRaw: String) -> ExpenseToIncomeSnapshot? {
  Dynamic-Risk Checklist: none flagged
- readExpenseToIncomeDefaultPeriod (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:193
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:193
  Def: static func readExpenseToIncomeDefaultPeriod() -> String? {
  Dynamic-Risk Checklist: none flagged
- writeSavingsOutlookSnapshot (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:198
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:198
  Def: static func writeSavingsOutlookSnapshot(_ snapshot: SavingsOutlookSnapshot, periodRaw: String) {
  Dynamic-Risk Checklist: none flagged
- writeSavingsOutlookDefaultPeriod (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:209
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:209
  Def: static func writeSavingsOutlookDefaultPeriod(_ periodRaw: String) {
  Dynamic-Risk Checklist: none flagged
- readSavingsOutlookSnapshot (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:214
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:214
  Def: static func readSavingsOutlookSnapshot(periodRaw: String) -> SavingsOutlookSnapshot? {
  Dynamic-Risk Checklist: none flagged
- readSavingsOutlookDefaultPeriod (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:222
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:222
  Def: static func readSavingsOutlookDefaultPeriod() -> String? {
  Dynamic-Risk Checklist: none flagged
- writeCategorySpotlightSnapshot (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:227
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:227
  Def: static func writeCategorySpotlightSnapshot(_ snapshot: CategorySpotlightSnapshot, periodRaw: String) {
  Dynamic-Risk Checklist: none flagged
- writeCategorySpotlightDefaultPeriod (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:238
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:238
  Def: static func writeCategorySpotlightDefaultPeriod(_ periodRaw: String) {
  Dynamic-Risk Checklist: none flagged
- readCategorySpotlightSnapshot (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:243
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:243
  Def: static func readCategorySpotlightSnapshot(periodRaw: String) -> CategorySpotlightSnapshot? {
  Dynamic-Risk Checklist: none flagged
- readCategorySpotlightDefaultPeriod (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:251
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:251
  Def: static func readCategorySpotlightDefaultPeriod() -> String? {
  Dynamic-Risk Checklist: none flagged
- writeDayOfWeekSnapshot (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:256
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:256
  Def: static func writeDayOfWeekSnapshot(_ snapshot: DayOfWeekSnapshot, periodRaw: String) {
  Dynamic-Risk Checklist: none flagged
- writeDayOfWeekDefaultPeriod (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:267
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:267
  Def: static func writeDayOfWeekDefaultPeriod(_ periodRaw: String) {
  Dynamic-Risk Checklist: none flagged
- readDayOfWeekSnapshot (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:272
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:272
  Def: static func readDayOfWeekSnapshot(periodRaw: String) -> DayOfWeekSnapshot? {
  Dynamic-Risk Checklist: none flagged
- readDayOfWeekDefaultPeriod (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:280
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:280
  Def: static func readDayOfWeekDefaultPeriod() -> String? {
  Dynamic-Risk Checklist: none flagged
- writeCategoryAvailabilitySnapshot (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:285
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:285
  Def: static func writeCategoryAvailabilitySnapshot(_ snapshot: CategoryAvailabilitySnapshot, periodRaw: String, segmentRaw: String) {
  Dynamic-Risk Checklist: none flagged
- readCategoryAvailabilitySnapshot (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:296
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:296
  Def: static func readCategoryAvailabilitySnapshot(periodRaw: String, segmentRaw: String) -> CategoryAvailabilitySnapshot? {
  Dynamic-Risk Checklist: none flagged
- writeCardWidgetSnapshot (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:304
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:304
  Def: static func writeCardWidgetSnapshot(_ snapshot: CardWidgetSnapshot, periodRaw: String, cardID: String) {
  Dynamic-Risk Checklist: none flagged
- writeCardWidgetDefaultPeriod (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:315
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:315
  Def: static func writeCardWidgetDefaultPeriod(_ periodRaw: String) {
  Dynamic-Risk Checklist: none flagged
- readCardWidgetSnapshot (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:320
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:320
  Def: static func readCardWidgetSnapshot(periodRaw: String, cardID: String) -> CardWidgetSnapshot? {
  Dynamic-Risk Checklist: none flagged
- readCardWidgetDefaultPeriod (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:328
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:328
  Def: static func readCardWidgetDefaultPeriod() -> String? {
  Dynamic-Risk Checklist: none flagged
- writeCardWidgetCards (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:333
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:333
  Def: static func writeCardWidgetCards(_ cards: [CardWidgetCard]) {
  Dynamic-Risk Checklist: none flagged
- readCardWidgetCards (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:343
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:343
  Def: static func readCardWidgetCards() -> [CardWidgetCard] {
  Dynamic-Risk Checklist: none flagged
- writeCategoryAvailabilityDefaultPeriod (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:350
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:350
  Def: static func writeCategoryAvailabilityDefaultPeriod(_ periodRaw: String) {
  Dynamic-Risk Checklist: none flagged
- readCategoryAvailabilityDefaultPeriod (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:355
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:355
  Def: static func readCategoryAvailabilityDefaultPeriod() -> String? {
  Dynamic-Risk Checklist: none flagged
- writeCategoryAvailabilityDefaultSegment (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:360
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:360
  Def: static func writeCategoryAvailabilityDefaultSegment(_ segmentRaw: String) {
  Dynamic-Risk Checklist: none flagged
- readCategoryAvailabilityDefaultSegment (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:365
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:365
  Def: static func readCategoryAvailabilityDefaultSegment() -> String? {
  Dynamic-Risk Checklist: none flagged
- writeCategoryAvailabilityDefaultSort (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:370
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:370
  Def: static func writeCategoryAvailabilityDefaultSort(_ sortRaw: String) {
  Dynamic-Risk Checklist: none flagged
- readCategoryAvailabilityDefaultSort (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:375
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:375
  Def: static func readCategoryAvailabilityDefaultSort() -> String? {
  Dynamic-Risk Checklist: none flagged
- writeCategoryAvailabilityCategories (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:380
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:380
  Def: static func writeCategoryAvailabilityCategories(_ categories: [String]) {
  Dynamic-Risk Checklist: none flagged
- readCategoryAvailabilityCategories (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:385
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:385
  Def: static func readCategoryAvailabilityCategories() -> [String] {
  Dynamic-Risk Checklist: none flagged
- nextPlannedKey (let) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:390
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:390
  Def: private static let nextPlannedKey = "widget.nextPlannedExpense.snapshot"
  Dynamic-Risk Checklist: none flagged
- nextPlannedWidgetKind (let) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:391
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:391
  Def: static let nextPlannedWidgetKind = "com.mb.offshore.nextPlannedExpense.widget"
  Dynamic-Risk Checklist: none flagged
- writeNextPlannedExpenseSnapshot (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:393
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:393
  Def: static func writeNextPlannedExpenseSnapshot(_ snapshot: NextPlannedExpenseSnapshot) {
  Dynamic-Risk Checklist: none flagged
- readNextPlannedExpenseSnapshot (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:404
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:404
  Def: static func readNextPlannedExpenseSnapshot() -> NextPlannedExpenseSnapshot? {
  Dynamic-Risk Checklist: none flagged
- clearNextPlannedExpenseSnapshot (func) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:412
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:412
  Def: static func clearNextPlannedExpenseSnapshot() {
  Dynamic-Risk Checklist: none flagged
- AddBudgetViewModel (class) — OffshoreBudgeting/View Models/AddBudgetViewModel.swift:16
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddBudgetViewModel.swift:16
  Def: final class AddBudgetViewModel: ObservableObject {
  Dynamic-Risk Checklist: none flagged
- makeDefaultName (func) — OffshoreBudgeting/View Models/AddBudgetViewModel.swift:89
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddBudgetViewModel.swift:89
  Def: private static func makeDefaultName(startDate: Date, endDate: Date) -> String {
  Dynamic-Risk Checklist: none flagged
- createNewBudget (func) — OffshoreBudgeting/View Models/AddBudgetViewModel.swift:148
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddBudgetViewModel.swift:148
  Def: private func createNewBudget() throws {
  Dynamic-Risk Checklist: none flagged
- updateExistingBudget (func) — OffshoreBudgeting/View Models/AddBudgetViewModel.swift:174
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddBudgetViewModel.swift:174
  Def: private func updateExistingBudget(with objectID: NSManagedObjectID) throws {
  Dynamic-Risk Checklist: none flagged
- fetchGlobalPlannedExpenseTemplates (func) — OffshoreBudgeting/View Models/AddBudgetViewModel.swift:228
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddBudgetViewModel.swift:228
  Def: private func fetchGlobalPlannedExpenseTemplates() -> [PlannedExpense] {
  Dynamic-Risk Checklist: none flagged
- fetchPlannedExpenses (func) — OffshoreBudgeting/View Models/AddBudgetViewModel.swift:240
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddBudgetViewModel.swift:240
  Def: private func fetchPlannedExpenses(for budget: Budget) -> [PlannedExpense] {
  Dynamic-Risk Checklist: none flagged
- AddIncomeFormViewModel (class) — OffshoreBudgeting/View Models/AddIncomeFormViewModel.swift:19
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddIncomeFormViewModel.swift:19
  Def: final class AddIncomeFormViewModel: ObservableObject {
  Dynamic-Risk Checklist: none flagged
- originalOccurrenceDate (var) — OffshoreBudgeting/View Models/AddIncomeFormViewModel.swift:28
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddIncomeFormViewModel.swift:28
  Def: private var originalOccurrenceDate: Date?
  Dynamic-Risk Checklist: none flagged
- originalSeriesStartDate (var) — OffshoreBudgeting/View Models/AddIncomeFormViewModel.swift:30
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddIncomeFormViewModel.swift:30
  Def: private var originalSeriesStartDate: Date?
  Dynamic-Risk Checklist: none flagged
- isPartOfSeries (var) — OffshoreBudgeting/View Models/AddIncomeFormViewModel.swift:50
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddIncomeFormViewModel.swift:50
  Def: var isPartOfSeries: Bool {
  Dynamic-Risk Checklist: none flagged
- trimmedSource (let) — OffshoreBudgeting/View Models/AddIncomeFormViewModel.swift:71
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddIncomeFormViewModel.swift:71
  Def: let trimmedSource = source.trimmingCharacters(in: .whitespacesAndNewlines)
  Dynamic-Risk Checklist: none flagged
- loadIfNeeded (func) — OffshoreBudgeting/View Models/AddIncomeFormViewModel.swift:84
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddIncomeFormViewModel.swift:84
  Def: func loadIfNeeded(from context: NSManagedObjectContext) throws {
  Dynamic-Risk Checklist: none flagged
- formatAmountForEditing (func) — OffshoreBudgeting/View Models/AddIncomeFormViewModel.swift:189
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddIncomeFormViewModel.swift:189
  Def: private func formatAmountForEditing(_ value: Double) -> String {
  Dynamic-Risk Checklist: none flagged
- parseAmount (func) — OffshoreBudgeting/View Models/AddIncomeFormViewModel.swift:199
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddIncomeFormViewModel.swift:199
  Def: private func parseAmount(from string: String) -> Double? {
  Dynamic-Risk Checklist: none flagged
- ValidationError (enum) — OffshoreBudgeting/View Models/AddIncomeFormViewModel.swift:230
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddIncomeFormViewModel.swift:230
  Def: enum ValidationError: LocalizedError {
  Dynamic-Risk Checklist: none flagged
- optionalInt16IfAttributeExists (func) — OffshoreBudgeting/View Models/AddIncomeFormViewModel.swift:240
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddIncomeFormViewModel.swift:240
  Def: private static func optionalInt16IfAttributeExists(on object: NSManagedObject,
  Dynamic-Risk Checklist: none flagged
- AddPlannedExpenseViewModel (class) — OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:16
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:16
  Def: final class AddPlannedExpenseViewModel: ObservableObject {
  Dynamic-Risk Checklist: none flagged
- editingOriginalTemplateLinkID (var) — OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:58
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:58
  Def: private var editingOriginalTemplateLinkID: UUID?
  Dynamic-Risk Checklist: none flagged
- attachCardPickerStoreIfNeeded (func) — OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:81
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:81
  Def: func attachCardPickerStoreIfNeeded(_ store: CardPickerStore) {
  Dynamic-Risk Checklist: none flagged
- amountValid (let) — OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:171
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:171
  Def: let amountValid = Double(plannedAmountString.replacingOccurrences(of: ",", with: "")) != nil
  Dynamic-Risk Checklist: none flagged
- textValid (let) — OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:172
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:172
  Def: let textValid = !descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  Dynamic-Risk Checklist: none flagged
- hasBudgetSelection (let) — OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:175
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:175
  Def: let hasBudgetSelection = !selectedBudgetIDs.isEmpty
  Dynamic-Risk Checklist: none flagged
- isEditingGlobalTemplate (var) — OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:190
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:190
  Def: var isEditingGlobalTemplate: Bool { editingOriginalIsGlobal }
  Dynamic-Risk Checklist: none flagged
- isEditingLinkedToTemplate (var) — OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:191
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:191
  Def: var isEditingLinkedToTemplate: Bool { editingOriginalTemplateLinkID != nil }
  Dynamic-Risk Checklist: none flagged
- shouldPromptForScopeSelection (var) — OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:192
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:192
  Def: var shouldPromptForScopeSelection: Bool { isEditing && (isEditingGlobalTemplate || isEditingLinkedToTemplate) }
  Dynamic-Risk Checklist: none flagged
- toggleBudgetSelection (func) — OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:396
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:396
  Def: func toggleBudgetSelection(for id: NSManagedObjectID) {
  Dynamic-Risk Checklist: none flagged
- shouldForceSingleBudgetSelection (var) — OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:415
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:415
  Def: private var shouldForceSingleBudgetSelection: Bool {
  Dynamic-Risk Checklist: none flagged
- isBudgetSelected (func) — OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:422
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:422
  Def: func isBudgetSelected(_ id: NSManagedObjectID) -> Bool {
  Dynamic-Risk Checklist: none flagged
- selectedBudgetNames (var) — OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:426
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:426
  Def: var selectedBudgetNames: [String] {
  Dynamic-Risk Checklist: none flagged
- gatherBudgetSelections (func) — OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:457
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:457
  Def: private func gatherBudgetSelections(for expense: PlannedExpense) -> Set<NSManagedObjectID> {
  Dynamic-Risk Checklist: none flagged
- resolveTemplate (func) — OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:502
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:502
  Def: private func resolveTemplate(for expense: PlannedExpense) -> PlannedExpense? {
  Dynamic-Risk Checklist: none flagged
- matchesDuplicate (func) — OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:519
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:519
  Def: private func matchesDuplicate(_ candidate: PlannedExpense, of reference: PlannedExpense) -> Bool {
  Dynamic-Risk Checklist: none flagged
- normalizedTitle (func) — OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:538
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:538
  Def: private func normalizedTitle(for expense: PlannedExpense) -> String {
  Dynamic-Risk Checklist: none flagged
- bindToCardPickerStore (func) — OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:568
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:568
  Def: private func bindToCardPickerStore(_ store: CardPickerStore, preserveSelection: Bool) {
  Dynamic-Risk Checklist: none flagged
- updateCardsFromStore (func) — OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:588
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:588
  Def: private func updateCardsFromStore(_ cards: [Card], preserveSelection: Bool) {
  Dynamic-Risk Checklist: none flagged
- formatAmount (func) — OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:609
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:609
  Def: private func formatAmount(_ value: Double) -> String {
  Dynamic-Risk Checklist: none flagged
- AddUnplannedExpenseViewModel (class) — OffshoreBudgeting/View Models/AddUnplannedExpenseViewModel.swift:15
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddUnplannedExpenseViewModel.swift:15
  Def: final class AddUnplannedExpenseViewModel: ObservableObject {
  Dynamic-Risk Checklist: none flagged
- attachCardPickerStoreIfNeeded (func) — OffshoreBudgeting/View Models/AddUnplannedExpenseViewModel.swift:70
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddUnplannedExpenseViewModel.swift:70
  Def: func attachCardPickerStoreIfNeeded(_ store: CardPickerStore) {
  Dynamic-Risk Checklist: none flagged
- reloadLists (func) — OffshoreBudgeting/View Models/AddUnplannedExpenseViewModel.swift:216
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddUnplannedExpenseViewModel.swift:216
  Def: private func reloadLists(preserveSelection: Bool = false) {
  Dynamic-Risk Checklist: none flagged
- bindToCardPickerStore (func) — OffshoreBudgeting/View Models/AddUnplannedExpenseViewModel.swift:240
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddUnplannedExpenseViewModel.swift:240
  Def: private func bindToCardPickerStore(_ store: CardPickerStore, preserveSelection: Bool) {
  Dynamic-Risk Checklist: none flagged
- updateCardsFromStore (func) — OffshoreBudgeting/View Models/AddUnplannedExpenseViewModel.swift:260
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddUnplannedExpenseViewModel.swift:260
  Def: private func updateCardsFromStore(_ cards: [Card], preserveSelection: Bool) {
  Dynamic-Risk Checklist: none flagged
- filteredCards (func) — OffshoreBudgeting/View Models/AddUnplannedExpenseViewModel.swift:272
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddUnplannedExpenseViewModel.swift:272
  Def: private func filteredCards(from cards: [Card]) -> [Card] {
  Dynamic-Risk Checklist: none flagged
- formatAmount (func) — OffshoreBudgeting/View Models/AddUnplannedExpenseViewModel.swift:277
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AddUnplannedExpenseViewModel.swift:277
  Def: private func formatAmount(_ value: Double) -> String {
  Dynamic-Risk Checklist: none flagged
- AppLockViewModel (class) — OffshoreBudgeting/View Models/AppLockViewModel.swift:29
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AppLockViewModel.swift:29
  Def: public final class AppLockViewModel: ObservableObject {
  Dynamic-Risk Checklist: none flagged
- lastPromptAt (var) — OffshoreBudgeting/View Models/AppLockViewModel.swift:45
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AppLockViewModel.swift:45
  Def: private var lastPromptAt: Date? = nil
  Dynamic-Risk Checklist: none flagged
- promptThrottleSeconds (let) — OffshoreBudgeting/View Models/AppLockViewModel.swift:46
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AppLockViewModel.swift:46
  Def: private let promptThrottleSeconds: TimeInterval = 1.0
  Dynamic-Risk Checklist: none flagged
- unlockGraceUntil (var) — OffshoreBudgeting/View Models/AppLockViewModel.swift:47
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AppLockViewModel.swift:47
  Def: private var unlockGraceUntil: Date? = nil
  Dynamic-Risk Checklist: none flagged
- unlockGraceSeconds (let) — OffshoreBudgeting/View Models/AppLockViewModel.swift:48
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AppLockViewModel.swift:48
  Def: private let unlockGraceSeconds: TimeInterval = 0.8
  Dynamic-Risk Checklist: none flagged
- attemptUnlockWithBiometrics (func) — OffshoreBudgeting/View Models/AppLockViewModel.swift:72
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AppLockViewModel.swift:72
  Def: public func attemptUnlockWithBiometrics(reason: String = "Unlock Offshore Budgeting") {
  Dynamic-Risk Checklist: none flagged
- lockSubtitle (var) — OffshoreBudgeting/View Models/AppLockViewModel.swift:118
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AppLockViewModel.swift:118
  Def: public var lockSubtitle: String {
  Dynamic-Risk Checklist: none flagged
- lockIconName (var) — OffshoreBudgeting/View Models/AppLockViewModel.swift:122
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AppLockViewModel.swift:122
  Def: public var lockIconName: String {
  Dynamic-Risk Checklist: none flagged
- biometricLabel (var) — OffshoreBudgeting/View Models/AppLockViewModel.swift:146
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AppLockViewModel.swift:146
  Def: private var biometricLabel: String {
  Dynamic-Risk Checklist: none flagged
- canUseBiometricsNow (var) — OffshoreBudgeting/View Models/AppLockViewModel.swift:154
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AppLockViewModel.swift:154
  Def: private var canUseBiometricsNow: Bool {
  Dynamic-Risk Checklist: none flagged
- biometricError (var) — OffshoreBudgeting/View Models/AppLockViewModel.swift:155
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AppLockViewModel.swift:155
  Def: var biometricError: BiometricError?
  Dynamic-Risk Checklist: none flagged
- preferredPolicy (func) — OffshoreBudgeting/View Models/AppLockViewModel.swift:159
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AppLockViewModel.swift:159
  Def: private func preferredPolicy() -> LAPolicy {
  Dynamic-Risk Checklist: none flagged
- disableLockForUnavailableAuth (func) — OffshoreBudgeting/View Models/AppLockViewModel.swift:163
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AppLockViewModel.swift:163
  Def: private func disableLockForUnavailableAuth(_ error: BiometricError?) {
  Dynamic-Risk Checklist: none flagged
- SortOption (enum) — OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:33
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:33
  Def: enum SortOption: String, CaseIterable, Identifiable {
  Dynamic-Risk Checklist: none flagged
- BudgetDetailsAlert (struct) — OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:38
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:38
  Def: struct BudgetDetailsAlert: Identifiable {
  Dynamic-Risk Checklist: none flagged
- selectedSegment (var) — OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:53
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:53
  Def: @Published var selectedSegment: Segment = .planned
  Dynamic-Risk Checklist: none flagged
- searchQuery (var) — OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:54
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:54
  Def: @Published var searchQuery: String = ""
  Dynamic-Risk Checklist: none flagged
- isInitialLoadInFlight (var) — OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:71
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:71
  Def: private var isInitialLoadInFlight = false
  Dynamic-Risk Checklist: none flagged
- isLoadInFlight (var) — OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:72
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:72
  Def: private var isLoadInFlight = false
  Dynamic-Risk Checklist: none flagged
- shouldReloadAfterCurrentRun (var) — OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:73
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:73
  Def: private var shouldReloadAfterCurrentRun = false
  Dynamic-Risk Checklist: none flagged
- plannedPlanned (let) — OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:88
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:88
  Def: let plannedPlanned = plannedExpenses.reduce(0) { $0 + $1.plannedAmount }
  Dynamic-Risk Checklist: none flagged
- plannedActual (let) — OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:89
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:89
  Def: let plannedActual  = plannedExpenses.reduce(0) { $0 + $1.actualAmount }
  Dynamic-Risk Checklist: none flagged
- sum (let) — OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:175
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:175
  Def: let sum = (existing?.amount ?? 0) + item.amount
  Dynamic-Risk Checklist: none flagged
- fallbackCategoryURI (func) — OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:207
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:207
  Def: private static func fallbackCategoryURI(for name: String) -> URL {
  Dynamic-Risk Checklist: none flagged
- plannedFilteredSorted (var) — OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:213
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:213
  Def: var plannedFilteredSorted: [PlannedExpense] {
  Dynamic-Risk Checklist: none flagged
- unplannedFilteredSorted (var) — OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:246
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:246
  Def: var unplannedFilteredSorted: [UnplannedExpense] {
  Dynamic-Risk Checklist: none flagged
- resetDateWindowToBudget (func) — OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:401
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:401
  Def: func resetDateWindowToBudget() {
  Dynamic-Risk Checklist: none flagged
- fetchPlannedExpenses (func) — OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:410
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:410
  Def: private func fetchPlannedExpenses(for budget: Budget?, in range: ClosedRange<Date>) -> [PlannedExpense] {
  Dynamic-Risk Checklist: none flagged
- fetchUnplannedExpenses (func) — OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:430
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:430
  Def: private func fetchUnplannedExpenses(for budget: Budget?, in range: ClosedRange<Date>) -> [UnplannedExpense] {
  Dynamic-Risk Checklist: none flagged
- normalizedRange (func) — OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:458
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:458
  Def: private func normalizedRange() -> ClosedRange<Date> {
  Dynamic-Risk Checklist: none flagged
- placeholderText (var) — OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:464
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:464
  Def: var placeholderText: String {
  Dynamic-Risk Checklist: none flagged
- Status (enum) — OffshoreBudgeting/View Models/BudgetMetrics.swift:7
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/BudgetMetrics.swift:7
  Def: enum Status: Equatable {
  Dynamic-Risk Checklist: none flagged
- SavingsOutlookMetrics (struct) — OffshoreBudgeting/View Models/BudgetMetrics.swift:22
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/BudgetMetrics.swift:22
  Def: struct SavingsOutlookMetrics: Equatable {
  Dynamic-Risk Checklist: none flagged
- CardDetailLoadState (enum) — OffshoreBudgeting/View Models/CardDetailViewModel.swift:48
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/CardDetailViewModel.swift:48
  Def: enum CardDetailLoadState: Equatable {
  Dynamic-Risk Checklist: none flagged
- Sort (enum) — OffshoreBudgeting/View Models/CardDetailViewModel.swift:94
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/CardDetailViewModel.swift:94
  Def: enum Sort: String, CaseIterable, Identifiable { case titleAZ, amountLowHigh, amountHighLow, dateOldNew, dateNewOld; var id: String { rawValue } }
  Dynamic-Risk Checklist: none flagged
- filteredTotal (var) — OffshoreBudgeting/View Models/CardDetailViewModel.swift:141
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/CardDetailViewModel.swift:141
  Def: var filteredTotal: Double { filteredExpenses.reduce(0) { $0 + $1.amount } }
  Dynamic-Risk Checklist: none flagged
- setDateRange (func) — OffshoreBudgeting/View Models/CardDetailViewModel.swift:261
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/CardDetailViewModel.swift:261
  Def: func setDateRange(_ start: Date, _ end: Date) {
  Dynamic-Risk Checklist: none flagged
- buildCategories (func) — OffshoreBudgeting/View Models/CardDetailViewModel.swift:325
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/CardDetailViewModel.swift:325
  Def: private func buildCategories(from expenses: [CardExpense]) -> [CardCategoryTotal] {
  Dynamic-Risk Checklist: none flagged
- applySort (func) — OffshoreBudgeting/View Models/CardDetailViewModel.swift:344
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/CardDetailViewModel.swift:344
  Def: private func applySort(_ sort: Sort, to items: [CardExpense]) -> [CardExpense] {
  Dynamic-Risk Checklist: none flagged
- CardsLoadState (enum) — OffshoreBudgeting/View Models/CardsViewModel.swift:24
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/CardsViewModel.swift:24
  Def: enum CardsLoadState: Equatable {
  Dynamic-Risk Checklist: none flagged
- CardsViewModel (class) — OffshoreBudgeting/View Models/CardsViewModel.swift:48
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/CardsViewModel.swift:48
  Def: final class CardsViewModel: ObservableObject {
  Dynamic-Risk Checklist: none flagged
- renameTarget (var) — OffshoreBudgeting/View Models/CardsViewModel.swift:56
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/CardsViewModel.swift:56
  Def: @Published var renameTarget: CardItem?
  Dynamic-Risk Checklist: none flagged
- latestSnapshot (var) — OffshoreBudgeting/View Models/CardsViewModel.swift:64
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/CardsViewModel.swift:64
  Def: private var latestSnapshot: [CardItem] = []
  Dynamic-Risk Checklist: none flagged
- configureAndStartObserver (func) — OffshoreBudgeting/View Models/CardsViewModel.swift:147
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/CardsViewModel.swift:147
  Def: private func configureAndStartObserver() {
  Dynamic-Risk Checklist: none flagged
- addCard (func) — OffshoreBudgeting/View Models/CardsViewModel.swift:235
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/CardsViewModel.swift:235
  Def: func addCard(name: String, theme: CardTheme, effect: CardEffect) async {
  Dynamic-Risk Checklist: none flagged
- promptRename (func) — OffshoreBudgeting/View Models/CardsViewModel.swift:255
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/CardsViewModel.swift:255
  Def: func promptRename(for card: CardItem) {
  Dynamic-Risk Checklist: none flagged
- rename (func) — OffshoreBudgeting/View Models/CardsViewModel.swift:261
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/CardsViewModel.swift:261
  Def: func rename(card: CardItem, to newName: String) async {
  Dynamic-Risk Checklist: none flagged
- reapplyThemes (func) — OffshoreBudgeting/View Models/CardsViewModel.swift:338
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/CardsViewModel.swift:338
  Def: private func reapplyThemes() {
  Dynamic-Risk Checklist: none flagged
- MatchQuality (enum) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:24
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:24
  Def: enum MatchQuality: Equatable {
  Dynamic-Risk Checklist: none flagged
- ImportBucket (enum) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:31
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:31
  Def: enum ImportBucket: Equatable {
  Dynamic-Risk Checklist: none flagged
- amountValue (var) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:62
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:62
  Def: var amountValue: Double? {
  Dynamic-Risk Checklist: none flagged
- isCredit (var) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:66
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:66
  Def: var isCredit: Bool { importKind == .credit }
  Dynamic-Risk Checklist: none flagged
- isPayment (var) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:67
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:67
  Def: var isPayment: Bool { importKind == .payment }
  Dynamic-Risk Checklist: none flagged
- isMissingCoreFields (var) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:69
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:69
  Def: var isMissingCoreFields: Bool {
  Dynamic-Risk Checklist: none flagged
- isOther (let) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:76
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:76
  Def: let isOther = categoryNameFromCSV.trimmingCharacters(in: .whitespacesAndNewlines)
  Dynamic-Risk Checklist: none flagged
- normalizedAmountForImport (var) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:82
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:82
  Def: var normalizedAmountForImport: Double? {
  Dynamic-Risk Checklist: none flagged
- cardObjectID (let) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:102
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:102
  Def: private let cardObjectID: NSManagedObjectID?
  Dynamic-Risk Checklist: none flagged
- categoryService (let) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:105
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:105
  Def: private let categoryService = ExpenseCategoryService()
  Dynamic-Risk Checklist: none flagged
- refreshCategories (func) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:142
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:142
  Def: func refreshCategories() async {
  Dynamic-Risk Checklist: none flagged
- addCategory (func) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:151
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:151
  Def: func addCategory(name: String, hex: String) {
  Dynamic-Risk Checklist: none flagged
- readyRowIDs (var) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:169
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:169
  Def: var readyRowIDs: [UUID] {
  Dynamic-Risk Checklist: none flagged
- possibleMatchRowIDs (var) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:175
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:175
  Def: var possibleMatchRowIDs: [UUID] {
  Dynamic-Risk Checklist: none flagged
- possibleDuplicateRowIDs (var) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:181
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:181
  Def: var possibleDuplicateRowIDs: [UUID] {
  Dynamic-Risk Checklist: none flagged
- paymentRowIDs (var) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:187
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:187
  Def: var paymentRowIDs: [UUID] {
  Dynamic-Risk Checklist: none flagged
- creditRowIDs (var) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:193
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:193
  Def: var creditRowIDs: [UUID] {
  Dynamic-Risk Checklist: none flagged
- missingDataRowIDs (var) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:199
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:199
  Def: var missingDataRowIDs: [UUID] {
  Dynamic-Risk Checklist: none flagged
- defaultSelectedIDs (var) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:213
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:213
  Def: var defaultSelectedIDs: Set<UUID> {
  Dynamic-Risk Checklist: none flagged
- categoryHex (func) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:228
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:228
  Def: func categoryHex(for objectID: NSManagedObjectID?) -> String? {
  Dynamic-Risk Checklist: none flagged
- importRows (func) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:234
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:234
  Def: func importRows(with ids: Set<UUID>) throws {
  Dynamic-Risk Checklist: none flagged
- hasMissingCategory (func) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:291
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:291
  Def: func hasMissingCategory(in ids: Set<UUID>) -> Bool {
  Dynamic-Risk Checklist: none flagged
- assignCategoryToAllSelected (func) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:295
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:295
  Def: func assignCategoryToAllSelected(ids: Set<UUID>, categoryID: NSManagedObjectID) {
  Dynamic-Risk Checklist: none flagged
- shouldBeInCredits (func) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:313
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:313
  Def: private func shouldBeInCredits(_ row: ImportRow) -> Bool {
  Dynamic-Risk Checklist: none flagged
- applyCategoryMatchesAfterCategoryInsert (func) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:317
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:317
  Def: private func applyCategoryMatchesAfterCategoryInsert() {
  Dynamic-Risk Checklist: none flagged
- applyCategoryMatching (func) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:327
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:327
  Def: private func applyCategoryMatching(to rows: [ImportRow]) -> [ImportRow] {
  Dynamic-Risk Checklist: none flagged
- fetchExistingExpenses (func) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:338
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:338
  Def: private func fetchExistingExpenses(for cardID: UUID, rows: [ImportRow]) -> [ExistingExpenseSnapshot] {
  Dynamic-Risk Checklist: none flagged
- dateWindow (func) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:353
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:353
  Def: private func dateWindow(for rows: [ImportRow]) -> DateInterval? {
  Dynamic-Risk Checklist: none flagged
- applyDuplicateDetection (func) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:363
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:363
  Def: private func applyDuplicateDetection(to rows: [ImportRow], existing: [ExistingExpenseSnapshot]) -> [ImportRow] {
  Dynamic-Risk Checklist: none flagged
- normalizedDescription (func) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:406
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:406
  Def: private func normalizedDescription(_ value: String) -> String {
  Dynamic-Risk Checklist: none flagged
- applyCategoryMatch (func) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:410
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:410
  Def: private func applyCategoryMatch(for row: ImportRow) -> ImportRow {
  Dynamic-Risk Checklist: none flagged
- bestCategoryMatch (func) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:430
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:430
  Def: private func bestCategoryMatch(for raw: String) -> ExpenseCategory? {
  Dynamic-Risk Checklist: none flagged
- similarityScore (func) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:454
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:454
  Def: private func similarityScore(lhs: Set<String>, rhs: Set<String>, lhsRaw: String, rhsRaw: String) -> Double {
  Dynamic-Risk Checklist: none flagged
- normalizedTokens (func) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:472
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:472
  Def: private func normalizedTokens(for value: String) -> [String] {
  Dynamic-Risk Checklist: none flagged
- normalizedKey (func) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:482
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:482
  Def: private func normalizedKey(for value: String) -> String {
  Dynamic-Risk Checklist: none flagged
- singularize (func) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:486
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:486
  Def: private func singularize(_ token: String) -> String {
  Dynamic-Risk Checklist: none flagged
- stopwords (let) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:499
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:499
  Def: private let stopwords: Set<String> = ["and", "the", "of", "for", "with", "to", "a", "an"]
  Dynamic-Risk Checklist: none flagged
- categorySynonyms (func) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:501
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:501
  Def: private func categorySynonyms(for categoryKey: String) -> [String] {
  Dynamic-Risk Checklist: none flagged
- categoryBoostScore (func) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:518
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:518
  Def: private func categoryBoostScore(categoryKey: String, rawTokens: Set<String>) -> Double {
  Dynamic-Risk Checklist: none flagged
- parseCSVFile (func) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:536
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:536
  Def: private func parseCSVFile(at url: URL) throws -> [ImportRow] {
  Dynamic-Risk Checklist: none flagged
- assignInitialBuckets (func) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:590
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:590
  Def: private func assignInitialBuckets() {
  Dynamic-Risk Checklist: none flagged
- headerIndex (func) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:611
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:611
  Def: private func headerIndex(in headers: [String], matching candidates: [String]) -> Int? {
  Dynamic-Risk Checklist: none flagged
- parseCSV (func) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:624
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:624
  Def: private func parseCSV(_ text: String) -> [[String]] {
  Dynamic-Risk Checklist: none flagged
- parseDate (func) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:685
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:685
  Def: private func parseDate(_ value: String) -> Date? {
  Dynamic-Risk Checklist: none flagged
- hasLeadingPlus (func) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:724
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:724
  Def: private func hasLeadingPlus(_ value: String) -> Bool {
  Dynamic-Risk Checklist: none flagged
- containsComma (let) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:737
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:737
  Def: let containsComma = stripped.contains(",")
  Dynamic-Risk Checklist: none flagged
- containsDot (let) — OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:738
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/ExpenseImportViewModel.swift:738
  Def: let containsDot = stripped.contains(".")
  Dynamic-Risk Checklist: none flagged
- potentialSavingsTotal (var) — OffshoreBudgeting/View Models/HomeViewModel.swift:90
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:90
  Def: var potentialSavingsTotal: Double { potentialIncomeTotal - plannedExpensesPlannedTotal }
  Dynamic-Risk Checklist: none flagged
- encoded (let) — OffshoreBudgeting/View Models/HomeViewModel.swift:109
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:109
  Def: let encoded = categoryName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? UUID().uuidString
  Dynamic-Risk Checklist: none flagged
- capsPeriodKey (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:119
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:119
  Def: private func capsPeriodKey(start: Date, end: Date, segment: String) -> String {
  Dynamic-Risk Checklist: none flagged
- HomeViewModel (class) — OffshoreBudgeting/View Models/HomeViewModel.swift:159
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:159
  Def: final class HomeViewModel: ObservableObject {
  Dynamic-Risk Checklist: none flagged
- entityChangeMonitor (var) — OffshoreBudgeting/View Models/HomeViewModel.swift:181
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:181
  Def: private var entityChangeMonitor: CoreDataEntityChangeMonitor?
  Dynamic-Risk Checklist: none flagged
- cancellables (var) — OffshoreBudgeting/View Models/HomeViewModel.swift:182
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:182
  Def: private var cancellables: Set<AnyCancellable> = []
  Dynamic-Risk Checklist: none flagged
- isRefreshing (var) — OffshoreBudgeting/View Models/HomeViewModel.swift:184
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:184
  Def: private var isRefreshing = false
  Dynamic-Risk Checklist: none flagged
- hasPostedInitialDataNotification (var) — OffshoreBudgeting/View Models/HomeViewModel.swift:188
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:188
  Def: private var hasPostedInitialDataNotification = false
  Dynamic-Risk Checklist: none flagged
- widgetRefreshTask (var) — OffshoreBudgeting/View Models/HomeViewModel.swift:191
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:191
  Def: private var widgetRefreshTask: Task<Void, Never>?
  Dynamic-Risk Checklist: none flagged
- lastWidgetRefreshAt (var) — OffshoreBudgeting/View Models/HomeViewModel.swift:192
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:192
  Def: private var lastWidgetRefreshAt: Date?
  Dynamic-Risk Checklist: none flagged
- widgetRefreshMinimumInterval (let) — OffshoreBudgeting/View Models/HomeViewModel.swift:193
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:193
  Def: private let widgetRefreshMinimumInterval: TimeInterval = 20.0
  Dynamic-Risk Checklist: none flagged
- isUsingCustomRange (var) — OffshoreBudgeting/View Models/HomeViewModel.swift:217
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:217
  Def: var isUsingCustomRange: Bool { customDateRange != nil }
  Dynamic-Risk Checklist: none flagged
- emitStateDebounced (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:326
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:326
  Def: private func emitStateDebounced(_ newState: BudgetLoadState) {
  Dynamic-Risk Checklist: none flagged
- scheduleWidgetSnapshotRefresh (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:390
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:390
  Def: private func scheduleWidgetSnapshotRefresh(referenceDate: Date, preferDeferred: Bool) {
  Dynamic-Risk Checklist: none flagged
- updateIncomeWidget (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:419
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:419
  Def: private func updateIncomeWidget(from summaries: [BudgetSummary], period: BudgetPeriod) {
  Dynamic-Risk Checklist: none flagged
- updateExpenseToIncomeWidget (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:435
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:435
  Def: private func updateExpenseToIncomeWidget(from summaries: [BudgetSummary], period: BudgetPeriod) {
  Dynamic-Risk Checklist: none flagged
- updateSavingsOutlookWidget (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:449
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:449
  Def: private func updateSavingsOutlookWidget(from summaries: [BudgetSummary], period: BudgetPeriod) {
  Dynamic-Risk Checklist: none flagged
- updateCategorySpotlightWidget (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:468
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:468
  Def: private func updateCategorySpotlightWidget(from summaries: [BudgetSummary], period: BudgetPeriod) {
  Dynamic-Risk Checklist: none flagged
- updateDayOfWeekWidget (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:487
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:487
  Def: private func updateDayOfWeekWidget(from summaries: [BudgetSummary], period: BudgetPeriod, referenceDate: Date) async {
  Dynamic-Risk Checklist: none flagged
- updateIncomeWidgetsForAllPeriods (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:505
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:505
  Def: private func updateIncomeWidgetsForAllPeriods(referenceDate: Date,
  Dynamic-Risk Checklist: none flagged
- updateExpenseToIncomeWidgetsForAllPeriods (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:517
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:517
  Def: private func updateExpenseToIncomeWidgetsForAllPeriods(referenceDate: Date,
  Dynamic-Risk Checklist: none flagged
- updateSavingsOutlookWidgetsForAllPeriods (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:529
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:529
  Def: private func updateSavingsOutlookWidgetsForAllPeriods(referenceDate: Date,
  Dynamic-Risk Checklist: none flagged
- updateCategorySpotlightWidgetsForAllPeriods (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:541
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:541
  Def: private func updateCategorySpotlightWidgetsForAllPeriods(referenceDate: Date,
  Dynamic-Risk Checklist: none flagged
- updateDayOfWeekWidgetsForAllPeriods (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:553
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:553
  Def: private func updateDayOfWeekWidgetsForAllPeriods(referenceDate: Date,
  Dynamic-Risk Checklist: none flagged
- updateCategoryAvailabilityWidgetsForAllPeriods (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:565
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:565
  Def: private func updateCategoryAvailabilityWidgetsForAllPeriods(referenceDate: Date,
  Dynamic-Risk Checklist: none flagged
- updateCardWidgetsForAllPeriods (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:602
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:602
  Def: private func updateCardWidgetsForAllPeriods(referenceDate: Date,
  Dynamic-Risk Checklist: none flagged
- resolveCardUUID (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:726
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:726
  Def: private func resolveCardUUID(for card: Card, context: NSManagedObjectContext) -> UUID? {
  Dynamic-Risk Checklist: none flagged
- resolveBudgetUUID (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:734
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:734
  Def: private func resolveBudgetUUID(for budgetID: NSManagedObjectID, context: NSManagedObjectContext) -> UUID? {
  Dynamic-Risk Checklist: none flagged
- categoryCapsWidget (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:767
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:767
  Def: private func categoryCapsWidget(for summary: BudgetSummary) -> [String: (planned: Double?, variable: Double?)] {
  Dynamic-Risk Checklist: none flagged
- computeCategoryAvailabilityWidget (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:793
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:793
  Def: private func computeCategoryAvailabilityWidget(summary: BudgetSummary, caps: [String: (planned: Double?, variable: Double?)], segment: CategoryAvailabilitySegment) -> [WidgetSharedStore.CategoryAvailabilitySnapshot.Item] {
  Dynamic-Risk Checklist: none flagged
- daySpendTotalsForWidget (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:850
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:850
  Def: private func daySpendTotalsForWidget(summaryID: NSManagedObjectID, in range: ClosedRange<Date>) async -> [Date: DaySpendTotal] {
  Dynamic-Risk Checklist: none flagged
- widgetBuckets (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:908
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:908
  Def: private func widgetBuckets(for period: BudgetPeriod, range: ClosedRange<Date>, dayTotals: [Date: DaySpendTotal]) -> [WidgetSpendBucket] {
  Dynamic-Risk Checklist: none flagged
- DayLabelMode (enum) — OffshoreBudgeting/View Models/HomeViewModel.swift:929
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:929
  Def: private enum DayLabelMode {
  Dynamic-Risk Checklist: none flagged
- bucketsForRanges (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:962
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:962
  Def: private func bucketsForRanges(_ ranges: [ClosedRange<Date>], dayTotals: [Date: DaySpendTotal], labelMode: DayLabelMode) -> [WidgetSpendBucket] {
  Dynamic-Risk Checklist: none flagged
- bucketsForMonths (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:998
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:998
  Def: private func bucketsForMonths(range: ClosedRange<Date>, dayTotals: [Date: DaySpendTotal]) -> [WidgetSpendBucket] {
  Dynamic-Risk Checklist: none flagged
- rangeForWidgetPeriod (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:1028
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:1028
  Def: private func rangeForWidgetPeriod(_ period: BudgetPeriod, referenceDate: Date) -> ClosedRange<Date> {
  Dynamic-Risk Checklist: none flagged
- sundayWeekRange (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:1051
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:1051
  Def: private func sundayWeekRange(containing date: Date) -> ClosedRange<Date> {
  Dynamic-Risk Checklist: none flagged
- splitRange (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:1060
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:1060
  Def: private func splitRange(_ range: ClosedRange<Date>, daysPerBucket: Int) -> [ClosedRange<Date>] {
  Dynamic-Risk Checklist: none flagged
- dayRangeLabel (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:1075
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:1075
  Def: private func dayRangeLabel(for range: ClosedRange<Date>) -> String {
  Dynamic-Risk Checklist: none flagged
- monthsInRange (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:1103
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:1103
  Def: private func monthsInRange(_ range: ClosedRange<Date>) -> [ClosedRange<Date>] {
  Dynamic-Risk Checklist: none flagged
- hexesForCategoryTotals (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:1119
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:1119
  Def: private func hexesForCategoryTotals(_ totals: [CategorySpendKey: Double]) -> [String] {
  Dynamic-Risk Checklist: none flagged
- widgetFallbackHexes (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:1125
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:1125
  Def: private func widgetFallbackHexes(from dayTotals: [Date: DaySpendTotal]) -> [String] {
  Dynamic-Risk Checklist: none flagged
- loadSummaries (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:1142
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:1142
  Def: private func loadSummaries(period: BudgetPeriod, dateRange: ClosedRange<Date>) async -> (summaries: [BudgetSummary], budgetIDs: [NSManagedObjectID]) {
  Dynamic-Risk Checklist: none flagged
- applyCustomRange (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:1183
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:1183
  Def: func applyCustomRange(start: Date, end: Date) {
  Dynamic-Risk Checklist: none flagged
- clearCustomRange (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:1191
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:1191
  Def: func clearCustomRange() {
  Dynamic-Risk Checklist: none flagged
- normalizedRange (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:1199
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:1199
  Def: private static func normalizedRange(start: Date, end: Date) -> ClosedRange<Date>? {
  Dynamic-Risk Checklist: none flagged
- updateBudgetPeriod (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:1211
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:1211
  Def: func updateBudgetPeriod(to newPeriod: BudgetPeriod) {
  Dynamic-Risk Checklist: none flagged
- adjustSelectedPeriod (func) — OffshoreBudgeting/View Models/HomeViewModel.swift:1232
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:1232
  Def: func adjustSelectedPeriod(by delta: Int) {
  Dynamic-Risk Checklist: none flagged
- startDay (let) — OffshoreBudgeting/View Models/HomeViewModel.swift:1309
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:1309
  Def: let startDay = calendar.startOfDay(for: range.lowerBound)
  Dynamic-Risk Checklist: none flagged
- endExclusive (let) — OffshoreBudgeting/View Models/HomeViewModel.swift:1311
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:1311
  Def: let endExclusive = calendar.date(byAdding: .day, value: 1, to: endDay) ?? range.upperBound
  Dynamic-Risk Checklist: none flagged
- plannedFetch (let) — OffshoreBudgeting/View Models/HomeViewModel.swift:1332
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:1332
  Def: let plannedFetch = NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense")
  Dynamic-Risk Checklist: none flagged
- plannedRaw (let) — OffshoreBudgeting/View Models/HomeViewModel.swift:1337
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:1337
  Def: let plannedRaw: [PlannedExpense] = (try? context.fetch(plannedFetch)) ?? []
  Dynamic-Risk Checklist: none flagged
- seenTemplateChildKeys (var) — OffshoreBudgeting/View Models/HomeViewModel.swift:1339
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:1339
  Def: var seenTemplateChildKeys = Set<String>()
  Dynamic-Risk Checklist: none flagged
- dateKey (let) — OffshoreBudgeting/View Models/HomeViewModel.swift:1342
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:1342
  Def: let dateKey = String(format: "%.0f", (exp.transactionDate ?? .distantPast).timeIntervalSince1970)
  Dynamic-Risk Checklist: none flagged
- incomeStartDay (let) — OffshoreBudgeting/View Models/HomeViewModel.swift:1355
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:1355
  Def: let incomeStartDay = calendar.startOfDay(for: periodStart)
  Dynamic-Risk Checklist: none flagged
- incomeEndDay (let) — OffshoreBudgeting/View Models/HomeViewModel.swift:1356
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:1356
  Def: let incomeEndDay = calendar.startOfDay(for: periodEnd)
  Dynamic-Risk Checklist: none flagged
- incomeEndExclusive (let) — OffshoreBudgeting/View Models/HomeViewModel.swift:1357
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:1357
  Def: let incomeEndExclusive = calendar.date(byAdding: .day, value: 1, to: incomeEndDay) ?? periodEnd
  Dynamic-Risk Checklist: none flagged
- unplannedReq (let) — OffshoreBudgeting/View Models/HomeViewModel.swift:1389
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:1389
  Def: let unplannedReq = NSFetchRequest<UnplannedExpense>(entityName: "UnplannedExpense")
  Dynamic-Risk Checklist: none flagged
- sum (let) — OffshoreBudgeting/View Models/HomeViewModel.swift:1436
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/HomeViewModel.swift:1436
  Def: let sum = (existing?.amount ?? 0) + item.amount
  Dynamic-Risk Checklist: none flagged
- IncomeScreenViewModel (class) — OffshoreBudgeting/View Models/IncomeScreenViewModel.swift:14
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/IncomeScreenViewModel.swift:14
  Def: final class IncomeScreenViewModel: ObservableObject {
  Dynamic-Risk Checklist: none flagged
- cancellables (var) — OffshoreBudgeting/View Models/IncomeScreenViewModel.swift:29
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/IncomeScreenViewModel.swift:29
  Def: private var cancellables: Set<AnyCancellable> = []
  Dynamic-Risk Checklist: none flagged
- maxCachedMonths (let) — OffshoreBudgeting/View Models/IncomeScreenViewModel.swift:40
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/IncomeScreenViewModel.swift:40
  Def: private let maxCachedMonths: Int = 24
  Dynamic-Risk Checklist: none flagged
- selectedDateTitle (var) — OffshoreBudgeting/View Models/IncomeScreenViewModel.swift:80
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/IncomeScreenViewModel.swift:80
  Def: var selectedDateTitle: String {
  Dynamic-Risk Checklist: none flagged
- totalForSelectedDateText (var) — OffshoreBudgeting/View Models/IncomeScreenViewModel.swift:85
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/IncomeScreenViewModel.swift:85
  Def: var totalForSelectedDateText: String {
  Dynamic-Risk Checklist: none flagged
- refreshEventsCache (func) — OffshoreBudgeting/View Models/IncomeScreenViewModel.swift:163
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/IncomeScreenViewModel.swift:163
  Def: private func refreshEventsCache(for date: Date, force: Bool) {
  Dynamic-Risk Checklist: none flagged
- prefetchMonths (func) — OffshoreBudgeting/View Models/IncomeScreenViewModel.swift:184
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/IncomeScreenViewModel.swift:184
  Def: private func prefetchMonths(from date: Date, monthsBefore: Int, monthsAfter: Int) {
  Dynamic-Risk Checklist: none flagged
- dynamicHorizon (func) — OffshoreBudgeting/View Models/IncomeScreenViewModel.swift:207
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/IncomeScreenViewModel.swift:207
  Def: private func dynamicHorizon(for date: Date) -> (before: Int, after: Int) {
  Dynamic-Risk Checklist: none flagged
- ensureMonthCached (func) — OffshoreBudgeting/View Models/IncomeScreenViewModel.swift:235
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/IncomeScreenViewModel.swift:235
  Def: private func ensureMonthCached(for date: Date) -> Bool {
  Dynamic-Risk Checklist: none flagged
- trimCacheIfNeeded (func) — OffshoreBudgeting/View Models/IncomeScreenViewModel.swift:249
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/IncomeScreenViewModel.swift:249
  Def: private func trimCacheIfNeeded() {
  Dynamic-Risk Checklist: none flagged
- rebuildEventsByDay (func) — OffshoreBudgeting/View Models/IncomeScreenViewModel.swift:259
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/IncomeScreenViewModel.swift:259
  Def: private func rebuildEventsByDay() {
  Dynamic-Risk Checklist: none flagged
- remapEventsToDisplayCalendar (func) — OffshoreBudgeting/View Models/IncomeScreenViewModel.swift:269
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/IncomeScreenViewModel.swift:269
  Def: private func remapEventsToDisplayCalendar(_ monthEvents: [Date: [IncomeService.IncomeEvent]]) -> [Date: [IncomeService.IncomeEvent]] {
  Dynamic-Risk Checklist: none flagged
- totalsForWeek (func) — OffshoreBudgeting/View Models/IncomeScreenViewModel.swift:304
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/IncomeScreenViewModel.swift:304
  Def: private func totalsForWeek(containing date: Date) throws -> (planned: Double, actual: Double) {
  Dynamic-Risk Checklist: none flagged
- weekInterval (func) — OffshoreBudgeting/View Models/IncomeScreenViewModel.swift:311
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/IncomeScreenViewModel.swift:311
  Def: private func weekInterval(containing date: Date) -> DateInterval? {
  Dynamic-Risk Checklist: none flagged
- plannedCurrency (var) — OffshoreBudgeting/View Models/PresetsViewModel.swift:26
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/PresetsViewModel.swift:26
  Def: var plannedCurrency: String { CurrencyFormatter.shared.string(plannedAmount) }
  Dynamic-Risk Checklist: none flagged
- actualCurrency (var) — OffshoreBudgeting/View Models/PresetsViewModel.swift:27
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/PresetsViewModel.swift:27
  Def: var actualCurrency: String { CurrencyFormatter.shared.string(actualAmount) }
  Dynamic-Risk Checklist: none flagged
- nextDateLabel (var) — OffshoreBudgeting/View Models/PresetsViewModel.swift:28
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/PresetsViewModel.swift:28
  Def: var nextDateLabel: String {
  Dynamic-Risk Checklist: none flagged
- PresetsViewModel (class) — OffshoreBudgeting/View Models/PresetsViewModel.swift:51
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/PresetsViewModel.swift:51
  Def: final class PresetsViewModel: ObservableObject {
  Dynamic-Risk Checklist: none flagged
- applyItemsDebounced (func) — OffshoreBudgeting/View Models/PresetsViewModel.swift:131
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/PresetsViewModel.swift:131
  Def: private func applyItemsDebounced(_ newItems: [PresetListItem]) {
  Dynamic-Risk Checklist: none flagged
- DateFormatterCache (class) — OffshoreBudgeting/View Models/PresetsViewModel.swift:166
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/PresetsViewModel.swift:166
  Def: final class DateFormatterCache {
  Dynamic-Risk Checklist: none flagged
- mediumDate (func) — OffshoreBudgeting/View Models/PresetsViewModel.swift:170
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/PresetsViewModel.swift:170
  Def: func mediumDate(_ date: Date) -> String { medium.string(from: date) }
  Dynamic-Risk Checklist: none flagged
- SettingsViewModel (class) — OffshoreBudgeting/View Models/SettingsViewModel.swift:15
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/SettingsViewModel.swift:15
  Def: final class SettingsViewModel: ObservableObject {
  Dynamic-Risk Checklist: none flagged
- calendarHorizontal (var) — OffshoreBudgeting/View Models/SettingsViewModel.swift:23
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/SettingsViewModel.swift:23
  Def: var calendarHorizontal: Bool = true { willSet { objectWillChange.send() } }
  Dynamic-Risk Checklist: none flagged
- presetsDefaultUseInFutureBudgets (var) — OffshoreBudgeting/View Models/SettingsViewModel.swift:27
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/SettingsViewModel.swift:27
  Def: var presetsDefaultUseInFutureBudgets: Bool = true { willSet { objectWillChange.send() } }
  Dynamic-Risk Checklist: none flagged
- SettingsIcon (struct) — OffshoreBudgeting/View Models/SettingsViewModel.swift:74
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/SettingsViewModel.swift:74
  Def: struct SettingsIcon: View {
  Dynamic-Risk Checklist: none flagged
- compactDimension (var) — OffshoreBudgeting/View Models/SettingsViewModel.swift:79
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/SettingsViewModel.swift:79
  Def: @ScaledMetric(relativeTo: .body) private var compactDimension: CGFloat = 40
  Dynamic-Risk Checklist: none flagged
- regularDimension (var) — OffshoreBudgeting/View Models/SettingsViewModel.swift:80
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/SettingsViewModel.swift:80
  Def: @ScaledMetric(relativeTo: .body) private var regularDimension: CGFloat = 48
  Dynamic-Risk Checklist: none flagged
- compactCornerRadius (var) — OffshoreBudgeting/View Models/SettingsViewModel.swift:81
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/SettingsViewModel.swift:81
  Def: @ScaledMetric(relativeTo: .body) private var compactCornerRadius: CGFloat = 14
  Dynamic-Risk Checklist: none flagged
- regularCornerRadius (var) — OffshoreBudgeting/View Models/SettingsViewModel.swift:82
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/SettingsViewModel.swift:82
  Def: @ScaledMetric(relativeTo: .body) private var regularCornerRadius: CGFloat = 16
  Dynamic-Risk Checklist: none flagged
- iconDimension (var) — OffshoreBudgeting/View Models/SettingsViewModel.swift:104
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/SettingsViewModel.swift:104
  Def: private var iconDimension: CGFloat { isCompact ? compactDimension : regularDimension }
  Dynamic-Risk Checklist: none flagged
- iconCornerRadius (var) — OffshoreBudgeting/View Models/SettingsViewModel.swift:105
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/SettingsViewModel.swift:105
  Def: private var iconCornerRadius: CGFloat { isCompact ? compactCornerRadius : regularCornerRadius }
  Dynamic-Risk Checklist: none flagged
- SettingsCard (struct) — OffshoreBudgeting/View Models/SettingsViewModel.swift:116
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/SettingsViewModel.swift:116
  Def: struct SettingsCard<Content: View>: View {
  Dynamic-Risk Checklist: none flagged
- innerCornerRadius (var) — OffshoreBudgeting/View Models/SettingsViewModel.swift:142
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/SettingsViewModel.swift:142
  Def: private var innerCornerRadius: CGFloat { 14 }
  Dynamic-Risk Checklist: none flagged
- cardPadding (var) — OffshoreBudgeting/View Models/SettingsViewModel.swift:143
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/SettingsViewModel.swift:143
  Def: private var cardPadding: CGFloat { isCompact ? 10 : 16 }
  Dynamic-Risk Checklist: none flagged
- headerSpacing (var) — OffshoreBudgeting/View Models/SettingsViewModel.swift:144
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/SettingsViewModel.swift:144
  Def: private var headerSpacing: CGFloat { isCompact ? 6 : 12 }
  Dynamic-Risk Checklist: none flagged
- outerCornerRadius (var) — OffshoreBudgeting/View Models/SettingsViewModel.swift:145
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/SettingsViewModel.swift:145
  Def: private var outerCornerRadius: CGFloat { isCompact ? 14 : 20 }
  Dynamic-Risk Checklist: none flagged
- legacyCard (func) — OffshoreBudgeting/View Models/SettingsViewModel.swift:148
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/SettingsViewModel.swift:148
  Def: private func legacyCard() -> some View {
  Dynamic-Risk Checklist: none flagged
- modernCard (func) — OffshoreBudgeting/View Models/SettingsViewModel.swift:170
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/SettingsViewModel.swift:170
  Def: private func modernCard() -> some View {
  Dynamic-Risk Checklist: none flagged
- cardHeader (var) — OffshoreBudgeting/View Models/SettingsViewModel.swift:186
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/SettingsViewModel.swift:186
  Def: private var cardHeader: some View {
  Dynamic-Risk Checklist: none flagged
- rowsContainer (var) — OffshoreBudgeting/View Models/SettingsViewModel.swift:202
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/SettingsViewModel.swift:202
  Def: private var rowsContainer: some View {
  Dynamic-Risk Checklist: none flagged
- SettingsRow (struct) — OffshoreBudgeting/View Models/SettingsViewModel.swift:217
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/SettingsViewModel.swift:217
  Def: struct SettingsRow<Trailing: View>: View {
  Dynamic-Risk Checklist: none flagged
- compactRowPadding (var) — OffshoreBudgeting/View Models/SettingsViewModel.swift:225
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/SettingsViewModel.swift:225
  Def: @ScaledMetric(relativeTo: .body) private var compactRowPadding: CGFloat = 10
  Dynamic-Risk Checklist: none flagged
- regularRowPadding (var) — OffshoreBudgeting/View Models/SettingsViewModel.swift:226
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/SettingsViewModel.swift:226
  Def: @ScaledMetric(relativeTo: .body) private var regularRowPadding: CGFloat = 14
  Dynamic-Risk Checklist: none flagged
- compactRowMinHeight (var) — OffshoreBudgeting/View Models/SettingsViewModel.swift:227
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/SettingsViewModel.swift:227
  Def: @ScaledMetric(relativeTo: .body) private var compactRowMinHeight: CGFloat = 40
  Dynamic-Risk Checklist: none flagged
- regularRowMinHeight (var) — OffshoreBudgeting/View Models/SettingsViewModel.swift:228
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/SettingsViewModel.swift:228
  Def: @ScaledMetric(relativeTo: .body) private var regularRowMinHeight: CGFloat = 48
  Dynamic-Risk Checklist: none flagged
- rowHorizontalPadding (var) — OffshoreBudgeting/View Models/SettingsViewModel.swift:274
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/SettingsViewModel.swift:274
  Def: private var rowHorizontalPadding: CGFloat { isCompact ? compactRowPadding : regularRowPadding }
  Dynamic-Risk Checklist: none flagged
- rowMinHeight (var) — OffshoreBudgeting/View Models/SettingsViewModel.swift:275
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/SettingsViewModel.swift:275
  Def: private var rowMinHeight: CGFloat { isCompact ? compactRowMinHeight : regularRowMinHeight }
  Dynamic-Risk Checklist: none flagged
- toggleAllMinHeight (var) — OffshoreBudgeting/Views/AddBudgetView.swift:41
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddBudgetView.swift:41
  Def: @ScaledMetric(relativeTo: .body) private var toggleAllMinHeight: CGFloat = 44
  Dynamic-Risk Checklist: none flagged
- isTracking (let) — OffshoreBudgeting/Views/AddBudgetView.swift:179
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddBudgetView.swift:179
  Def: let isTracking = Binding(
  Dynamic-Risk Checklist: none flagged
- toggleAllCards (func) — OffshoreBudgeting/Views/AddBudgetView.swift:287
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddBudgetView.swift:287
  Def: private func toggleAllCards() {
  Dynamic-Risk Checklist: none flagged
- toggleAllPresets (func) — OffshoreBudgeting/Views/AddBudgetView.swift:296
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddBudgetView.swift:296
  Def: private func toggleAllPresets() {
  Dynamic-Risk Checklist: none flagged
- toggleAllRowButton (func) — OffshoreBudgeting/Views/AddBudgetView.swift:306
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddBudgetView.swift:306
  Def: private func toggleAllRowButton(action: @escaping () -> Void) -> some View {
  Dynamic-Risk Checklist: none flagged
- Mode (enum) — OffshoreBudgeting/Views/AddCardFormView.swift:30
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddCardFormView.swift:30
  Def: enum Mode { case add, edit }
  Dynamic-Risk Checklist: none flagged
- previewItem (var) — OffshoreBudgeting/Views/AddCardFormView.swift:82
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddCardFormView.swift:82
  Def: private var previewItem: CardItem {
  Dynamic-Risk Checklist: none flagged
- EffectSwatch (struct) — OffshoreBudgeting/Views/AddCardFormView.swift:238
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddCardFormView.swift:238
  Def: private struct EffectSwatch: View {
  Dynamic-Risk Checklist: none flagged
- swatchMinHeight (var) — OffshoreBudgeting/Views/AddCardFormView.swift:245
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddCardFormView.swift:245
  Def: @ScaledMetric(relativeTo: .body) private var swatchMinHeight: CGFloat = 72
  Dynamic-Risk Checklist: none flagged
- ThemeSwatch (struct) — OffshoreBudgeting/Views/AddCardFormView.swift:291
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddCardFormView.swift:291
  Def: private struct ThemeSwatch: View {
  Dynamic-Risk Checklist: none flagged
- swatchMinHeight (var) — OffshoreBudgeting/Views/AddCardFormView.swift:297
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddCardFormView.swift:297
  Def: @ScaledMetric(relativeTo: .body) private var swatchMinHeight: CGFloat = 72
  Dynamic-Risk Checklist: none flagged
- showEditScopeOptions (var) — OffshoreBudgeting/Views/AddIncomeFormView.swift:17
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddIncomeFormView.swift:17
  Def: @State private var showEditScopeOptions: Bool = false
  Dynamic-Risk Checklist: none flagged
- formContent (var) — OffshoreBudgeting/Views/AddIncomeFormView.swift:107
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddIncomeFormView.swift:107
  Def: private var formContent: some View {
  Dynamic-Risk Checklist: none flagged
- typeSection (var) — OffshoreBudgeting/Views/AddIncomeFormView.swift:127
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddIncomeFormView.swift:127
  Def: private var typeSection: some View {
  Dynamic-Risk Checklist: none flagged
- sourceSection (var) — OffshoreBudgeting/Views/AddIncomeFormView.swift:144
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddIncomeFormView.swift:144
  Def: private var sourceSection: some View {
  Dynamic-Risk Checklist: none flagged
- amountSection (var) — OffshoreBudgeting/Views/AddIncomeFormView.swift:175
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddIncomeFormView.swift:175
  Def: private var amountSection: some View {
  Dynamic-Risk Checklist: none flagged
- firstDateSection (var) — OffshoreBudgeting/Views/AddIncomeFormView.swift:204
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddIncomeFormView.swift:204
  Def: private var firstDateSection: some View {
  Dynamic-Risk Checklist: none flagged
- recurrenceSection (var) — OffshoreBudgeting/Views/AddIncomeFormView.swift:219
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddIncomeFormView.swift:219
  Def: private var recurrenceSection: some View {
  Dynamic-Risk Checklist: none flagged
- didSyncAssignBudgetToggle (var) — OffshoreBudgeting/Views/AddPlannedExpenseView.swift:40
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddPlannedExpenseView.swift:40
  Def: @State private var didSyncAssignBudgetToggle = false
  Dynamic-Risk Checklist: none flagged
- didApplyDefaultGlobal (var) — OffshoreBudgeting/Views/AddPlannedExpenseView.swift:43
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddPlannedExpenseView.swift:43
  Def: @State private var didApplyDefaultGlobal = false
  Dynamic-Risk Checklist: none flagged
- showAllBudgetsForEdit (var) — OffshoreBudgeting/Views/AddPlannedExpenseView.swift:48
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddPlannedExpenseView.swift:48
  Def: @State private var showAllBudgetsForEdit = false
  Dynamic-Risk Checklist: none flagged
- isShowingScopeDialog (var) — OffshoreBudgeting/Views/AddPlannedExpenseView.swift:49
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddPlannedExpenseView.swift:49
  Def: @State private var isShowingScopeDialog = false
  Dynamic-Risk Checklist: none flagged
- isEditingFromBudgetContext (var) — OffshoreBudgeting/Views/AddPlannedExpenseView.swift:55
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddPlannedExpenseView.swift:55
  Def: private var isEditingFromBudgetContext: Bool {
  Dynamic-Risk Checklist: none flagged
- cardRowHeight (var) — OffshoreBudgeting/Views/AddPlannedExpenseView.swift:61
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddPlannedExpenseView.swift:61
  Def: @ScaledMetric(relativeTo: .body) private var cardRowHeight: CGFloat = 160
  Dynamic-Risk Checklist: none flagged
- presentSaveError (func) — OffshoreBudgeting/Views/AddPlannedExpenseView.swift:446
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddPlannedExpenseView.swift:446
  Def: private func presentSaveError(_ error: Error) {
  Dynamic-Risk Checklist: none flagged
- saveAndStayOpen (func) — OffshoreBudgeting/Views/AddPlannedExpenseView.swift:462
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddPlannedExpenseView.swift:462
  Def: private func saveAndStayOpen() -> Bool {
  Dynamic-Risk Checklist: none flagged
- budgetPickerSection (var) — OffshoreBudgeting/Views/AddPlannedExpenseView.swift:484
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddPlannedExpenseView.swift:484
  Def: private var budgetPickerSection: some View {
  Dynamic-Risk Checklist: none flagged
- isEditingLimited (let) — OffshoreBudgeting/Views/AddPlannedExpenseView.swift:499
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddPlannedExpenseView.swift:499
  Def: let isEditingLimited = isEditingFromBudgetContext && !isSearching && !showAllBudgetsForEdit
  Dynamic-Risk Checklist: none flagged
- collapsed (let) — OffshoreBudgeting/Views/AddPlannedExpenseView.swift:500
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddPlannedExpenseView.swift:500
  Def: let collapsed = !showAllBudgets && !isSearching && !isEditingLimited && all.count > limit
  Dynamic-Risk Checklist: none flagged
- applyDefaultSaveAsGlobalPresetIfNeeded (func) — OffshoreBudgeting/Views/AddPlannedExpenseView.swift:573
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddPlannedExpenseView.swift:573
  Def: private func applyDefaultSaveAsGlobalPresetIfNeeded() {
  Dynamic-Risk Checklist: none flagged
- verticalInset (let) — OffshoreBudgeting/Views/AddPlannedExpenseView.swift:633
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddPlannedExpenseView.swift:633
  Def: private let verticalInset: CGFloat = DS.Spacing.s + DS.Spacing.xs
  Dynamic-Risk Checklist: none flagged
- rowInsets (var) — OffshoreBudgeting/Views/AddPlannedExpenseView.swift:702
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddPlannedExpenseView.swift:702
  Def: private var rowInsets: EdgeInsets {
  Dynamic-Risk Checklist: none flagged
- chipRowLayout (func) — OffshoreBudgeting/Views/AddPlannedExpenseView.swift:721
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddPlannedExpenseView.swift:721
  Def: private func chipRowLayout() -> some View {
  Dynamic-Risk Checklist: none flagged
- chipsScrollView (func) — OffshoreBudgeting/Views/AddPlannedExpenseView.swift:727
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddPlannedExpenseView.swift:727
  Def: private func chipsScrollView() -> some View {
  Dynamic-Risk Checklist: none flagged
- categoryChips (var) — OffshoreBudgeting/Views/AddPlannedExpenseView.swift:738
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddPlannedExpenseView.swift:738
  Def: private var categoryChips: some View {
  Dynamic-Risk Checklist: none flagged
- PresentationDetentsCompat (struct) — OffshoreBudgeting/Views/AddPlannedExpenseView.swift:773
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddPlannedExpenseView.swift:773
  Def: private struct PresentationDetentsCompat: ViewModifier {
  Dynamic-Risk Checklist: none flagged
- AddCategoryPill (struct) — OffshoreBudgeting/Views/AddPlannedExpenseView.swift:784
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddPlannedExpenseView.swift:784
  Def: private struct AddCategoryPill: View {
  Dynamic-Risk Checklist: none flagged
- CategoryChip (struct) — OffshoreBudgeting/Views/AddPlannedExpenseView.swift:829
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddPlannedExpenseView.swift:829
  Def: private struct CategoryChip: View {
  Dynamic-Risk Checklist: none flagged
- cardRowHeight (var) — OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:38
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:38
  Def: @ScaledMetric(relativeTo: .body) private var cardRowHeight: CGFloat = 160
  Dynamic-Risk Checklist: none flagged
- formContent (var) — OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:161
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:161
  Def: private var formContent: some View {
  Dynamic-Risk Checklist: none flagged
- verticalInset (let) — OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:350
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:350
  Def: private let verticalInset: CGFloat = DS.Spacing.s + DS.Spacing.xs
  Dynamic-Risk Checklist: none flagged
- rowInsets (var) — OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:430
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:430
  Def: private var rowInsets: EdgeInsets {
  Dynamic-Risk Checklist: none flagged
- chipRowLayout (func) — OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:474
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:474
  Def: private func chipRowLayout() -> some View {
  Dynamic-Risk Checklist: none flagged
- chipsScrollView (func) — OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:480
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:480
  Def: private func chipsScrollView() -> some View {
  Dynamic-Risk Checklist: none flagged
- categoryChips (var) — OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:491
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:491
  Def: private var categoryChips: some View {
  Dynamic-Risk Checklist: none flagged
- AddCategoryPill (struct) — OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:526
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:526
  Def: private struct AddCategoryPill: View {
  Dynamic-Risk Checklist: none flagged
- CategoryChip (struct) — OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:572
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:572
  Def: private struct CategoryChip: View {
  Dynamic-Risk Checklist: none flagged
- AppLockView (struct) — OffshoreBudgeting/Views/AppLockView.swift:17
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/AppLockView.swift:17
  Def: public struct AppLockView: View {
  Dynamic-Risk Checklist: none flagged
- isPresentingAddVariable (var) — OffshoreBudgeting/Views/BudgetDetailsView.swift:19
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:19
  Def: @State private var isPresentingAddVariable = false
  Dynamic-Risk Checklist: none flagged
- isPresentingManageCards (var) — OffshoreBudgeting/Views/BudgetDetailsView.swift:20
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:20
  Def: @State private var isPresentingManageCards = false
  Dynamic-Risk Checklist: none flagged
- isPresentingManagePresets (var) — OffshoreBudgeting/Views/BudgetDetailsView.swift:21
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:21
  Def: @State private var isPresentingManagePresets = false
  Dynamic-Risk Checklist: none flagged
- editingPlannedBox (var) — OffshoreBudgeting/Views/BudgetDetailsView.swift:23
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:23
  Def: @State private var editingPlannedBox: ObjectIDBox?
  Dynamic-Risk Checklist: none flagged
- editingUnplannedBox (var) — OffshoreBudgeting/Views/BudgetDetailsView.swift:24
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:24
  Def: @State private var editingUnplannedBox: ObjectIDBox?
  Dynamic-Risk Checklist: none flagged
- capOverrides (var) — OffshoreBudgeting/Views/BudgetDetailsView.swift:26
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:26
  Def: @State private var capOverrides: [String: (min: Double?, max: Double?)] = [:]
  Dynamic-Risk Checklist: none flagged
- unplannedExpenseService (let) — OffshoreBudgeting/Views/BudgetDetailsView.swift:31
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:31
  Def: private let unplannedExpenseService = UnplannedExpenseService()
  Dynamic-Risk Checklist: none flagged
- categoryChipRowMinHeight (var) — OffshoreBudgeting/Views/BudgetDetailsView.swift:32
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:32
  Def: @ScaledMetric(relativeTo: .body) private var categoryChipRowMinHeight: CGFloat = 44
  Dynamic-Risk Checklist: none flagged
- resolvedStore (let) — OffshoreBudgeting/Views/BudgetDetailsView.swift:36
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:36
  Def: let resolvedStore = store ?? BudgetDetailsViewModelStore.shared
  Dynamic-Risk Checklist: none flagged
- summaryCard (var) — OffshoreBudgeting/Views/BudgetDetailsView.swift:115
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:115
  Def: private var summaryCard: some View {
  Dynamic-Risk Checklist: none flagged
- segmentRow (var) — OffshoreBudgeting/Views/BudgetDetailsView.swift:140
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:140
  Def: private var segmentRow: some View {
  Dynamic-Risk Checklist: none flagged
- sortRow (var) — OffshoreBudgeting/Views/BudgetDetailsView.swift:150
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:150
  Def: private var sortRow: some View {
  Dynamic-Risk Checklist: none flagged
- rowsSection (var) — OffshoreBudgeting/Views/BudgetDetailsView.swift:166
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:166
  Def: private var rowsSection: some View {
  Dynamic-Risk Checklist: none flagged
- categoryChipsRow (var) — OffshoreBudgeting/Views/BudgetDetailsView.swift:216
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:216
  Def: private var categoryChipsRow: some View {
  Dynamic-Risk Checklist: none flagged
- summaryMetric (func) — OffshoreBudgeting/Views/BudgetDetailsView.swift:270
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:270
  Def: private func summaryMetric(title: String, value: Double) -> some View {
  Dynamic-Risk Checklist: none flagged
- statRow (func) — OffshoreBudgeting/Views/BudgetDetailsView.swift:281
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:281
  Def: private func statRow(for summary: BudgetSummary) -> some View {
  Dynamic-Risk Checklist: none flagged
- statCard (func) — OffshoreBudgeting/Views/BudgetDetailsView.swift:343
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:343
  Def: private func statCard(title: String, color: Color, items: [StatItem], background: Color) -> some View {
  Dynamic-Risk Checklist: none flagged
- toolbarActions (var) — OffshoreBudgeting/Views/BudgetDetailsView.swift:374
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:374
  Def: private var toolbarActions: some View {
  Dynamic-Risk Checklist: none flagged
- dateFormatter (var) — OffshoreBudgeting/Views/BudgetDetailsView.swift:413
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:413
  Def: private var dateFormatter: DateIntervalFormatter {
  Dynamic-Risk Checklist: none flagged
- addPlannedSheet (var) — OffshoreBudgeting/Views/BudgetDetailsView.swift:443
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:443
  Def: private var addPlannedSheet: some View {
  Dynamic-Risk Checklist: none flagged
- addVariableSheet (var) — OffshoreBudgeting/Views/BudgetDetailsView.swift:453
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:453
  Def: private var addVariableSheet: some View {
  Dynamic-Risk Checklist: none flagged
- manageCardsSheet (var) — OffshoreBudgeting/Views/BudgetDetailsView.swift:462
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:462
  Def: private var manageCardsSheet: some View {
  Dynamic-Risk Checklist: none flagged
- managePresetsSheet (var) — OffshoreBudgeting/Views/BudgetDetailsView.swift:473
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:473
  Def: private var managePresetsSheet: some View {
  Dynamic-Risk Checklist: none flagged
- presentCapGauge (func) — OffshoreBudgeting/Views/BudgetDetailsView.swift:497
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:497
  Def: private func presentCapGauge(for cat: BudgetSummary.CategorySpending) {
  Dynamic-Risk Checklist: none flagged
- periodKey (func) — OffshoreBudgeting/Views/BudgetDetailsView.swift:575
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:575
  Def: private func periodKey(start: Date, end: Date, segment: BudgetDetailsViewModel.Segment) -> String {
  Dynamic-Risk Checklist: none flagged
- plannedPlannedCapTotals (var) — OffshoreBudgeting/Views/BudgetDetailsView.swift:590
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:590
  Def: private var plannedPlannedCapTotals: [String: Double] {
  Dynamic-Risk Checklist: none flagged
- defaultCaps (func) — OffshoreBudgeting/Views/BudgetDetailsView.swift:618
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:618
  Def: private func defaultCaps(for categoryName: String, segment: BudgetDetailsViewModel.Segment) -> (min: Double, max: Double?) {
  Dynamic-Risk Checklist: none flagged
- capLimits (func) — OffshoreBudgeting/Views/BudgetDetailsView.swift:624
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:624
  Def: private func capLimits(for categoryName: String, segment: BudgetDetailsViewModel.Segment) -> (min: Double, max: Double?) {
  Dynamic-Risk Checklist: none flagged
- isOverCap (func) — OffshoreBudgeting/Views/BudgetDetailsView.swift:633
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:633
  Def: private func isOverCap(category: BudgetSummary.CategorySpending, segment: BudgetDetailsViewModel.Segment) -> Bool {
  Dynamic-Risk Checklist: none flagged
- saveCaps (func) — OffshoreBudgeting/Views/BudgetDetailsView.swift:639
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:639
  Def: private func saveCaps(for data: CapGaugeData, min: Double, max: Double?) async {
  Dynamic-Risk Checklist: none flagged
- CategoryCapGaugeSheet (struct) — OffshoreBudgeting/Views/BudgetDetailsView.swift:711
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:711
  Def: private struct CategoryCapGaugeSheet: View {
  Dynamic-Risk Checklist: none flagged
- minText (var) — OffshoreBudgeting/Views/BudgetDetailsView.swift:716
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:716
  Def: @State private var minText: String
  Dynamic-Risk Checklist: none flagged
- maxText (var) — OffshoreBudgeting/Views/BudgetDetailsView.swift:717
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:717
  Def: @State private var maxText: String
  Dynamic-Risk Checklist: none flagged
- editedMin (var) — OffshoreBudgeting/Views/BudgetDetailsView.swift:732
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:732
  Def: private var editedMin: Double { parsedMin ?? data.minCap }
  Dynamic-Risk Checklist: none flagged
- maxValue (var) — OffshoreBudgeting/Views/BudgetDetailsView.swift:737
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:737
  Def: private var maxValue: Double {
  Dynamic-Risk Checklist: none flagged
- maxLabelString (var) — OffshoreBudgeting/Views/BudgetDetailsView.swift:743
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:743
  Def: private var maxLabelString: String {
  Dynamic-Risk Checklist: none flagged
- isSaveDisabled (var) — OffshoreBudgeting/Views/BudgetDetailsView.swift:746
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:746
  Def: private var isSaveDisabled: Bool {
  Dynamic-Risk Checklist: none flagged
- capEditor (var) — OffshoreBudgeting/Views/BudgetDetailsView.swift:831
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:831
  Def: private var capEditor: some View {
  Dynamic-Risk Checklist: none flagged
- handleSave (func) — OffshoreBudgeting/Views/BudgetDetailsView.swift:884
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:884
  Def: private func handleSave() async {
  Dynamic-Risk Checklist: none flagged
- parsedMin (var) — OffshoreBudgeting/Views/BudgetDetailsView.swift:893
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:893
  Def: private var parsedMin: Double? { parseAmount(minText) }
  Dynamic-Risk Checklist: none flagged
- parsedMax (var) — OffshoreBudgeting/Views/BudgetDetailsView.swift:894
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:894
  Def: private var parsedMax: Double? { parseAmount(maxText) }
  Dynamic-Risk Checklist: none flagged
- parseAmount (func) — OffshoreBudgeting/Views/BudgetDetailsView.swift:896
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:896
  Def: private func parseAmount(_ text: String) -> Double? {
  Dynamic-Risk Checklist: none flagged
- formatInput (func) — OffshoreBudgeting/Views/BudgetDetailsView.swift:906
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:906
  Def: private static func formatInput(_ value: Double) -> String {
  Dynamic-Risk Checklist: none flagged
- clamp (func) — OffshoreBudgeting/Views/BudgetDetailsView.swift:927
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetDetailsView.swift:927
  Def: private func clamp(_ value: Double, min: Double, max: Double) -> Double {
  Dynamic-Risk Checklist: none flagged
- BudgetsView (struct) — OffshoreBudgeting/Views/BudgetsView.swift:6
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:6
  Def: struct BudgetsView: View {
  Dynamic-Risk Checklist: none flagged
- isLoading (var) — OffshoreBudgeting/Views/BudgetsView.swift:9
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:9
  Def: @State private var isLoading = false
  Dynamic-Risk Checklist: none flagged
- isPresentingAddBudget (var) — OffshoreBudgeting/Views/BudgetsView.swift:11
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:11
  Def: @State private var isPresentingAddBudget = false
  Dynamic-Risk Checklist: none flagged
- expandedActive (var) — OffshoreBudgeting/Views/BudgetsView.swift:14
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:14
  Def: @State private var expandedActive = true
  Dynamic-Risk Checklist: none flagged
- expandedUpcoming (var) — OffshoreBudgeting/Views/BudgetsView.swift:15
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:15
  Def: @State private var expandedUpcoming = false
  Dynamic-Risk Checklist: none flagged
- expandedPast (var) — OffshoreBudgeting/Views/BudgetsView.swift:16
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:16
  Def: @State private var expandedPast = false
  Dynamic-Risk Checklist: none flagged
- searchFocused (var) — OffshoreBudgeting/Views/BudgetsView.swift:18
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:18
  Def: @FocusState private var searchFocused: Bool
  Dynamic-Risk Checklist: none flagged
- addBudgetSheet (var) — OffshoreBudgeting/Views/BudgetsView.swift:103
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:103
  Def: private var addBudgetSheet: some View {
  Dynamic-Risk Checklist: none flagged
- activeBudgets (var) — OffshoreBudgeting/Views/BudgetsView.swift:112
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:112
  Def: private var activeBudgets: [Budget] {
  Dynamic-Risk Checklist: none flagged
- pastBudgets (var) — OffshoreBudgeting/Views/BudgetsView.swift:117
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:117
  Def: private var pastBudgets: [Budget] {
  Dynamic-Risk Checklist: none flagged
- upcomingBudgets (var) — OffshoreBudgeting/Views/BudgetsView.swift:124
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:124
  Def: private var upcomingBudgets: [Budget] {
  Dynamic-Risk Checklist: none flagged
- loadBudgetsIfNeeded (func) — OffshoreBudgeting/Views/BudgetsView.swift:132
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:132
  Def: private func loadBudgetsIfNeeded() async {
  Dynamic-Risk Checklist: none flagged
- isActive (func) — OffshoreBudgeting/Views/BudgetsView.swift:154
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:154
  Def: private func isActive(_ budget: Budget, on date: Date) -> Bool {
  Dynamic-Risk Checklist: none flagged
- defaultBudgetDates (func) — OffshoreBudgeting/Views/BudgetsView.swift:159
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:159
  Def: private func defaultBudgetDates() -> (start: Date, end: Date) {
  Dynamic-Risk Checklist: none flagged
- trimmedSearchText (var) — OffshoreBudgeting/Views/BudgetsView.swift:166
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:166
  Def: private var trimmedSearchText: String {
  Dynamic-Risk Checklist: none flagged
- matchesSearch (func) — OffshoreBudgeting/Views/BudgetsView.swift:180
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:180
  Def: private func matchesSearch(_ budget: Budget, query: String) -> Bool {
  Dynamic-Risk Checklist: none flagged
- looksDateish (func) — OffshoreBudgeting/Views/BudgetsView.swift:193
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:193
  Def: private func looksDateish(_ text: String) -> Bool {
  Dynamic-Risk Checklist: none flagged
- detectedDates (func) — OffshoreBudgeting/Views/BudgetsView.swift:212
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:212
  Def: private func detectedDates(in text: String) -> [Date] {
  Dynamic-Risk Checklist: none flagged
- budgetContains (func) — OffshoreBudgeting/Views/BudgetsView.swift:220
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:220
  Def: private func budgetContains(date: Date, budget: Budget) -> Bool {
  Dynamic-Risk Checklist: none flagged
- budgetOverlaps (func) — OffshoreBudgeting/Views/BudgetsView.swift:225
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:225
  Def: private func budgetOverlaps(range: ClosedRange<Date>, budget: Budget) -> Bool {
  Dynamic-Risk Checklist: none flagged
- BudgetSectionKey (enum) — OffshoreBudgeting/Views/BudgetsView.swift:231
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:231
  Def: private enum BudgetSectionKey {
  Dynamic-Risk Checklist: none flagged
- effectiveActiveExpanded (var) — OffshoreBudgeting/Views/BudgetsView.swift:237
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:237
  Def: private var effectiveActiveExpanded: Bool { isSearchActive ? true : expandedActive }
  Dynamic-Risk Checklist: none flagged
- effectiveUpcomingExpanded (var) — OffshoreBudgeting/Views/BudgetsView.swift:238
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:238
  Def: private var effectiveUpcomingExpanded: Bool { isSearchActive ? true : expandedUpcoming }
  Dynamic-Risk Checklist: none flagged
- effectivePastExpanded (var) — OffshoreBudgeting/Views/BudgetsView.swift:239
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:239
  Def: private var effectivePastExpanded: Bool { isSearchActive ? true : expandedPast }
  Dynamic-Risk Checklist: none flagged
- toggleExpanded (func) — OffshoreBudgeting/Views/BudgetsView.swift:241
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:241
  Def: private func toggleExpanded(_ key: BudgetSectionKey) {
  Dynamic-Risk Checklist: none flagged
- searchToolbarControl (var) — OffshoreBudgeting/Views/BudgetsView.swift:308
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:308
  Def: private var searchToolbarControl: some View {
  Dynamic-Risk Checklist: none flagged
- searchToolbarControlGlass (var) — OffshoreBudgeting/Views/BudgetsView.swift:317
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:317
  Def: private var searchToolbarControlGlass: some View {
  Dynamic-Risk Checklist: none flagged
- searchToolbarControlLegacy (var) — OffshoreBudgeting/Views/BudgetsView.swift:332
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:332
  Def: private var searchToolbarControlLegacy: some View {
  Dynamic-Risk Checklist: none flagged
- glassSearchField (var) — OffshoreBudgeting/Views/BudgetsView.swift:346
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:346
  Def: private var glassSearchField: some View {
  Dynamic-Risk Checklist: none flagged
- legacySearchField (var) — OffshoreBudgeting/Views/BudgetsView.swift:360
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:360
  Def: private var legacySearchField: some View {
  Dynamic-Risk Checklist: none flagged
- activeLocal (let) — OffshoreBudgeting/Views/BudgetsView.swift:415
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:415
  Def: static let activeLocal = "budgets.section.active.expanded.local"
  Dynamic-Risk Checklist: none flagged
- activeCloud (let) — OffshoreBudgeting/Views/BudgetsView.swift:416
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:416
  Def: static let activeCloud = "budgets.section.active.expanded.cloud"
  Dynamic-Risk Checklist: none flagged
- upcomingLocal (let) — OffshoreBudgeting/Views/BudgetsView.swift:417
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:417
  Def: static let upcomingLocal = "budgets.section.upcoming.expanded.local"
  Dynamic-Risk Checklist: none flagged
- upcomingCloud (let) — OffshoreBudgeting/Views/BudgetsView.swift:418
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:418
  Def: static let upcomingCloud = "budgets.section.upcoming.expanded.cloud"
  Dynamic-Risk Checklist: none flagged
- pastLocal (let) — OffshoreBudgeting/Views/BudgetsView.swift:419
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:419
  Def: static let pastLocal = "budgets.section.past.expanded.local"
  Dynamic-Risk Checklist: none flagged
- pastCloud (let) — OffshoreBudgeting/Views/BudgetsView.swift:420
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:420
  Def: static let pastCloud = "budgets.section.past.expanded.cloud"
  Dynamic-Risk Checklist: none flagged
- loadExpansionState (func) — OffshoreBudgeting/Views/BudgetsView.swift:423
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:423
  Def: private func loadExpansionState() {
  Dynamic-Risk Checklist: none flagged
- loadExpandedValue (func) — OffshoreBudgeting/Views/BudgetsView.swift:435
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:435
  Def: private func loadExpandedValue(defaultValue: Bool, localKey: String, cloudKey: String) -> Bool {
  Dynamic-Risk Checklist: none flagged
- persistExpandedState (func) — OffshoreBudgeting/Views/BudgetsView.swift:457
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:457
  Def: private func persistExpandedState(for key: BudgetSectionKey, value: Bool) {
  Dynamic-Risk Checklist: none flagged
- syncExpandedValueIfNeeded (func) — OffshoreBudgeting/Views/BudgetsView.swift:472
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:472
  Def: private func syncExpandedValueIfNeeded(_ value: Bool, cloudKey: String) {
  Dynamic-Risk Checklist: none flagged
- BudgetRow (struct) — OffshoreBudgeting/Views/BudgetsView.swift:499
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:499
  Def: private struct BudgetRow: View {
  Dynamic-Risk Checklist: none flagged
- dateFormatter (let) — OffshoreBudgeting/Views/BudgetsView.swift:502
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:502
  Def: private let dateFormatter: DateIntervalFormatter = {
  Dynamic-Risk Checklist: none flagged
- accessibilityLabelText (var) — OffshoreBudgeting/Views/BudgetsView.swift:529
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:529
  Def: private var accessibilityLabelText: String {
  Dynamic-Risk Checklist: none flagged
- AlertItem (struct) — OffshoreBudgeting/Views/BudgetsView.swift:537
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:537
  Def: private struct AlertItem: Identifiable {
  Dynamic-Risk Checklist: none flagged
- isPresentingEditCard (var) — OffshoreBudgeting/Views/CardDetailView.swift:28
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:28
  Def: @State private var isPresentingEditCard: Bool = false
  Dynamic-Risk Checklist: none flagged
- isSearchFieldFocused (var) — OffshoreBudgeting/Views/CardDetailView.swift:39
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:39
  Def: @FocusState private var isSearchFieldFocused: Bool
  Dynamic-Risk Checklist: none flagged
- deletionError (var) — OffshoreBudgeting/Views/CardDetailView.swift:44
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:44
  Def: @State private var deletionError: DeletionError?
  Dynamic-Risk Checklist: none flagged
- editingExpense (var) — OffshoreBudgeting/Views/CardDetailView.swift:45
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:45
  Def: @State private var editingExpense: CardExpense?
  Dynamic-Risk Checklist: none flagged
- isPresentingImportPicker (var) — OffshoreBudgeting/Views/CardDetailView.swift:46
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:46
  Def: @State private var isPresentingImportPicker: Bool = false
  Dynamic-Risk Checklist: none flagged
- importPickerCoordinator (var) — OffshoreBudgeting/Views/CardDetailView.swift:49
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:49
  Def: @StateObject private var importPickerCoordinator = ImportPickerCoordinator()
  Dynamic-Risk Checklist: none flagged
- initialHeaderTopPadding (let) — OffshoreBudgeting/Views/CardDetailView.swift:61
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:61
  Def: private let initialHeaderTopPadding: CGFloat = 16
  Dynamic-Risk Checklist: none flagged
- categoryChipDotSize (var) — OffshoreBudgeting/Views/CardDetailView.swift:63
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:63
  Def: @ScaledMetric(relativeTo: .subheadline) private var categoryChipDotSize: CGFloat = 10
  Dynamic-Risk Checklist: none flagged
- detailsList (func) — OffshoreBudgeting/Views/CardDetailView.swift:233
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:233
  Def: private func detailsList(cardMaxWidth: CGFloat?) -> some View {
  Dynamic-Risk Checklist: none flagged
- handleCardEdit (func) — OffshoreBudgeting/Views/CardDetailView.swift:404
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:404
  Def: private func handleCardEdit(name: String, theme: CardTheme, effect: CardEffect) {
  Dynamic-Risk Checklist: none flagged
- handleDelete (func) — OffshoreBudgeting/Views/CardDetailView.swift:439
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:439
  Def: private func handleDelete(_ offsets: IndexSet) {
  Dynamic-Risk Checklist: none flagged
- performDelete (func) — OffshoreBudgeting/Views/CardDetailView.swift:454
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:454
  Def: private func performDelete(_ expense: CardExpense) {
  Dynamic-Risk Checklist: none flagged
- navigationContent (var) — OffshoreBudgeting/Views/CardDetailView.swift:486
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:486
  Def: private var navigationContent: some View {
  Dynamic-Risk Checklist: none flagged
- searchToolbarControl (var) — OffshoreBudgeting/Views/CardDetailView.swift:540
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:540
  Def: private var searchToolbarControl: some View {
  Dynamic-Risk Checklist: none flagged
- searchToolbarControlGlass (var) — OffshoreBudgeting/Views/CardDetailView.swift:549
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:549
  Def: private var searchToolbarControlGlass: some View {
  Dynamic-Risk Checklist: none flagged
- presentImportPicker (func) — OffshoreBudgeting/Views/CardDetailView.swift:562
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:562
  Def: private func presentImportPicker() {
  Dynamic-Risk Checklist: none flagged
- ImportPickerCoordinator (class) — OffshoreBudgeting/Views/CardDetailView.swift:583
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:583
  Def: private final class ImportPickerCoordinator: NSObject, UIDocumentPickerDelegate, ObservableObject {
  Dynamic-Risk Checklist: none flagged
- documentPicker (func) — OffshoreBudgeting/Views/CardDetailView.swift:586
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:586
  Def: func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
  Dynamic-Risk Checklist: none flagged
- documentPickerWasCancelled (func) — OffshoreBudgeting/Views/CardDetailView.swift:590
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:590
  Def: func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
  Dynamic-Risk Checklist: none flagged
- presentCatalystDocumentPicker (func) — OffshoreBudgeting/Views/CardDetailView.swift:605
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:605
  Def: private func presentCatalystDocumentPicker() {
  Dynamic-Risk Checklist: none flagged
- searchToolbarControlLegacy (var) — OffshoreBudgeting/Views/CardDetailView.swift:632
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:632
  Def: private var searchToolbarControlLegacy: some View {
  Dynamic-Risk Checklist: none flagged
- glassSearchField (var) — OffshoreBudgeting/Views/CardDetailView.swift:644
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:644
  Def: private var glassSearchField: some View {
  Dynamic-Risk Checklist: none flagged
- legacySearchField (var) — OffshoreBudgeting/Views/CardDetailView.swift:658
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:658
  Def: private var legacySearchField: some View {
  Dynamic-Risk Checklist: none flagged
- goButton (var) — OffshoreBudgeting/Views/CardDetailView.swift:708
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:708
  Def: private var goButton: some View {
  Dynamic-Risk Checklist: none flagged
- calendarMenu (var) — OffshoreBudgeting/Views/CardDetailView.swift:746
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:746
  Def: private var calendarMenu: some View {
  Dynamic-Risk Checklist: none flagged
- applyDateRange (func) — OffshoreBudgeting/Views/CardDetailView.swift:794
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:794
  Def: private func applyDateRange() {
  Dynamic-Risk Checklist: none flagged
- resolvedCardMaxWidth (func) — OffshoreBudgeting/Views/CardDetailView.swift:802
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:802
  Def: private func resolvedCardMaxWidth(in context: ResponsiveLayoutContext) -> CGFloat? {
  Dynamic-Risk Checklist: none flagged
- resolvedDateRowMaxWidth (func) — OffshoreBudgeting/Views/CardDetailView.swift:819
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:819
  Def: private func resolvedDateRowMaxWidth(in context: ResponsiveLayoutContext) -> CGFloat? {
  Dynamic-Risk Checklist: none flagged
- boundedCardWidth (func) — OffshoreBudgeting/Views/CardDetailView.swift:836
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:836
  Def: private func boundedCardWidth(for availableWidth: CGFloat, upperBound: CGFloat) -> CGFloat? {
  Dynamic-Risk Checklist: none flagged
- totalSpentHeatmapColors (var) — OffshoreBudgeting/Views/CardDetailView.swift:850
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:850
  Def: private var totalSpentHeatmapColors: [Color]? {
  Dynamic-Risk Checklist: none flagged
- rawColors (let) — OffshoreBudgeting/Views/CardDetailView.swift:851
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:851
  Def: let rawColors = viewModel.filteredCategories.compactMap { UBColorFromHex($0.colorHex) }
  Dynamic-Risk Checklist: none flagged
- totalSpentHeatmapBackground (func) — OffshoreBudgeting/Views/CardDetailView.swift:858
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:858
  Def: private func totalSpentHeatmapBackground(colors: [Color]) -> some View {
  Dynamic-Risk Checklist: none flagged
- HeatmapBlob (struct) — OffshoreBudgeting/Views/CardDetailView.swift:875
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:875
  Def: private struct HeatmapBlob: Identifiable {
  Dynamic-Risk Checklist: none flagged
- heatmapBlobs (func) — OffshoreBudgeting/Views/CardDetailView.swift:883
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:883
  Def: private func heatmapBlobs(from colors: [Color]) -> [HeatmapBlob] {
  Dynamic-Risk Checklist: none flagged
- softenedHeatmapColors (func) — OffshoreBudgeting/Views/CardDetailView.swift:902
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:902
  Def: private func softenedHeatmapColors(from colors: [Color]) -> [Color] {
  Dynamic-Risk Checklist: none flagged
- softenHeatmapColor (func) — OffshoreBudgeting/Views/CardDetailView.swift:906
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:906
  Def: private func softenHeatmapColor(_ color: Color) -> Color {
  Dynamic-Risk Checklist: none flagged
- ExpenseRow (struct) — OffshoreBudgeting/Views/CardDetailView.swift:941
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:941
  Def: private struct ExpenseRow: View {
  Dynamic-Risk Checklist: none flagged
- categoryDotSize (var) — OffshoreBudgeting/Views/CardDetailView.swift:944
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:944
  Def: @ScaledMetric(relativeTo: .caption) private var categoryDotSize: CGFloat = 8
  Dynamic-Risk Checklist: none flagged
- catColor (let) — OffshoreBudgeting/Views/CardDetailView.swift:959
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:959
  Def: let catColor = UBColorFromHex(expense.category?.color) ?? .secondary
  Dynamic-Risk Checklist: none flagged
- IconOnlyButton (struct) — OffshoreBudgeting/Views/CardDetailView.swift:990
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:990
  Def: private struct IconOnlyButton: View {
  Dynamic-Risk Checklist: none flagged
- DeletionError (struct) — OffshoreBudgeting/Views/CardDetailView.swift:1016
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:1016
  Def: private struct DeletionError: Identifiable {
  Dynamic-Risk Checklist: none flagged
- categoryChip (func) — OffshoreBudgeting/Views/CardDetailView.swift:1028
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardDetailView.swift:1028
  Def: func categoryChip(_ cat: CardCategoryTotal) -> some View {
  Dynamic-Risk Checklist: none flagged
- CardPickerItemTile (struct) — OffshoreBudgeting/Views/CardPickerItemTile.swift:15
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardPickerItemTile.swift:15
  Def: struct CardPickerItemTile: View {
  Dynamic-Risk Checklist: none flagged
- creditCardAspect (let) — OffshoreBudgeting/Views/CardPickerItemTile.swift:24
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardPickerItemTile.swift:24
  Def: private let creditCardAspect: CGFloat = 85.60 / 53.98 // ≈ 1.586
  Dynamic-Risk Checklist: none flagged
- pickerHeight (let) — OffshoreBudgeting/Views/CardPickerItemTile.swift:26
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardPickerItemTile.swift:26
  Def: private let pickerHeight: CGFloat = 132
  Dynamic-Risk Checklist: none flagged
- uiItem (let) — OffshoreBudgeting/Views/CardPickerItemTile.swift:30
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardPickerItemTile.swift:30
  Def: let uiItem = CardItem(from: card)
  Dynamic-Risk Checklist: none flagged
- CardPickerRow (struct) — OffshoreBudgeting/Views/CardPickerRow.swift:25
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardPickerRow.swift:25
  Def: struct CardPickerRow: View {
  Dynamic-Risk Checklist: none flagged
- tileHeight (var) — OffshoreBudgeting/Views/CardPickerRow.swift:37
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardPickerRow.swift:37
  Def: @ScaledMetric(relativeTo: .body) private var tileHeight: CGFloat = 160
  Dynamic-Risk Checklist: none flagged
- idString (let) — OffshoreBudgeting/Views/CardPickerRow.swift:49
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardPickerRow.swift:49
  Def: let idString = managedCard.objectID.uriRepresentation().absoluteString
  Dynamic-Risk Checklist: none flagged
- scrollToSelected (func) — OffshoreBudgeting/Views/CardPickerRow.swift:90
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardPickerRow.swift:90
  Def: private func scrollToSelected(_ proxy: ScrollViewProxy, animated: Bool) {
  Dynamic-Risk Checklist: none flagged
- enableMaterialMotion (var) — OffshoreBudgeting/Views/CardTileView.swift:37
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:37
  Def: var enableMaterialMotion: Bool = true
  Dynamic-Risk Checklist: none flagged
- nonAccessibilityTitleLineLimit (var) — OffshoreBudgeting/Views/CardTileView.swift:46
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:46
  Def: var nonAccessibilityTitleLineLimit: Int = 2
  Dynamic-Risk Checklist: none flagged
- nonAccessibilityTitleMinimumScaleFactor (var) — OffshoreBudgeting/Views/CardTileView.swift:48
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:48
  Def: var nonAccessibilityTitleMinimumScaleFactor: CGFloat? = nil
  Dynamic-Risk Checklist: none flagged
- nonAccessibilityTitleAllowsTightening (var) — OffshoreBudgeting/Views/CardTileView.swift:50
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:50
  Def: var nonAccessibilityTitleAllowsTightening: Bool = false
  Dynamic-Risk Checklist: none flagged
- titlePadding (var) — OffshoreBudgeting/Views/CardTileView.swift:62
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:62
  Def: @ScaledMetric(relativeTo: .body) private var titlePadding: CGFloat = DS.Spacing.l
  Dynamic-Risk Checklist: none flagged
- minimumTileHeight (var) — OffshoreBudgeting/Views/CardTileView.swift:63
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:63
  Def: @ScaledMetric(relativeTo: .body) private var minimumTileHeight: CGFloat = 160
  Dynamic-Risk Checklist: none flagged
- tileVisual (var) — OffshoreBudgeting/Views/CardTileView.swift:111
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:111
  Def: var tileVisual: some View {
  Dynamic-Risk Checklist: none flagged
- selectionFillOverlay (var) — OffshoreBudgeting/Views/CardTileView.swift:170
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:170
  Def: var selectionFillOverlay: some View {
  Dynamic-Risk Checklist: none flagged
- selectionRingOverlay (var) — OffshoreBudgeting/Views/CardTileView.swift:187
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:187
  Def: var selectionRingOverlay: some View {
  Dynamic-Risk Checklist: none flagged
- selectionGlowOverlay (var) — OffshoreBudgeting/Views/CardTileView.swift:211
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:211
  Def: var selectionGlowOverlay: some View {
  Dynamic-Risk Checklist: none flagged
- thinEdgeOverlay (var) — OffshoreBudgeting/Views/CardTileView.swift:224
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:224
  Def: var thinEdgeOverlay: some View {
  Dynamic-Risk Checklist: none flagged
- cardTitle (var) — OffshoreBudgeting/Views/CardTileView.swift:231
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:231
  Def: var cardTitle: some View {
  Dynamic-Risk Checklist: none flagged
- titleFont (let) — OffshoreBudgeting/Views/CardTileView.swift:232
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:232
  Def: let titleFont = Font.system(.title, design: .rounded).weight(.semibold)
  Dynamic-Risk Checklist: none flagged
- titleColor (let) — OffshoreBudgeting/Views/CardTileView.swift:233
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:233
  Def: let titleColor: Color = isHighContrast ? .primary : UBTypography.cardTitleStatic
  Dynamic-Risk Checklist: none flagged
- allowMotionShine (let) — OffshoreBudgeting/Views/CardTileView.swift:234
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:234
  Def: let allowMotionShine = enableMotionShine && !reduceMotion && !isHighContrast
  Dynamic-Risk Checklist: none flagged
- selectionBadge (var) — OffshoreBudgeting/Views/CardTileView.swift:255
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:255
  Def: var selectionBadge: some View {
  Dynamic-Risk Checklist: none flagged
- ring (let) — OffshoreBudgeting/Views/CardTileView.swift:294
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:294
  Def: let ring = holographicRingMetrics(for: size)
  Dynamic-Risk Checklist: none flagged
- ringShape (let) — OffshoreBudgeting/Views/CardTileView.swift:295
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:295
  Def: let ringShape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
  Dynamic-Risk Checklist: none flagged
- materialFill (func) — OffshoreBudgeting/Views/CardTileView.swift:346
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:346
  Def: func materialFill(for size: CGSize) -> AnyShapeStyle {
  Dynamic-Risk Checklist: none flagged
- materialSaturation (var) — OffshoreBudgeting/Views/CardTileView.swift:362
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:362
  Def: var materialSaturation: Double {
  Dynamic-Risk Checklist: none flagged
- materialOverlayColor (func) — OffshoreBudgeting/Views/CardTileView.swift:376
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:376
  Def: func materialOverlayColor(for size: CGSize) -> Color {
  Dynamic-Risk Checklist: none flagged
- glassSurface (func) — OffshoreBudgeting/Views/CardTileView.swift:390
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:390
  Def: func glassSurface(for size: CGSize) -> some View {
  Dynamic-Risk Checklist: none flagged
- glassThemeTint (var) — OffshoreBudgeting/Views/CardTileView.swift:429
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:429
  Def: var glassThemeTint: Color {
  Dynamic-Risk Checklist: none flagged
- saturationBoost (let) — OffshoreBudgeting/Views/CardTileView.swift:432
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:432
  Def: let saturationBoost = colorScheme == .dark ? 0.06 : 0.12
  Dynamic-Risk Checklist: none flagged
- brightnessBoost (let) — OffshoreBudgeting/Views/CardTileView.swift:433
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:433
  Def: let brightnessBoost = colorScheme == .dark ? 0.08 : 0.04
  Dynamic-Risk Checklist: none flagged
- glassRim (var) — OffshoreBudgeting/Views/CardTileView.swift:443
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:443
  Def: var glassRim: Color {
  Dynamic-Risk Checklist: none flagged
- rimBase (let) — OffshoreBudgeting/Views/CardTileView.swift:444
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:444
  Def: let rimBase = themeManager.selectedTheme.glassPalette.rim
  Dynamic-Risk Checklist: none flagged
- rimTint (let) — OffshoreBudgeting/Views/CardTileView.swift:445
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:445
  Def: let rimTint = adjustedColor(glassThemeTint, brightnessDelta: 0.04, saturationDelta: -0.04)
  Dynamic-Risk Checklist: none flagged
- glassTintOpacityScale (var) — OffshoreBudgeting/Views/CardTileView.swift:451
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:451
  Def: var glassTintOpacityScale: Double {
  Dynamic-Risk Checklist: none flagged
- glassTintOverlayOpacity (func) — OffshoreBudgeting/Views/CardTileView.swift:455
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:455
  Def: func glassTintOverlayOpacity(for size: CGSize) -> Double {
  Dynamic-Risk Checklist: none flagged
- glassBaseSaturation (var) — OffshoreBudgeting/Views/CardTileView.swift:462
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:462
  Def: var glassBaseSaturation: Double {
  Dynamic-Risk Checklist: none flagged
- glassBaseBrightness (var) — OffshoreBudgeting/Views/CardTileView.swift:466
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:466
  Def: var glassBaseBrightness: Double {
  Dynamic-Risk Checklist: none flagged
- glassSpecularOverlay (func) — OffshoreBudgeting/Views/CardTileView.swift:470
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:470
  Def: func glassSpecularOverlay(for size: CGSize) -> LinearGradient {
  Dynamic-Risk Checklist: none flagged
- glassSpecularSecondaryOverlay (func) — OffshoreBudgeting/Views/CardTileView.swift:490
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:490
  Def: func glassSpecularSecondaryOverlay(for size: CGSize) -> LinearGradient {
  Dynamic-Risk Checklist: none flagged
- glassSpecularAnglePrimary (var) — OffshoreBudgeting/Views/CardTileView.swift:510
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:510
  Def: var glassSpecularAnglePrimary: Angle {
  Dynamic-Risk Checklist: none flagged
- glassSpecularAngleSecondary (var) — OffshoreBudgeting/Views/CardTileView.swift:514
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:514
  Def: var glassSpecularAngleSecondary: Angle {
  Dynamic-Risk Checklist: none flagged
- glassSpecularShift (func) — OffshoreBudgeting/Views/CardTileView.swift:518
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:518
  Def: func glassSpecularShift(for size: CGSize) -> CGSize {
  Dynamic-Risk Checklist: none flagged
- glassFallbackStyle (var) — OffshoreBudgeting/Views/CardTileView.swift:531
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:531
  Def: var glassFallbackStyle: AnyShapeStyle {
  Dynamic-Risk Checklist: none flagged
- plasticOverlayColor (func) — OffshoreBudgeting/Views/CardTileView.swift:540
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:540
  Def: func plasticOverlayColor(for size: CGSize) -> Color {
  Dynamic-Risk Checklist: none flagged
- holographicOverlayColor (func) — OffshoreBudgeting/Views/CardTileView.swift:549
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:549
  Def: func holographicOverlayColor(for size: CGSize) -> Color {
  Dynamic-Risk Checklist: none flagged
- plasticGradient (func) — OffshoreBudgeting/Views/CardTileView.swift:558
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:558
  Def: func plasticGradient(for size: CGSize) -> LinearGradient {
  Dynamic-Risk Checklist: none flagged
- holographicGradient (func) — OffshoreBudgeting/Views/CardTileView.swift:578
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:578
  Def: func holographicGradient(for size: CGSize) -> LinearGradient {
  Dynamic-Risk Checklist: none flagged
- holographicFoilOverlay (func) — OffshoreBudgeting/Views/CardTileView.swift:621
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:621
  Def: func holographicFoilOverlay(for size: CGSize) -> LinearGradient {
  Dynamic-Risk Checklist: none flagged
- holographicFoilOverlayOpacity (func) — OffshoreBudgeting/Views/CardTileView.swift:651
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:651
  Def: func holographicFoilOverlayOpacity(for size: CGSize) -> Double {
  Dynamic-Risk Checklist: none flagged
- holographicRainbowOverlay (func) — OffshoreBudgeting/Views/CardTileView.swift:658
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:658
  Def: func holographicRainbowOverlay(for size: CGSize) -> RadialGradient {
  Dynamic-Risk Checklist: none flagged
- holographicRainbowOverlayOpacity (func) — OffshoreBudgeting/Views/CardTileView.swift:673
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:673
  Def: func holographicRainbowOverlayOpacity(for size: CGSize) -> Double {
  Dynamic-Risk Checklist: none flagged
- holographicRainbowStops (func) — OffshoreBudgeting/Views/CardTileView.swift:680
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:680
  Def: func holographicRainbowStops(base: Color) -> [Gradient.Stop] {
  Dynamic-Risk Checklist: none flagged
- holographicRingMetrics (func) — OffshoreBudgeting/Views/CardTileView.swift:701
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:701
  Def: func holographicRingMetrics(for size: CGSize) -> (inset: CGFloat, thickness: CGFloat) {
  Dynamic-Risk Checklist: none flagged
- holographicRingRimOpacity (func) — OffshoreBudgeting/Views/CardTileView.swift:708
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:708
  Def: func holographicRingRimOpacity(for size: CGSize) -> Double {
  Dynamic-Risk Checklist: none flagged
- holographicRingFillOpacity (func) — OffshoreBudgeting/Views/CardTileView.swift:715
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:715
  Def: func holographicRingFillOpacity(for size: CGSize) -> Double {
  Dynamic-Risk Checklist: none flagged
- metalGradient (var) — OffshoreBudgeting/Views/CardTileView.swift:722
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:722
  Def: var metalGradient: LinearGradient {
  Dynamic-Risk Checklist: none flagged
- metalBrushColor (var) — OffshoreBudgeting/Views/CardTileView.swift:735
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:735
  Def: var metalBrushColor: Color {
  Dynamic-Risk Checklist: none flagged
- neutral (let) — OffshoreBudgeting/Views/CardTileView.swift:742
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:742
  Def: let neutral = colorScheme == .dark ? Color(white: 0.22) : Color(white: 0.90)
  Dynamic-Risk Checklist: none flagged
- metalHighlightColor (var) — OffshoreBudgeting/Views/CardTileView.swift:746
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:746
  Def: var metalHighlightColor: Color {
  Dynamic-Risk Checklist: none flagged
- metalShadowColor (var) — OffshoreBudgeting/Views/CardTileView.swift:750
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:750
  Def: var metalShadowColor: Color {
  Dynamic-Risk Checklist: none flagged
- metalBandHighlight (var) — OffshoreBudgeting/Views/CardTileView.swift:754
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:754
  Def: var metalBandHighlight: Color {
  Dynamic-Risk Checklist: none flagged
- metalBandShadow (var) — OffshoreBudgeting/Views/CardTileView.swift:758
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:758
  Def: var metalBandShadow: Color {
  Dynamic-Risk Checklist: none flagged
- materialGradient (func) — OffshoreBudgeting/Views/CardTileView.swift:762
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:762
  Def: func materialGradient(angle: Angle, shift: CGSize, stops: [Gradient.Stop], length: Double = 0.7) -> LinearGradient {
  Dynamic-Risk Checklist: none flagged
- rgbaComponents (func) — OffshoreBudgeting/Views/CardTileView.swift:794
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:794
  Def: func rgbaComponents(from color: Color) -> (Double, Double, Double, Double)? {
  Dynamic-Risk Checklist: none flagged
- hsbaComponents (func) — OffshoreBudgeting/Views/CardTileView.swift:804
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:804
  Def: func hsbaComponents(from color: Color) -> (Double, Double, Double, Double)? {
  Dynamic-Risk Checklist: none flagged
- plasticAngle (var) — OffshoreBudgeting/Views/CardTileView.swift:896
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:896
  Def: var plasticAngle: Angle {
  Dynamic-Risk Checklist: none flagged
- plasticShift (func) — OffshoreBudgeting/Views/CardTileView.swift:901
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:901
  Def: func plasticShift(for size: CGSize) -> CGSize {
  Dynamic-Risk Checklist: none flagged
- holographicAngle (var) — OffshoreBudgeting/Views/CardTileView.swift:911
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:911
  Def: var holographicAngle: Angle {
  Dynamic-Risk Checklist: none flagged
- holographicSecondaryAngle (var) — OffshoreBudgeting/Views/CardTileView.swift:915
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:915
  Def: var holographicSecondaryAngle: Angle {
  Dynamic-Risk Checklist: none flagged
- holographicShift (func) — OffshoreBudgeting/Views/CardTileView.swift:919
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:919
  Def: func holographicShift(for size: CGSize) -> CGSize {
  Dynamic-Risk Checklist: none flagged
- damped (let) — OffshoreBudgeting/Views/CardTileView.swift:925
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:925
  Def: let damped = pow(motionMagnitude, 1.8)
  Dynamic-Risk Checklist: none flagged
- holographicBandAttenuation (var) — OffshoreBudgeting/Views/CardTileView.swift:929
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:929
  Def: var holographicBandAttenuation: Double {
  Dynamic-Risk Checklist: none flagged
- holographicStopShift (func) — OffshoreBudgeting/Views/CardTileView.swift:939
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:939
  Def: func holographicStopShift(for size: CGSize) -> Double {
  Dynamic-Risk Checklist: none flagged
- holographicRainbowCenter (var) — OffshoreBudgeting/Views/CardTileView.swift:949
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:949
  Def: var holographicRainbowCenter: UnitPoint {
  Dynamic-Risk Checklist: none flagged
- holographicRainbowShift (var) — OffshoreBudgeting/Views/CardTileView.swift:957
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:957
  Def: var holographicRainbowShift: CGSize {
  Dynamic-Risk Checklist: none flagged
- metalAngle (var) — OffshoreBudgeting/Views/CardTileView.swift:964
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:964
  Def: var metalAngle: Angle {
  Dynamic-Risk Checklist: none flagged
- metalShift (var) — OffshoreBudgeting/Views/CardTileView.swift:969
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:969
  Def: var metalShift: CGSize {
  Dynamic-Risk Checklist: none flagged
- MetalBrushedLinesOverlay (struct) — OffshoreBudgeting/Views/CardTileView.swift:981
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:981
  Def: private struct MetalBrushedLinesOverlay: View {
  Dynamic-Risk Checklist: none flagged
- MetalAnisotropicBandingOverlay (struct) — OffshoreBudgeting/Views/CardTileView.swift:1005
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:1005
  Def: private struct MetalAnisotropicBandingOverlay: View {
  Dynamic-Risk Checklist: none flagged
- gap (let) — OffshoreBudgeting/Views/CardTileView.swift:1008
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardTileView.swift:1008
  Def: let gap: CGFloat
  Dynamic-Risk Checklist: none flagged
- CardsView (struct) — OffshoreBudgeting/Views/CardsView.swift:9
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardsView.swift:9
  Def: struct CardsView: View {
  Dynamic-Risk Checklist: none flagged
- isPresentingCardVariableExpense (var) — OffshoreBudgeting/Views/CardsView.swift:14
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardsView.swift:14
  Def: @State private var isPresentingCardVariableExpense = false
  Dynamic-Risk Checklist: none flagged
- detailCard (var) — OffshoreBudgeting/Views/CardsView.swift:15
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardsView.swift:15
  Def: @State private var detailCard: CardItem? = nil
  Dynamic-Risk Checklist: none flagged
- cardWidth (var) — OffshoreBudgeting/Views/CardsView.swift:22
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardsView.swift:22
  Def: @ScaledMetric(relativeTo: .body) private var cardWidth: CGFloat = 260
  Dynamic-Risk Checklist: none flagged
- cardHeight (var) — OffshoreBudgeting/Views/CardsView.swift:23
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardsView.swift:23
  Def: @ScaledMetric(relativeTo: .body) private var cardHeight: CGFloat = 160
  Dynamic-Risk Checklist: none flagged
- gridSpacing (var) — OffshoreBudgeting/Views/CardsView.swift:24
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardsView.swift:24
  Def: @ScaledMetric(relativeTo: .body) private var gridSpacing: CGFloat = 16
  Dynamic-Risk Checklist: none flagged
- gridPadding (var) — OffshoreBudgeting/Views/CardsView.swift:25
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardsView.swift:25
  Def: @ScaledMetric(relativeTo: .body) private var gridPadding: CGFloat = 16
  Dynamic-Risk Checklist: none flagged
- usesSingleColumn (var) — OffshoreBudgeting/Views/CardsView.swift:27
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardsView.swift:27
  Def: private var usesSingleColumn: Bool {
  Dynamic-Risk Checklist: none flagged
- availableGridWidth (var) — OffshoreBudgeting/Views/CardsView.swift:35
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardsView.swift:35
  Def: private var availableGridWidth: CGFloat {
  Dynamic-Risk Checklist: none flagged
- insets (let) — OffshoreBudgeting/Views/CardsView.swift:37
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardsView.swift:37
  Def: let insets = safeArea.leading + safeArea.trailing
  Dynamic-Risk Checklist: none flagged
- cardsContent (var) — OffshoreBudgeting/Views/CardsView.swift:61
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardsView.swift:61
  Def: private var cardsContent: some View {
  Dynamic-Risk Checklist: none flagged
- addButton (var) — OffshoreBudgeting/Views/CardsView.swift:175
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CardsView.swift:175
  Def: private var addButton: some View {
  Dynamic-Risk Checklist: none flagged
- fallbackStroke (let) — OffshoreBudgeting/Views/CategoryChipStyle.swift:15
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CategoryChipStyle.swift:15
  Def: let fallbackStroke: Stroke
  Dynamic-Risk Checklist: none flagged
- make (func) — OffshoreBudgeting/Views/CategoryChipStyle.swift:22
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CategoryChipStyle.swift:22
  Def: static func make(
  Dynamic-Risk Checklist: none flagged
- tintedColor (func) — OffshoreBudgeting/Views/CategoryChipStyle.swift:76
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CategoryChipStyle.swift:76
  Def: static func tintedColor(
  Dynamic-Risk Checklist: none flagged
- CloudSyncGateView (struct) — OffshoreBudgeting/Views/CloudSyncGateView.swift:6
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CloudSyncGateView.swift:6
  Def: struct CloudSyncGateView: View {
  Dynamic-Risk Checklist: none flagged
- uiTesting (var) — OffshoreBudgeting/Views/CloudSyncGateView.swift:8
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CloudSyncGateView.swift:8
  Def: @Environment(\.uiTestingFlags) private var uiTesting
  Dynamic-Risk Checklist: none flagged
- showFirstPrompt (var) — OffshoreBudgeting/Views/CloudSyncGateView.swift:18
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CloudSyncGateView.swift:18
  Def: @State private var showFirstPrompt: Bool = false
  Dynamic-Risk Checklist: none flagged
- scanningForExisting (var) — OffshoreBudgeting/Views/CloudSyncGateView.swift:19
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CloudSyncGateView.swift:19
  Def: @State private var scanningForExisting: Bool = false
  Dynamic-Risk Checklist: none flagged
- showExistingDataPrompt (var) — OffshoreBudgeting/Views/CloudSyncGateView.swift:20
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CloudSyncGateView.swift:20
  Def: @State private var showExistingDataPrompt: Bool = false
  Dynamic-Risk Checklist: none flagged
- existingDataFound (var) — OffshoreBudgeting/Views/CloudSyncGateView.swift:21
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CloudSyncGateView.swift:21
  Def: @State private var existingDataFound: Bool = false
  Dynamic-Risk Checklist: none flagged
- preparingWorkspace (var) — OffshoreBudgeting/Views/CloudSyncGateView.swift:22
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CloudSyncGateView.swift:22
  Def: @State private var preparingWorkspace: Bool = false
  Dynamic-Risk Checklist: none flagged
- preparingView (var) — OffshoreBudgeting/Views/CloudSyncGateView.swift:59
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CloudSyncGateView.swift:59
  Def: private var preparingView: some View {
  Dynamic-Risk Checklist: none flagged
- scanningView (var) — OffshoreBudgeting/Views/CloudSyncGateView.swift:67
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CloudSyncGateView.swift:67
  Def: private var scanningView: some View {
  Dynamic-Risk Checklist: none flagged
- presentIfNeeded (func) — OffshoreBudgeting/Views/CloudSyncGateView.swift:76
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CloudSyncGateView.swift:76
  Def: private func presentIfNeeded() {
  Dynamic-Risk Checklist: none flagged
- declineCloudThenOnboard (func) — OffshoreBudgeting/Views/CloudSyncGateView.swift:94
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CloudSyncGateView.swift:94
  Def: private func declineCloudThenOnboard() {
  Dynamic-Risk Checklist: none flagged
- enableAndProbeForExistingData (func) — OffshoreBudgeting/Views/CloudSyncGateView.swift:105
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CloudSyncGateView.swift:105
  Def: private func enableAndProbeForExistingData() {
  Dynamic-Risk Checklist: none flagged
- proceedWithLocalScan (func) — OffshoreBudgeting/Views/CloudSyncGateView.swift:130
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CloudSyncGateView.swift:130
  Def: private func proceedWithLocalScan() {
  Dynamic-Risk Checklist: none flagged
- useExistingDataAndSkipOnboarding (func) — OffshoreBudgeting/Views/CloudSyncGateView.swift:152
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CloudSyncGateView.swift:152
  Def: private func useExistingDataAndSkipOnboarding() {
  Dynamic-Risk Checklist: none flagged
- startFreshLocalOnboarding (func) — OffshoreBudgeting/Views/CloudSyncGateView.swift:162
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CloudSyncGateView.swift:162
  Def: private func startFreshLocalOnboarding() {
  Dynamic-Risk Checklist: none flagged
- BudgetCategoryChipView (struct) — OffshoreBudgeting/Views/Components/BudgetCategoryChipView.swift:6
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/BudgetCategoryChipView.swift:6
  Def: struct BudgetCategoryChipView: View {
  Dynamic-Risk Checklist: none flagged
- isExceeded (let) — OffshoreBudgeting/Views/Components/BudgetCategoryChipView.swift:11
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/BudgetCategoryChipView.swift:11
  Def: let isExceeded: Bool
  Dynamic-Risk Checklist: none flagged
- chipLabel (let) — OffshoreBudgeting/Views/Components/BudgetCategoryChipView.swift:18
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/BudgetCategoryChipView.swift:18
  Def: let chipLabel = HStack(spacing: 8) {
  Dynamic-Risk Checklist: none flagged
- BudgetExpenseSegmentedControl (struct) — OffshoreBudgeting/Views/Components/BudgetFilterControls.swift:3
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/BudgetFilterControls.swift:3
  Def: struct BudgetExpenseSegmentedControl<Segment: Hashable>: View {
  Dynamic-Risk Checklist: none flagged
- plannedSegment (let) — OffshoreBudgeting/Views/Components/BudgetFilterControls.swift:4
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/BudgetFilterControls.swift:4
  Def: let plannedSegment: Segment
  Dynamic-Risk Checklist: none flagged
- variableSegment (let) — OffshoreBudgeting/Views/Components/BudgetFilterControls.swift:5
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/BudgetFilterControls.swift:5
  Def: let variableSegment: Segment
  Dynamic-Risk Checklist: none flagged
- BudgetSortBar (struct) — OffshoreBudgeting/Views/Components/BudgetFilterControls.swift:17
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/BudgetFilterControls.swift:17
  Def: struct BudgetSortBar<Sort: Hashable>: View {
  Dynamic-Risk Checklist: none flagged
- toolbarIconGlassPreferred (func) — OffshoreBudgeting/Views/Components/Buttons.swift:85
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/Buttons.swift:85
  Def: static func toolbarIconGlassPreferred(
  Dynamic-Risk Checklist: none flagged
- toolbarIconGlassPreferred (func) — OffshoreBudgeting/Views/Components/Buttons.swift:113
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/Buttons.swift:113
  Def: static func toolbarIconGlassPreferred(
  Dynamic-Risk Checklist: none flagged
- CalendarNavigationButtonStyle (struct) — OffshoreBudgeting/Views/Components/CalendarNavigationButtonStyle.swift:6
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/CalendarNavigationButtonStyle.swift:6
  Def: struct CalendarNavigationButtonStyle: ButtonStyle {
  Dynamic-Risk Checklist: none flagged
- makeBody (func) — OffshoreBudgeting/Views/Components/CalendarNavigationButtonStyle.swift:7
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/CalendarNavigationButtonStyle.swift:7
  Def: func makeBody(configuration: Configuration) -> some View {
  Dynamic-Risk Checklist: none flagged
- progressWidth (var) — OffshoreBudgeting/Views/Components/CategoryAvailabilityRow.swift:8
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/CategoryAvailabilityRow.swift:8
  Def: @ScaledMetric(relativeTo: .body) private var progressWidth: CGFloat = 120
  Dynamic-Risk Checklist: none flagged
- useStackedLayout (var) — OffshoreBudgeting/Views/Components/CategoryAvailabilityRow.swift:11
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/CategoryAvailabilityRow.swift:11
  Def: private var useStackedLayout: Bool {
  Dynamic-Risk Checklist: none flagged
- progressTotal (let) — OffshoreBudgeting/Views/Components/CategoryAvailabilityRow.swift:22
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/CategoryAvailabilityRow.swift:22
  Def: let progressTotal: Double = {
  Dynamic-Risk Checklist: none flagged
- CategoryChipPill (struct) — OffshoreBudgeting/Views/Components/CategoryChipPill.swift:5
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/CategoryChipPill.swift:5
  Def: struct CategoryChipPill<Label: View>: View {
  Dynamic-Risk Checklist: none flagged
- textColor (var) — OffshoreBudgeting/Views/Components/CategoryChipPill.swift:50
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/CategoryChipPill.swift:50
  Def: private var textColor: Color {
  Dynamic-Risk Checklist: none flagged
- backgroundView (var) — OffshoreBudgeting/Views/Components/CategoryChipPill.swift:58
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/CategoryChipPill.swift:58
  Def: private var backgroundView: some View {
  Dynamic-Risk Checklist: none flagged
- overlayView (var) — OffshoreBudgeting/Views/Components/CategoryChipPill.swift:70
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/CategoryChipPill.swift:70
  Def: private var overlayView: some View {
  Dynamic-Risk Checklist: none flagged
- GlassCTAButton (struct) — OffshoreBudgeting/Views/Components/GlassCTAButton.swift:7
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/GlassCTAButton.swift:7
  Def: struct GlassCTAButton<Label: View>: View {
  Dynamic-Risk Checklist: none flagged
- labelBuilder (let) — OffshoreBudgeting/Views/Components/GlassCTAButton.swift:16
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/GlassCTAButton.swift:16
  Def: private let labelBuilder: () -> Label
  Dynamic-Risk Checklist: none flagged
- legacyButton (func) — OffshoreBudgeting/Views/Components/GlassCTAButton.swift:47
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/GlassCTAButton.swift:47
  Def: private func legacyButton() -> some View {
  Dynamic-Risk Checklist: none flagged
- glassButton (func) — OffshoreBudgeting/Views/Components/GlassCTAButton.swift:61
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/GlassCTAButton.swift:61
  Def: private func glassButton() -> some View {
  Dynamic-Risk Checklist: none flagged
- buttonLabel (func) — OffshoreBudgeting/Views/Components/GlassCTAButton.swift:80
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/GlassCTAButton.swift:80
  Def: private func buttonLabel() -> some View {
  Dynamic-Risk Checklist: none flagged
- glassLabelForeground (var) — OffshoreBudgeting/Views/Components/GlassCTAButton.swift:97
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/GlassCTAButton.swift:97
  Def: private var glassLabelForeground: Color {
  Dynamic-Risk Checklist: none flagged
- resolvedFallbackMetrics (var) — OffshoreBudgeting/Views/Components/GlassCTAButton.swift:101
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/GlassCTAButton.swift:101
  Def: private var resolvedFallbackMetrics: TranslucentButtonStyle.Metrics {
  Dynamic-Risk Checklist: none flagged
- resolvedMaxWidth (var) — OffshoreBudgeting/Views/Components/GlassCTAButton.swift:109
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/GlassCTAButton.swift:109
  Def: private var resolvedMaxWidth: CGFloat? {
  Dynamic-Risk Checklist: none flagged
- PillSegmentedControl (struct) — OffshoreBudgeting/Views/Components/PillSegmentedControl.swift:7
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/PillSegmentedControl.swift:7
  Def: struct PillSegmentedControl<SelectionValue, Content>: View where SelectionValue: Hashable, Content: View {
  Dynamic-Risk Checklist: none flagged
- segments (let) — OffshoreBudgeting/Views/Components/PillSegmentedControl.swift:13
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/PillSegmentedControl.swift:13
  Def: private let segments: [(tag: SelectionValue, label: AnyView)]
  Dynamic-Risk Checklist: none flagged
- extractSegments (func) — OffshoreBudgeting/Views/Components/PillSegmentedControl.swift:30
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/PillSegmentedControl.swift:30
  Def: static func extractSegments(from content: () -> Content) -> [(tag: SelectionValue, label: AnyView)] {
  Dynamic-Risk Checklist: none flagged
- UBPresentationDetent (enum) — OffshoreBudgeting/Views/Components/SheetDetentsCompat.swift:12
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/SheetDetentsCompat.swift:12
  Def: enum UBPresentationDetent: Equatable, Hashable {
  Dynamic-Risk Checklist: none flagged
- systemDetent (var) — OffshoreBudgeting/Views/Components/SheetDetentsCompat.swift:18
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/SheetDetentsCompat.swift:18
  Def: var systemDetent: PresentationDetent {
  Dynamic-Risk Checklist: none flagged
- rootActionIcon (let) — OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:26
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:26
  Def: static let rootActionIcon = Metrics(
  Dynamic-Risk Checklist: none flagged
- rootActionLabel (let) — OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:37
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:37
  Def: static let rootActionLabel = Metrics(
  Dynamic-Risk Checklist: none flagged
- calendarNavigationIcon (let) — OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:48
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:48
  Def: static let calendarNavigationIcon = Metrics(
  Dynamic-Risk Checklist: none flagged
- calendarNavigationLabel (let) — OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:59
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:59
  Def: static let calendarNavigationLabel = Metrics(
  Dynamic-Risk Checklist: none flagged
- macNavigationControl (let) — OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:70
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:70
  Def: static let macNavigationControl = Metrics(
  Dynamic-Risk Checklist: none flagged
- macRootTab (func) — OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:82
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:82
  Def: static func macRootTab(for capabilities: PlatformCapabilities) -> Metrics { .macNavigationControl }
  Dynamic-Risk Checklist: none flagged
- makeBody (func) — OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:105
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:105
  Def: func makeBody(configuration: Configuration) -> some View {
  Dynamic-Risk Checklist: none flagged
- labelContent (func) — OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:141
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:141
  Def: private func labelContent(for configuration: Configuration, theme: AppTheme) -> some View {
  Dynamic-Risk Checklist: none flagged
- labelForeground (func) — OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:171
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:171
  Def: private func labelForeground(for theme: AppTheme) -> Color {
  Dynamic-Risk Checklist: none flagged
- legacyLabelForeground (func) — OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:175
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:175
  Def: private func legacyLabelForeground(for theme: AppTheme) -> Color {
  Dynamic-Risk Checklist: none flagged
- fillColor (func) — OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:202
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:202
  Def: private func fillColor(for theme: AppTheme, isPressed: Bool) -> Color {
  Dynamic-Risk Checklist: none flagged
- shadowRadius (func) — OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:222
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:222
  Def: private func shadowRadius(isPressed: Bool) -> CGFloat {
  Dynamic-Risk Checklist: none flagged
- shadowY (func) — OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:226
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:226
  Def: private func shadowY(isPressed: Bool) -> CGFloat {
  Dynamic-Risk Checklist: none flagged
- legacyShadowRadius (func) — OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:230
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:230
  Def: private func legacyShadowRadius(isPressed: Bool) -> CGFloat {
  Dynamic-Risk Checklist: none flagged
- legacyShadowY (func) — OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:234
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:234
  Def: private func legacyShadowY(isPressed: Bool) -> CGFloat {
  Dynamic-Risk Checklist: none flagged
- border (func) — OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:238
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:238
  Def: private func border(for theme: AppTheme, isPressed: Bool, radius: CGFloat) -> some View {
  Dynamic-Risk Checklist: none flagged
- glow (func) — OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:253
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:253
  Def: private func glow(for theme: AppTheme, radius: CGFloat, isPressed: Bool) -> some View {
  Dynamic-Risk Checklist: none flagged
- glowOpacity (func) — OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:269
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:269
  Def: private func glowOpacity(for theme: AppTheme, isPressed: Bool) -> Double {
  Dynamic-Risk Checklist: none flagged
- flatFillColor (func) — OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:274
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:274
  Def: private func flatFillColor(for theme: AppTheme, isPressed: Bool) -> Color {
  Dynamic-Risk Checklist: none flagged
- flatShadowColor (func) — OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:284
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:284
  Def: private func flatShadowColor(for theme: AppTheme, isPressed: Bool) -> Color {
  Dynamic-Risk Checklist: none flagged
- borderColor (func) — OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:293
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:293
  Def: private func borderColor(for theme: AppTheme, isPressed: Bool) -> Color {
  Dynamic-Risk Checklist: none flagged
- Unit (enum) — OffshoreBudgeting/Views/CustomRecurrenceEditorView.swift:17
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CustomRecurrenceEditorView.swift:17
  Def: enum Unit: String, CaseIterable, Identifiable {
  Dynamic-Risk Checklist: none flagged
- icsFreq (var) — OffshoreBudgeting/Views/CustomRecurrenceEditorView.swift:21
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CustomRecurrenceEditorView.swift:21
  Def: var icsFreq: String {
  Dynamic-Risk Checklist: none flagged
- selectedWeekdays (var) — OffshoreBudgeting/Views/CustomRecurrenceEditorView.swift:33
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CustomRecurrenceEditorView.swift:33
  Def: var selectedWeekdays: Set<Weekday> = [.monday, .wednesday, .friday]
  Dynamic-Risk Checklist: none flagged
- roughParse (func) — OffshoreBudgeting/Views/CustomRecurrenceEditorView.swift:49
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CustomRecurrenceEditorView.swift:49
  Def: static func roughParse(rruleString: String) -> CustomRecurrence {
  Dynamic-Risk Checklist: none flagged
- CustomRecurrenceEditorView (struct) — OffshoreBudgeting/Views/CustomRecurrenceEditorView.swift:75
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CustomRecurrenceEditorView.swift:75
  Def: struct CustomRecurrenceEditorView: View {
  Dynamic-Risk Checklist: none flagged
- WeekdayMultiPicker (struct) — OffshoreBudgeting/Views/CustomRecurrenceEditorView.swift:196
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CustomRecurrenceEditorView.swift:196
  Def: private struct WeekdayMultiPicker: View {
  Dynamic-Risk Checklist: none flagged
- applyCustomRecurrence (func) — OffshoreBudgeting/Views/CustomRecurrenceEditorView.swift:226
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/CustomRecurrenceEditorView.swift:226
  Def: func applyCustomRecurrence(_ custom: CustomRecurrence) {
  Dynamic-Risk Checklist: none flagged
- EditCategoryCapsView (struct) — OffshoreBudgeting/Views/EditCategoryCapsView.swift:6
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/EditCategoryCapsView.swift:6
  Def: struct EditCategoryCapsView: View {
  Dynamic-Risk Checklist: none flagged
- legacySafeAreaInsets (var) — OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:19
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:19
  Def: @Environment(\.ub_safeAreaInsets) private var legacySafeAreaInsets
  Dynamic-Risk Checklist: none flagged
- sortByName (let) — OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:23
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:23
  Def: private static let sortByName: [NSSortDescriptor] = [
  Dynamic-Risk Checklist: none flagged
- addSheetInstanceID (var) — OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:37
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:37
  Def: @State private var addSheetInstanceID = UUID()
  Dynamic-Risk Checklist: none flagged
- categoryToEdit (var) — OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:38
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:38
  Def: @State private var categoryToEdit: ExpenseCategory?
  Dynamic-Risk Checklist: none flagged
- categoryToDelete (var) — OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:39
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:39
  Def: @State private var categoryToDelete: ExpenseCategory?
  Dynamic-Risk Checklist: none flagged
- counts (let) — OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:121
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:121
  Def: let counts = usageCounts(for: cat)
  Dynamic-Risk Checklist: none flagged
- groupedListContent (var) — OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:147
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:147
  Def: private var groupedListContent: some View {
  Dynamic-Risk Checklist: none flagged
- categoryRow (func) — OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:198
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:198
  Def: private func categoryRow(for category: ExpenseCategory, swipeConfig: UnifiedSwipeConfig) -> some View {
  Dynamic-Risk Checklist: none flagged
- rowLabel (func) — OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:217
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:217
  Def: private func rowLabel(for category: ExpenseCategory) -> some View {
  Dynamic-Risk Checklist: none flagged
- addCategory (func) — OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:236
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:236
  Def: private func addCategory(name: String, hex: String) {
  Dynamic-Risk Checklist: none flagged
- deleteCategory (func) — OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:245
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:245
  Def: private func deleteCategory(_ cat: ExpenseCategory) {
  Dynamic-Risk Checklist: none flagged
- usageCounts (func) — OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:262
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:262
  Def: private func usageCounts(for category: ExpenseCategory) -> (planned: Int, unplanned: Int, total: Int) {
  Dynamic-Risk Checklist: none flagged
- CategoryRowView (struct) — OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:288
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:288
  Def: private struct CategoryRowView<Label: View>: View {
  Dynamic-Risk Checklist: none flagged
- applyIfAvailableScrollContentBackgroundHidden (func) — OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:314
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:314
  Def: func applyIfAvailableScrollContentBackgroundHidden() -> some View {
  Dynamic-Risk Checklist: none flagged
- forceDismissAnyPresentedControllerIfNeeded (func) — OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:431
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:431
  Def: private func forceDismissAnyPresentedControllerIfNeeded() {
  Dynamic-Risk Checklist: none flagged
- ColorCircle (struct) — OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:445
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:445
  Def: struct ColorCircle: View {
  Dynamic-Risk Checklist: none flagged
- DetentsForCategoryEditorCompat (struct) — OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:460
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:460
  Def: private struct DetentsForCategoryEditorCompat: ViewModifier {
  Dynamic-Risk Checklist: none flagged
- ExpenseImportView (struct) — OffshoreBudgeting/Views/ExpenseImportView.swift:12
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:12
  Def: struct ExpenseImportView: View {
  Dynamic-Risk Checklist: none flagged
- didApplyDefaultSelection (var) — OffshoreBudgeting/Views/ExpenseImportView.swift:21
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:21
  Def: @State private var didApplyDefaultSelection = false
  Dynamic-Risk Checklist: none flagged
- isPresentingAddCategory (var) — OffshoreBudgeting/Views/ExpenseImportView.swift:22
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:22
  Def: @State private var isPresentingAddCategory = false
  Dynamic-Risk Checklist: none flagged
- isPresentingAssignCategory (var) — OffshoreBudgeting/Views/ExpenseImportView.swift:23
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:23
  Def: @State private var isPresentingAssignCategory = false
  Dynamic-Risk Checklist: none flagged
- isShowingMissingCategoryAlert (var) — OffshoreBudgeting/Views/ExpenseImportView.swift:24
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:24
  Def: @State private var isShowingMissingCategoryAlert = false
  Dynamic-Risk Checklist: none flagged
- importError (var) — OffshoreBudgeting/Views/ExpenseImportView.swift:25
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:25
  Def: @State private var importError: ImportError?
  Dynamic-Risk Checklist: none flagged
- lastKnownSelection (var) — OffshoreBudgeting/Views/ExpenseImportView.swift:26
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:26
  Def: @State private var lastKnownSelection: Set<UUID> = []
  Dynamic-Risk Checklist: none flagged
- isReadyExpanded (var) — OffshoreBudgeting/Views/ExpenseImportView.swift:27
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:27
  Def: @State private var isReadyExpanded = true
  Dynamic-Risk Checklist: none flagged
- isPossibleExpanded (var) — OffshoreBudgeting/Views/ExpenseImportView.swift:28
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:28
  Def: @State private var isPossibleExpanded = true
  Dynamic-Risk Checklist: none flagged
- isDuplicatesExpanded (var) — OffshoreBudgeting/Views/ExpenseImportView.swift:29
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:29
  Def: @State private var isDuplicatesExpanded = true
  Dynamic-Risk Checklist: none flagged
- isNeedsExpanded (var) — OffshoreBudgeting/Views/ExpenseImportView.swift:30
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:30
  Def: @State private var isNeedsExpanded = true
  Dynamic-Risk Checklist: none flagged
- isPaymentsExpanded (var) — OffshoreBudgeting/Views/ExpenseImportView.swift:31
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:31
  Def: @State private var isPaymentsExpanded = true
  Dynamic-Risk Checklist: none flagged
- isCreditsExpanded (var) — OffshoreBudgeting/Views/ExpenseImportView.swift:32
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:32
  Def: @State private var isCreditsExpanded = true
  Dynamic-Risk Checklist: none flagged
- listContent (var) — OffshoreBudgeting/Views/ExpenseImportView.swift:128
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:128
  Def: private var listContent: some View {
  Dynamic-Risk Checklist: none flagged
- importRowView (func) — OffshoreBudgeting/Views/ExpenseImportView.swift:206
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:206
  Def: private func importRowView(_ row: Binding<ExpenseImportViewModel.ImportRow>, isSelectable: Bool) -> some View {
  Dynamic-Risk Checklist: none flagged
- importSelected (func) — OffshoreBudgeting/Views/ExpenseImportView.swift:330
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:330
  Def: private func importSelected() {
  Dynamic-Risk Checklist: none flagged
- selectAllEligible (func) — OffshoreBudgeting/Views/ExpenseImportView.swift:348
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:348
  Def: private func selectAllEligible() {
  Dynamic-Risk Checklist: none flagged
- pruneSelections (func) — OffshoreBudgeting/Views/ExpenseImportView.swift:352
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:352
  Def: private func pruneSelections() {
  Dynamic-Risk Checklist: none flagged
- applyDefaultSelectionIfNeeded (func) — OffshoreBudgeting/Views/ExpenseImportView.swift:356
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:356
  Def: private func applyDefaultSelectionIfNeeded() {
  Dynamic-Risk Checklist: none flagged
- cancelSelection (func) — OffshoreBudgeting/Views/ExpenseImportView.swift:363
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:363
  Def: private func cancelSelection() {
  Dynamic-Risk Checklist: none flagged
- sectionHeader (func) — OffshoreBudgeting/Views/ExpenseImportView.swift:368
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:368
  Def: private func sectionHeader(title: String, isExpanded: Binding<Bool>) -> some View {
  Dynamic-Risk Checklist: none flagged
- badgeRow (func) — OffshoreBudgeting/Views/ExpenseImportView.swift:383
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:383
  Def: private func badgeRow(for row: Binding<ExpenseImportViewModel.ImportRow>) -> some View {
  Dynamic-Risk Checklist: none flagged
- menuBadge (func) — OffshoreBudgeting/Views/ExpenseImportView.swift:411
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:411
  Def: private func menuBadge(text: String) -> some View {
  Dynamic-Risk Checklist: none flagged
- staticBadge (func) — OffshoreBudgeting/Views/ExpenseImportView.swift:424
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:424
  Def: private func staticBadge(text: String, accessibilityLabel: String) -> some View {
  Dynamic-Risk Checklist: none flagged
- kindLabel (func) — OffshoreBudgeting/Views/ExpenseImportView.swift:432
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:432
  Def: private func kindLabel(for kind: ExpenseImportViewModel.ImportKind) -> String {
  Dynamic-Risk Checklist: none flagged
- menuLabel (func) — OffshoreBudgeting/Views/ExpenseImportView.swift:441
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:441
  Def: private func menuLabel<Content: View>(content: Content) -> some View {
  Dynamic-Risk Checklist: none flagged
- toggleSelection (func) — OffshoreBudgeting/Views/ExpenseImportView.swift:465
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:465
  Def: private func toggleSelection(for id: UUID, isSelectable: Bool) {
  Dynamic-Risk Checklist: none flagged
- bindingDate (func) — OffshoreBudgeting/Views/ExpenseImportView.swift:479
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:479
  Def: private func bindingDate(for row: Binding<ExpenseImportViewModel.ImportRow>) -> Binding<Date> {
  Dynamic-Risk Checklist: none flagged
- CategoryPickerSheet (struct) — OffshoreBudgeting/Views/ExpenseImportView.swift:497
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:497
  Def: private struct CategoryPickerSheet: View {
  Dynamic-Risk Checklist: none flagged
- ub_menuButtonStyle (func) — OffshoreBudgeting/Views/ExpenseImportView.swift:537
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:537
  Def: func ub_menuButtonStyle() -> some View {
  Dynamic-Risk Checklist: none flagged
- applySelectionDisabledIfAvailable (func) — OffshoreBudgeting/Views/ExpenseImportView.swift:552
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:552
  Def: func applySelectionDisabledIfAvailable(_ disabled: Bool) -> some View {
  Dynamic-Risk Checklist: none flagged
- ImportError (struct) — OffshoreBudgeting/Views/ExpenseImportView.swift:562
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ExpenseImportView.swift:562
  Def: private struct ImportError: Identifiable {
  Dynamic-Risk Checklist: none flagged
- showOnboardingAlert (var) — OffshoreBudgeting/Views/HelpView.swift:10
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HelpView.swift:10
  Def: @State private var showOnboardingAlert = false
  Dynamic-Risk Checklist: none flagged
- helpMenu (var) — OffshoreBudgeting/Views/HelpView.swift:60
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HelpView.swift:60
  Def: private var helpMenu: some View {
  Dynamic-Risk Checklist: none flagged
- intro (var) — OffshoreBudgeting/Views/HelpView.swift:164
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HelpView.swift:164
  Def: private var intro: some View {
  Dynamic-Risk Checklist: none flagged
- repeatOnboardingButton (var) — OffshoreBudgeting/Views/HelpView.swift:465
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HelpView.swift:465
  Def: private var repeatOnboardingButton: some View {
  Dynamic-Risk Checklist: none flagged
- HelpView_Previews (struct) — OffshoreBudgeting/Views/HelpView.swift:509
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HelpView.swift:509
  Def: struct HelpView_Previews: PreviewProvider {
  Dynamic-Risk Checklist: none flagged
- previews (var) — OffshoreBudgeting/Views/HelpView.swift:510
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HelpView.swift:510
  Def: static var previews: some View {
  Dynamic-Risk Checklist: none flagged
- HelpIconStyle (enum) — OffshoreBudgeting/Views/HelpView.swift:516
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HelpView.swift:516
  Def: private enum HelpIconStyle {
  Dynamic-Risk Checklist: none flagged
- iconTextSpacing (var) — OffshoreBudgeting/Views/HelpView.swift:575
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HelpView.swift:575
  Def: @ScaledMetric(relativeTo: .body) private var iconTextSpacing: CGFloat = 16
  Dynamic-Risk Checklist: none flagged
- HelpIconTile (struct) — OffshoreBudgeting/Views/HelpView.swift:593
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HelpView.swift:593
  Def: private struct HelpIconTile: View {
  Dynamic-Risk Checklist: none flagged
- HelpDeviceFrame (enum) — OffshoreBudgeting/Views/HelpView.swift:617
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HelpView.swift:617
  Def: private enum HelpDeviceFrame: String, CaseIterable, Identifiable {
  Dynamic-Risk Checklist: none flagged
- sanitizedSection (let) — OffshoreBudgeting/Views/HelpView.swift:653
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HelpView.swift:653
  Def: let sanitizedSection = sectionTitle.replacingOccurrences(of: " ", with: "")
  Dynamic-Risk Checklist: none flagged
- resolvedDevice (var) — OffshoreBudgeting/Views/HelpView.swift:657
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HelpView.swift:657
  Def: private var resolvedDevice: HelpDeviceFrame {
  Dynamic-Risk Checklist: none flagged
- shouldUseLandscape (var) — OffshoreBudgeting/Views/HelpView.swift:669
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HelpView.swift:669
  Def: private var shouldUseLandscape: Bool {
  Dynamic-Risk Checklist: none flagged
- HelpScreenshotPlaceholder (struct) — OffshoreBudgeting/Views/HelpView.swift:689
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HelpView.swift:689
  Def: private struct HelpScreenshotPlaceholder: View {
  Dynamic-Risk Checklist: none flagged
- screenshotImage (var) — OffshoreBudgeting/Views/HelpView.swift:730
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HelpView.swift:730
  Def: private var screenshotImage: Image? {
  Dynamic-Risk Checklist: none flagged
- capDisplay (var) — OffshoreBudgeting/Views/HomeView.swift:62
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:62
  Def: var capDisplay: String { cap.map { CategoryAvailability.formatCurrencyStatic($0) } ?? "∞" }
  Dynamic-Risk Checklist: none flagged
- formatCurrencyStatic (func) — OffshoreBudgeting/Views/HomeView.swift:64
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:64
  Def: private static func formatCurrencyStatic(_ value: Double) -> String {
  Dynamic-Risk Checklist: none flagged
- WidgetSpanKey (struct) — OffshoreBudgeting/Views/HomeView.swift:98
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:98
  Def: private struct WidgetSpanKey: LayoutValueKey {
  Dynamic-Risk Checklist: none flagged
- WidgetGridLayout (struct) — OffshoreBudgeting/Views/HomeView.swift:103
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:103
  Def: private struct WidgetGridLayout: Layout {
  Dynamic-Risk Checklist: none flagged
- makeCache (func) — OffshoreBudgeting/Views/HomeView.swift:114
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:114
  Def: func makeCache(subviews: Subviews) -> Cache { Cache() }
  Dynamic-Risk Checklist: none flagged
- updateCache (func) — OffshoreBudgeting/Views/HomeView.swift:116
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:116
  Def: func updateCache(_ cache: inout Cache, for subviews: Subviews, proposal: ProposedViewSize) {
  Dynamic-Risk Checklist: none flagged
- sizeThatFits (func) — OffshoreBudgeting/Views/HomeView.swift:120
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:120
  Def: func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
  Dynamic-Risk Checklist: none flagged
- placeSubviews (func) — OffshoreBudgeting/Views/HomeView.swift:127
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:127
  Def: func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
  Dynamic-Risk Checklist: none flagged
- computeLayout (func) — OffshoreBudgeting/Views/HomeView.swift:140
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:140
  Def: private func computeLayout(subviews: Subviews, proposal: ProposedViewSize) -> Cache {
  Dynamic-Risk Checklist: none flagged
- weekdayRangeOverride (var) — OffshoreBudgeting/Views/HomeView.swift:221
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:221
  Def: @State private var weekdayRangeOverride: ClosedRange<Date>? = nil
  Dynamic-Risk Checklist: none flagged
- Sort (enum) — OffshoreBudgeting/Views/HomeView.swift:232
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:232
  Def: enum Sort: String, CaseIterable, Identifiable { case titleAZ, amountLowHigh, amountHighLow, dateOldNew, dateNewOld; var id: String { rawValue } }
  Dynamic-Risk Checklist: none flagged
- availabilitySegmentRawValue (var) — OffshoreBudgeting/Views/HomeView.swift:236
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:236
  Def: @AppStorage("homeAvailabilitySegment") private var availabilitySegmentRawValue: String = CategoryAvailabilitySegment.combined.rawValue
  Dynamic-Risk Checklist: none flagged
- syncHomeWidgetsAcrossDevices (var) — OffshoreBudgeting/Views/HomeView.swift:239
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:239
  Def: @AppStorage(AppSettingsKeys.syncHomeWidgetsAcrossDevices.rawValue) private var syncHomeWidgetsAcrossDevices: Bool = false
  Dynamic-Risk Checklist: none flagged
- defaultWidgets (let) — OffshoreBudgeting/Views/HomeView.swift:241
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:241
  Def: private static let defaultWidgets: [WidgetID] = [
  Dynamic-Risk Checklist: none flagged
- pinnedLocal (let) — OffshoreBudgeting/Views/HomeView.swift:246
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:246
  Def: static let pinnedLocal = "homePinnedWidgetIDs"
  Dynamic-Risk Checklist: none flagged
- pinnedCloud (let) — OffshoreBudgeting/Views/HomeView.swift:247
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:247
  Def: static let pinnedCloud = "homePinnedWidgetIDs.cloud"
  Dynamic-Risk Checklist: none flagged
- orderLocal (let) — OffshoreBudgeting/Views/HomeView.swift:248
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:248
  Def: static let orderLocal = "homeWidgetOrderIDs"
  Dynamic-Risk Checklist: none flagged
- orderCloud (let) — OffshoreBudgeting/Views/HomeView.swift:249
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:249
  Def: static let orderCloud = "homeWidgetOrderIDs.cloud"
  Dynamic-Risk Checklist: none flagged
- storageRefreshToken (var) — OffshoreBudgeting/Views/HomeView.swift:257
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:257
  Def: @State private var storageRefreshToken = UUID()
  Dynamic-Risk Checklist: none flagged
- gridSpacing (var) — OffshoreBudgeting/Views/HomeView.swift:259
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:259
  Def: @ScaledMetric(relativeTo: .body) private var gridSpacing: CGFloat = 18
  Dynamic-Risk Checklist: none flagged
- gridRowHeight (var) — OffshoreBudgeting/Views/HomeView.swift:260
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:260
  Def: @ScaledMetric(relativeTo: .body) private var gridRowHeight: CGFloat = 170
  Dynamic-Risk Checklist: none flagged
- availabilityRowHeight (var) — OffshoreBudgeting/Views/HomeView.swift:261
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:261
  Def: @ScaledMetric(relativeTo: .body) private var availabilityRowHeight: CGFloat = 64
  Dynamic-Risk Checklist: none flagged
- availabilityRowSpacing (var) — OffshoreBudgeting/Views/HomeView.swift:262
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:262
  Def: @ScaledMetric(relativeTo: .body) private var availabilityRowSpacing: CGFloat = 8
  Dynamic-Risk Checklist: none flagged
- availabilityTabPadding (var) — OffshoreBudgeting/Views/HomeView.swift:263
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:263
  Def: @ScaledMetric(relativeTo: .body) private var availabilityTabPadding: CGFloat = 12
  Dynamic-Risk Checklist: none flagged
- categorySpotlightHeight (var) — OffshoreBudgeting/Views/HomeView.swift:265
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:265
  Def: @ScaledMetric(relativeTo: .body) private var categorySpotlightHeight: CGFloat = 200
  Dynamic-Risk Checklist: none flagged
- dayOfWeekChartHeight (var) — OffshoreBudgeting/Views/HomeView.swift:266
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:266
  Def: @ScaledMetric(relativeTo: .body) private var dayOfWeekChartHeight: CGFloat = 140
  Dynamic-Risk Checklist: none flagged
- dayOfWeekRowHeight (var) — OffshoreBudgeting/Views/HomeView.swift:267
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:267
  Def: @ScaledMetric(relativeTo: .body) private var dayOfWeekRowHeight: CGFloat = 24
  Dynamic-Risk Checklist: none flagged
- dayOfWeekRowSpacing (var) — OffshoreBudgeting/Views/HomeView.swift:268
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:268
  Def: @ScaledMetric(relativeTo: .body) private var dayOfWeekRowSpacing: CGFloat = 8
  Dynamic-Risk Checklist: none flagged
- cardWidgetMaxWidth (var) — OffshoreBudgeting/Views/HomeView.swift:270
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:270
  Def: @ScaledMetric(relativeTo: .body) private var cardWidgetMaxWidth: CGFloat = 360
  Dynamic-Risk Checklist: none flagged
- cardPreviewHeight (var) — OffshoreBudgeting/Views/HomeView.swift:272
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:272
  Def: @ScaledMetric(relativeTo: .body) private var cardPreviewHeight: CGFloat = 76
  Dynamic-Risk Checklist: none flagged
- isCompactDateRow (var) — OffshoreBudgeting/Views/HomeView.swift:274
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:274
  Def: private var isCompactDateRow: Bool {
  Dynamic-Risk Checklist: none flagged
- isLargeText (var) — OffshoreBudgeting/Views/HomeView.swift:282
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:282
  Def: private var isLargeText: Bool {
  Dynamic-Risk Checklist: none flagged
- columnCount (var) — OffshoreBudgeting/Views/HomeView.swift:294
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:294
  Def: private var columnCount: Int {
  Dynamic-Risk Checklist: none flagged
- availabilitySegment (var) — OffshoreBudgeting/Views/HomeView.swift:310
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:310
  Def: private var availabilitySegment: CategoryAvailabilitySegment {
  Dynamic-Risk Checklist: none flagged
- availabilitySegmentBinding (var) — OffshoreBudgeting/Views/HomeView.swift:313
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:313
  Def: private var availabilitySegmentBinding: Binding<CategoryAvailabilitySegment> {
  Dynamic-Risk Checklist: none flagged
- decodeScenarioAllocations (func) — OffshoreBudgeting/Views/HomeView.swift:322
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:322
  Def: private func decodeScenarioAllocations(from raw: String) -> [String: Double] {
  Dynamic-Risk Checklist: none flagged
- cardWidgets (var) — OffshoreBudgeting/Views/HomeView.swift:334
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:334
  Def: @State private var cardWidgets: [CardItem] = []
  Dynamic-Risk Checklist: none flagged
- baseTitleColor (var) — OffshoreBudgeting/Views/HomeView.swift:348
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:348
  Def: var baseTitleColor: Color {
  Dynamic-Risk Checklist: none flagged
- highContrastTitleColor (var) — OffshoreBudgeting/Views/HomeView.swift:363
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:363
  Def: var highContrastTitleColor: Color {
  Dynamic-Risk Checklist: none flagged
- HomeMetricRoute (struct) — OffshoreBudgeting/Views/HomeView.swift:368
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:368
  Def: private struct HomeMetricRoute: Hashable {
  Dynamic-Risk Checklist: none flagged
- NextPlannedRoute (struct) — OffshoreBudgeting/Views/HomeView.swift:374
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:374
  Def: private struct NextPlannedRoute: Hashable {
  Dynamic-Risk Checklist: none flagged
- fromStorage (func) — OffshoreBudgeting/Views/HomeView.swift:405
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:405
  Def: static func fromStorage(_ raw: String) -> WidgetID? {
  Dynamic-Risk Checklist: none flagged
- hash (func) — OffshoreBudgeting/Views/HomeView.swift:437
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:437
  Def: func hash(into hasher: inout Hasher) {
  Dynamic-Risk Checklist: none flagged
- whatsNewVersionToken (var) — OffshoreBudgeting/Views/HomeView.swift:442
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:442
  Def: private var whatsNewVersionToken: String? {
  Dynamic-Risk Checklist: none flagged
- topCategory (let) — OffshoreBudgeting/Views/HomeView.swift:478
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:478
  Def: let topCategory = summary.categoryBreakdown.first ?? summary.plannedCategoryBreakdown.first ?? summary.categoryBreakdown.first
  Dynamic-Risk Checklist: none flagged
- contentSections (var) — OffshoreBudgeting/Views/HomeView.swift:513
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:513
  Def: private var contentSections: some View {
  Dynamic-Risk Checklist: none flagged
- listContent (var) — OffshoreBudgeting/Views/HomeView.swift:548
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:548
  Def: private var listContent: some View {
  Dynamic-Risk Checklist: none flagged
- listBody (var) — OffshoreBudgeting/Views/HomeView.swift:557
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:557
  Def: private var listBody: some View {
  Dynamic-Risk Checklist: none flagged
- dateRow (var) — OffshoreBudgeting/Views/HomeView.swift:573
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:573
  Def: private var dateRow: some View {
  Dynamic-Risk Checklist: none flagged
- applyDisabled (let) — OffshoreBudgeting/Views/HomeView.swift:574
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:574
  Def: let applyDisabled = startDateSelection > endDateSelection
  Dynamic-Risk Checklist: none flagged
- useCompactLayout (let) — OffshoreBudgeting/Views/HomeView.swift:575
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:575
  Def: let useCompactLayout = isCompactDateRow || isAccessibilitySize
  Dynamic-Risk Checklist: none flagged
- controls (let) — OffshoreBudgeting/Views/HomeView.swift:581
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:581
  Def: let controls = dateRowControls(disabled: applyDisabled, compactLayout: useCompactLayout)
  Dynamic-Risk Checklist: none flagged
- dateRowControls (func) — OffshoreBudgeting/Views/HomeView.swift:604
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:604
  Def: private func dateRowControls(disabled: Bool, compactLayout: Bool) -> some View {
  Dynamic-Risk Checklist: none flagged
- datePickerRow (func) — OffshoreBudgeting/Views/HomeView.swift:666
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:666
  Def: private func datePickerRow(title: String, selection: Binding<Date>) -> some View {
  Dynamic-Risk Checklist: none flagged
- glassRowBackground (var) — OffshoreBudgeting/Views/HomeView.swift:685
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:685
  Def: private var glassRowBackground: some View {
  Dynamic-Risk Checklist: none flagged
- widgetListSections (func) — OffshoreBudgeting/Views/HomeView.swift:707
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:707
  Def: private func widgetListSections(for summary: BudgetSummary) -> some View {
  Dynamic-Risk Checklist: none flagged
- widgetsHeader (var) — OffshoreBudgeting/Views/HomeView.swift:764
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:764
  Def: private var widgetsHeader: some View {
  Dynamic-Risk Checklist: none flagged
- editWidgetsButton (var) — OffshoreBudgeting/Views/HomeView.swift:787
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:787
  Def: private var editWidgetsButton: some View {
  Dynamic-Risk Checklist: none flagged
- incomeWidget (func) — OffshoreBudgeting/Views/HomeView.swift:827
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:827
  Def: private func incomeWidget(for summary: BudgetSummary) -> some View {
  Dynamic-Risk Checklist: none flagged
- expenseRatioWidget (func) — OffshoreBudgeting/Views/HomeView.swift:868
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:868
  Def: private func expenseRatioWidget(for summary: BudgetSummary) -> some View {
  Dynamic-Risk Checklist: none flagged
- savingsWidget (func) — OffshoreBudgeting/Views/HomeView.swift:921
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:921
  Def: private func savingsWidget(for summary: BudgetSummary) -> some View {
  Dynamic-Risk Checklist: none flagged
- nextPlannedExpenseWidget (func) — OffshoreBudgeting/Views/HomeView.swift:1008
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1008
  Def: private func nextPlannedExpenseWidget(for summary: BudgetSummary) -> some View {
  Dynamic-Risk Checklist: none flagged
- detachedCardItem (func) — OffshoreBudgeting/Views/HomeView.swift:1039
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1039
  Def: private func detachedCardItem(from card: Card?) -> CardItem? {
  Dynamic-Risk Checklist: none flagged
- categorySpotlightWidget (func) — OffshoreBudgeting/Views/HomeView.swift:1044
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1044
  Def: private func categorySpotlightWidget(for summary: BudgetSummary) -> some View {
  Dynamic-Risk Checklist: none flagged
- cardWidget (func) — OffshoreBudgeting/Views/HomeView.swift:1076
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1076
  Def: private func cardWidget(card: CardItem, summary: BudgetSummary) -> some View {
  Dynamic-Risk Checklist: none flagged
- weekdayWidget (func) — OffshoreBudgeting/Views/HomeView.swift:1100
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1100
  Def: private func weekdayWidget(for summary: BudgetSummary) -> some View {
  Dynamic-Risk Checklist: none flagged
- previewBarOrientation (func) — OffshoreBudgeting/Views/HomeView.swift:1139
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1139
  Def: private func previewBarOrientation(for period: BudgetPeriod, bucketCount: Int) -> SpendBarOrientation {
  Dynamic-Risk Checklist: none flagged
- SpendBucketChart (struct) — OffshoreBudgeting/Views/HomeView.swift:1147
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1147
  Def: private struct SpendBucketChart: View {
  Dynamic-Risk Checklist: none flagged
- labelWidthAccessibility (var) — OffshoreBudgeting/Views/HomeView.swift:1156
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1156
  Def: @ScaledMetric(relativeTo: .body) private var labelWidthAccessibility: CGFloat = 84
  Dynamic-Risk Checklist: none flagged
- minRowHeight (var) — OffshoreBudgeting/Views/HomeView.swift:1157
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1157
  Def: @ScaledMetric(relativeTo: .body) private var minRowHeight: CGFloat = 14
  Dynamic-Risk Checklist: none flagged
- minBarWidth (var) — OffshoreBudgeting/Views/HomeView.swift:1158
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1158
  Def: @ScaledMetric(relativeTo: .body) private var minBarWidth: CGFloat = 10
  Dynamic-Risk Checklist: none flagged
- labelHeight (var) — OffshoreBudgeting/Views/HomeView.swift:1159
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1159
  Def: @ScaledMetric(relativeTo: .body) private var labelHeight: CGFloat = 16
  Dynamic-Risk Checklist: none flagged
- minBarAreaHeight (var) — OffshoreBudgeting/Views/HomeView.swift:1160
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1160
  Def: @ScaledMetric(relativeTo: .body) private var minBarAreaHeight: CGFloat = 60
  Dynamic-Risk Checklist: none flagged
- baseLabelWidth (let) — OffshoreBudgeting/Views/HomeView.swift:1166
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1166
  Def: let baseLabelWidth = dynamicTypeSize.isAccessibilitySize ? labelWidthAccessibility : labelWidth
  Dynamic-Risk Checklist: none flagged
- resolvedLabelWidth (let) — OffshoreBudgeting/Views/HomeView.swift:1167
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1167
  Def: let resolvedLabelWidth = dynamicTypeSize.isAccessibilitySize
  Dynamic-Risk Checklist: none flagged
- minLabelHeight (let) — OffshoreBudgeting/Views/HomeView.swift:1171
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1171
  Def: let minLabelHeight = labelHeight * (dynamicTypeSize.isAccessibilitySize ? 2 : 1)
  Dynamic-Risk Checklist: none flagged
- barMaxWidth (let) — OffshoreBudgeting/Views/HomeView.swift:1173
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1173
  Def: let barMaxWidth = max(geo.size.width - resolvedLabelWidth - 8, 20)
  Dynamic-Risk Checklist: none flagged
- barWidth (let) — OffshoreBudgeting/Views/HomeView.swift:1200
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1200
  Def: let barWidth = max((geo.size.width - spacing * CGFloat(count - 1)) / CGFloat(count), minBarWidth)
  Dynamic-Risk Checklist: none flagged
- barAreaHeight (let) — OffshoreBudgeting/Views/HomeView.swift:1201
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1201
  Def: let barAreaHeight = max(minBarAreaHeight, geo.size.height - labelHeight)
  Dynamic-Risk Checklist: none flagged
- displayLabel (func) — OffshoreBudgeting/Views/HomeView.swift:1229
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1229
  Def: private func displayLabel(_ label: String, period: BudgetPeriod) -> String {
  Dynamic-Risk Checklist: none flagged
- widgetItems (func) — OffshoreBudgeting/Views/HomeView.swift:1238
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1238
  Def: private func widgetItems(for summary: BudgetSummary) -> [WidgetItem] {
  Dynamic-Risk Checklist: none flagged
- orderedVisibleItems (func) — OffshoreBudgeting/Views/HomeView.swift:1266
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1266
  Def: private func orderedVisibleItems(from items: [WidgetItem]) -> [WidgetItem] {
  Dynamic-Risk Checklist: none flagged
- widgetCell (func) — OffshoreBudgeting/Views/HomeView.swift:1278
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1278
  Def: private func widgetCell(for item: WidgetItem) -> some View {
  Dynamic-Risk Checklist: none flagged
- pinToggle (func) — OffshoreBudgeting/Views/HomeView.swift:1302
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1302
  Def: private func pinToggle(for id: WidgetID, title: String, isPinned: Bool) -> some View {
  Dynamic-Risk Checklist: none flagged
- pinWidget (func) — OffshoreBudgeting/Views/HomeView.swift:1321
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1321
  Def: private func pinWidget(_ id: WidgetID) {
  Dynamic-Risk Checklist: none flagged
- unpinWidget (func) — OffshoreBudgeting/Views/HomeView.swift:1332
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1332
  Def: private func unpinWidget(_ id: WidgetID) {
  Dynamic-Risk Checklist: none flagged
- initializeLayoutStateIfNeeded (func) — OffshoreBudgeting/Views/HomeView.swift:1337
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1337
  Def: private func initializeLayoutStateIfNeeded(with items: [WidgetItem]) {
  Dynamic-Risk Checklist: none flagged
- decodeIDs (func) — OffshoreBudgeting/Views/HomeView.swift:1399
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1399
  Def: private func decodeIDs(from raw: String) -> [WidgetID] {
  Dynamic-Risk Checklist: none flagged
- encodeIDs (func) — OffshoreBudgeting/Views/HomeView.swift:1405
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1405
  Def: private func encodeIDs(_ ids: [WidgetID]) -> String {
  Dynamic-Risk Checklist: none flagged
- loadSyncedString (func) — OffshoreBudgeting/Views/HomeView.swift:1436
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1436
  Def: private func loadSyncedString(localKey: String, cloudKey: String) -> String {
  Dynamic-Risk Checklist: none flagged
- syncWidgetStorageIfNeeded (func) — OffshoreBudgeting/Views/HomeView.swift:1455
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1455
  Def: private func syncWidgetStorageIfNeeded(_ value: String, cloudKey: String) {
  Dynamic-Risk Checklist: none flagged
- handleWidgetSyncPreferenceChange (func) — OffshoreBudgeting/Views/HomeView.swift:1462
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1462
  Def: private func handleWidgetSyncPreferenceChange() {
  Dynamic-Risk Checklist: none flagged
- WidgetDropDelegate (struct) — OffshoreBudgeting/Views/HomeView.swift:1491
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1491
  Def: private struct WidgetDropDelegate: DropDelegate {
  Dynamic-Risk Checklist: none flagged
- persist (let) — OffshoreBudgeting/Views/HomeView.swift:1495
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1495
  Def: let persist: () -> Void
  Dynamic-Risk Checklist: none flagged
- validateDrop (func) — OffshoreBudgeting/Views/HomeView.swift:1497
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1497
  Def: func validateDrop(info: DropInfo) -> Bool {
  Dynamic-Risk Checklist: none flagged
- dropEntered (func) — OffshoreBudgeting/Views/HomeView.swift:1501
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1501
  Def: func dropEntered(info: DropInfo) {
  Dynamic-Risk Checklist: none flagged
- dropUpdated (func) — OffshoreBudgeting/Views/HomeView.swift:1505
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1505
  Def: func dropUpdated(info: DropInfo) -> DropProposal? {
  Dynamic-Risk Checklist: none flagged
- performDrop (func) — OffshoreBudgeting/Views/HomeView.swift:1509
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1509
  Def: func performDrop(info: DropInfo) -> Bool {
  Dynamic-Risk Checklist: none flagged
- reorderIfNeeded (func) — OffshoreBudgeting/Views/HomeView.swift:1515
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1515
  Def: private func reorderIfNeeded() {
  Dynamic-Risk Checklist: none flagged
- categoryAvailabilityWidget (func) — OffshoreBudgeting/Views/HomeView.swift:1530
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1530
  Def: private func categoryAvailabilityWidget(for summary: BudgetSummary) -> some View {
  Dynamic-Risk Checklist: none flagged
- scenarioWidget (func) — OffshoreBudgeting/Views/HomeView.swift:1710
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1710
  Def: private func scenarioWidget(for summary: BudgetSummary) -> some View {
  Dynamic-Risk Checklist: none flagged
- availabilityNavButton (func) — OffshoreBudgeting/Views/HomeView.swift:1732
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1732
  Def: private func availabilityNavButton(_ systemName: String, isDisabled: Bool, action: @escaping () -> Void) -> some View {
  Dynamic-Risk Checklist: none flagged
- widgetCard (func) — OffshoreBudgeting/Views/HomeView.swift:1789
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1789
  Def: private func widgetCard<Content: View>(title: String, subtitle: String? = nil, subtitleColor: Color = .secondary, kind: HomeWidgetKind, span: WidgetSpan, @ViewBuilder content: () -> Content) -> some View {
  Dynamic-Risk Checklist: none flagged
- primarySummary (var) — OffshoreBudgeting/Views/HomeView.swift:1851
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1851
  Def: private var primarySummary: BudgetSummary? {
  Dynamic-Risk Checklist: none flagged
- weekdayRangeLabel (var) — OffshoreBudgeting/Views/HomeView.swift:1864
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1864
  Def: private var weekdayRangeLabel: String {
  Dynamic-Risk Checklist: none flagged
- heatmapBackground (var) — OffshoreBudgeting/Views/HomeView.swift:1871
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1871
  Def: private var heatmapBackground: some View {
  Dynamic-Risk Checklist: none flagged
- onAppearTask (func) — OffshoreBudgeting/Views/HomeView.swift:1900
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1900
  Def: private func onAppearTask() async {
  Dynamic-Risk Checklist: none flagged
- stateDidChange (func) — OffshoreBudgeting/Views/HomeView.swift:1906
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1906
  Def: private func stateDidChange() async {
  Dynamic-Risk Checklist: none flagged
- rangeDescription (func) — OffshoreBudgeting/Views/HomeView.swift:1920
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1920
  Def: private func rangeDescription(_ range: ClosedRange<Date>) -> String {
  Dynamic-Risk Checklist: none flagged
- applyButton (func) — OffshoreBudgeting/Views/HomeView.swift:1934
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1934
  Def: private func applyButton(_ disabled: Bool) -> some View {
  Dynamic-Risk Checklist: none flagged
- periodMenuItems (var) — OffshoreBudgeting/Views/HomeView.swift:2019
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2019
  Def: private var periodMenuItems: some View {
  Dynamic-Risk Checklist: none flagged
- syncPickers (func) — OffshoreBudgeting/Views/HomeView.swift:2034
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2034
  Def: private func syncPickers(with range: ClosedRange<Date>) {
  Dynamic-Risk Checklist: none flagged
- applyCustomRangeFromPickers (func) — OffshoreBudgeting/Views/HomeView.swift:2039
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2039
  Def: private func applyCustomRangeFromPickers() {
  Dynamic-Risk Checklist: none flagged
- applyPeriod (func) — OffshoreBudgeting/Views/HomeView.swift:2043
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2043
  Def: private func applyPeriod(_ period: BudgetPeriod) {
  Dynamic-Risk Checklist: none flagged
- loadNextPlannedExpense (func) — OffshoreBudgeting/Views/HomeView.swift:2065
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2065
  Def: private func loadNextPlannedExpense(for summary: BudgetSummary?) async {
  Dynamic-Risk Checklist: none flagged
- updateNextPlannedExpenseWidget (func) — OffshoreBudgeting/Views/HomeView.swift:2113
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2113
  Def: private func updateNextPlannedExpenseWidget(snapshot: PlannedExpenseSnapshot?) {
  Dynamic-Risk Checklist: none flagged
- nextExpenseAnchorDate (func) — OffshoreBudgeting/Views/HomeView.swift:2158
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2158
  Def: private func nextExpenseAnchorDate(for range: ClosedRange<Date>, selectedDate: Date) -> Date {
  Dynamic-Risk Checklist: none flagged
- preferredFocusDate (func) — OffshoreBudgeting/Views/HomeView.swift:2171
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2171
  Def: private func preferredFocusDate(in range: ClosedRange<Date>, selectedDate: Date) -> Date {
  Dynamic-Risk Checklist: none flagged
- loadWidgetBuckets (func) — OffshoreBudgeting/Views/HomeView.swift:2183
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2183
  Def: private func loadWidgetBuckets(for summary: BudgetSummary?) async {
  Dynamic-Risk Checklist: none flagged
- loadCards (func) — OffshoreBudgeting/Views/HomeView.swift:2223
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2223
  Def: private func loadCards(for summary: BudgetSummary?) async {
  Dynamic-Risk Checklist: none flagged
- loadAllCards (func) — OffshoreBudgeting/Views/HomeView.swift:2239
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2239
  Def: private func loadAllCards() async {
  Dynamic-Risk Checklist: none flagged
- loadCaps (func) — OffshoreBudgeting/Views/HomeView.swift:2276
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2276
  Def: private func loadCaps(for summary: BudgetSummary?) async {
  Dynamic-Risk Checklist: none flagged
- categoryAvailability (func) — OffshoreBudgeting/Views/HomeView.swift:2285
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2285
  Def: private func categoryAvailability(for summary: BudgetSummary, segment: CategoryAvailabilitySegment) -> [CategoryAvailability] {
  Dynamic-Risk Checklist: none flagged
- readPlannedDescription (func) — OffshoreBudgeting/Views/HomeView.swift:2289
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2289
  Def: fileprivate static func readPlannedDescription(_ object: NSManagedObject) -> String? {
  Dynamic-Risk Checklist: none flagged
- readUnplannedDescription (func) — OffshoreBudgeting/Views/HomeView.swift:2299
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2299
  Def: fileprivate static func readUnplannedDescription(_ object: NSManagedObject) -> String? {
  Dynamic-Risk Checklist: none flagged
- MetricDetailView (struct) — OffshoreBudgeting/Views/HomeView.swift:2337
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2337
  Def: private struct MetricDetailView: View {
  Dynamic-Risk Checklist: none flagged
- showAllCategories (var) — OffshoreBudgeting/Views/HomeView.swift:2348
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2348
  Def: @State private var showAllCategories: Bool = false
  Dynamic-Risk Checklist: none flagged
- expenseSeries (var) — OffshoreBudgeting/Views/HomeView.swift:2349
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2349
  Def: @State private var expenseSeries: [DatedValue] = []
  Dynamic-Risk Checklist: none flagged
- actualIncomeSeries (var) — OffshoreBudgeting/Views/HomeView.swift:2350
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2350
  Def: @State private var actualIncomeSeries: [DatedValue] = []
  Dynamic-Risk Checklist: none flagged
- plannedIncomeSeries (var) — OffshoreBudgeting/Views/HomeView.swift:2351
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2351
  Def: @State private var plannedIncomeSeries: [DatedValue] = []
  Dynamic-Risk Checklist: none flagged
- savingsSeries (var) — OffshoreBudgeting/Views/HomeView.swift:2352
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2352
  Def: @State private var savingsSeries: [SavingsPoint] = []
  Dynamic-Risk Checklist: none flagged
- ratioSelection (var) — OffshoreBudgeting/Views/HomeView.swift:2353
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2353
  Def: @State private var ratioSelection: DatedValue?
  Dynamic-Risk Checklist: none flagged
- timelineSelection (var) — OffshoreBudgeting/Views/HomeView.swift:2361
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2361
  Def: @State private var timelineSelection: DatedValue?
  Dynamic-Risk Checklist: none flagged
- comparisonPeriod (var) — OffshoreBudgeting/Views/HomeView.swift:2363
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2363
  Def: @State private var comparisonPeriod: IncomeComparisonPeriod = .monthly
  Dynamic-Risk Checklist: none flagged
- showAddIncomeSheet (var) — OffshoreBudgeting/Views/HomeView.swift:2365
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2365
  Def: @State private var showAddIncomeSheet = false
  Dynamic-Risk Checklist: none flagged
- editingIncomeBox (var) — OffshoreBudgeting/Views/HomeView.swift:2366
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2366
  Def: @State private var editingIncomeBox: ManagedIDBox?
  Dynamic-Risk Checklist: none flagged
- spendSections (var) — OffshoreBudgeting/Views/HomeView.swift:2367
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2367
  Def: @State private var spendSections: [SpendChartSection] = []
  Dynamic-Risk Checklist: none flagged
- expandedCategoryExpenses (var) — OffshoreBudgeting/Views/HomeView.swift:2369
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2369
  Def: @State private var expandedCategoryExpenses: [CategoryExpenseItem] = []
  Dynamic-Risk Checklist: none flagged
- expandedCategoryLoading (var) — OffshoreBudgeting/Views/HomeView.swift:2370
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2370
  Def: @State private var expandedCategoryLoading: Bool = false
  Dynamic-Risk Checklist: none flagged
- scenarioWidth (var) — OffshoreBudgeting/Views/HomeView.swift:2372
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2372
  Def: @State private var scenarioWidth: CGFloat = 0
  Dynamic-Risk Checklist: none flagged
- detailAvailabilitySegmentRawValue (var) — OffshoreBudgeting/Views/HomeView.swift:2373
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2373
  Def: @AppStorage("homeAvailabilitySegment") private var detailAvailabilitySegmentRawValue: String = CategoryAvailabilitySegment.combined.rawValue
  Dynamic-Risk Checklist: none flagged
- legendLineWidth (var) — OffshoreBudgeting/Views/HomeView.swift:2377
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2377
  Def: @ScaledMetric(relativeTo: .body) private var legendLineWidth: CGFloat = 18
  Dynamic-Risk Checklist: none flagged
- legendLineHeight (var) — OffshoreBudgeting/Views/HomeView.swift:2378
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2378
  Def: @ScaledMetric(relativeTo: .body) private var legendLineHeight: CGFloat = 3
  Dynamic-Risk Checklist: none flagged
- detailChartHeight (var) — OffshoreBudgeting/Views/HomeView.swift:2379
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2379
  Def: @ScaledMetric(relativeTo: .body) private var detailChartHeight: CGFloat = 200
  Dynamic-Risk Checklist: none flagged
- detailDayRowHeight (var) — OffshoreBudgeting/Views/HomeView.swift:2380
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2380
  Def: @ScaledMetric(relativeTo: .body) private var detailDayRowHeight: CGFloat = 28
  Dynamic-Risk Checklist: none flagged
- detailDayRowSpacing (var) — OffshoreBudgeting/Views/HomeView.swift:2381
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2381
  Def: @ScaledMetric(relativeTo: .body) private var detailDayRowSpacing: CGFloat = 10
  Dynamic-Risk Checklist: none flagged
- detailAvailabilitySegmentBinding (var) — OffshoreBudgeting/Views/HomeView.swift:2385
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2385
  Def: private var detailAvailabilitySegmentBinding: Binding<CategoryAvailabilitySegment> {
  Dynamic-Risk Checklist: none flagged
- isLargeText (var) — OffshoreBudgeting/Views/HomeView.swift:2392
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2392
  Def: private var isLargeText: Bool {
  Dynamic-Risk Checklist: none flagged
- condensedReceivedSeries (func) — OffshoreBudgeting/Views/HomeView.swift:2404
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2404
  Def: private func condensedReceivedSeries() -> [DatedValue] {
  Dynamic-Risk Checklist: none flagged
- ExpenseIncomePoint (struct) — OffshoreBudgeting/Views/HomeView.swift:2449
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2449
  Def: private struct ExpenseIncomePoint: Identifiable {
  Dynamic-Risk Checklist: none flagged
- detailContent (var) — OffshoreBudgeting/Views/HomeView.swift:2516
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2516
  Def: private var detailContent: some View {
  Dynamic-Risk Checklist: none flagged
- incomeContent (var) — OffshoreBudgeting/Views/HomeView.swift:2541
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2541
  Def: private var incomeContent: some View {
  Dynamic-Risk Checklist: none flagged
- weekdayContent (var) — OffshoreBudgeting/Views/HomeView.swift:2550
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2550
  Def: private var weekdayContent: some View {
  Dynamic-Risk Checklist: none flagged
- stackedHeight (let) — OffshoreBudgeting/Views/HomeView.swift:2562
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2562
  Def: let stackedHeight = CGFloat(rowCount) * rowHeight + CGFloat(max(rowCount - 1, 0)) * detailDayRowSpacing
  Dynamic-Risk Checklist: none flagged
- chartHeight (let) — OffshoreBudgeting/Views/HomeView.swift:2563
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2563
  Def: let chartHeight = orientation == .horizontal ? max(resolvedDetailChartHeight, stackedHeight) : resolvedDetailChartHeight
  Dynamic-Risk Checklist: none flagged
- capsContent (var) — OffshoreBudgeting/Views/HomeView.swift:2756
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2756
  Def: private var capsContent: some View {
  Dynamic-Risk Checklist: none flagged
- filtered (let) — OffshoreBudgeting/Views/HomeView.swift:2758
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2758
  Def: let filtered = (capStatuses ?? []).filter { $0.segment == segment }
  Dynamic-Risk Checklist: none flagged
- expenseToIncomeContent (var) — OffshoreBudgeting/Views/HomeView.swift:2816
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2816
  Def: private var expenseToIncomeContent: some View {
  Dynamic-Risk Checklist: none flagged
- incomePoints (let) — OffshoreBudgeting/Views/HomeView.swift:2819
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2819
  Def: let incomePoints = actualIncomeSeries.isEmpty ? twoPointSeries(value: summary.actualIncomeTotal) : actualIncomeSeries
  Dynamic-Risk Checklist: none flagged
- plannedPoints (let) — OffshoreBudgeting/Views/HomeView.swift:2820
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2820
  Def: let plannedPoints = plannedIncomeSeries.isEmpty ? twoPointSeries(value: summary.potentialIncomeTotal) : plannedIncomeSeries
  Dynamic-Risk Checklist: none flagged
- plannedIncomePercent (let) — OffshoreBudgeting/Views/HomeView.swift:2822
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2822
  Def: let plannedIncomePercent = summary.potentialIncomeTotal > 0
  Dynamic-Risk Checklist: none flagged
- actualIncomeRemainingPercent (let) — OffshoreBudgeting/Views/HomeView.swift:2825
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2825
  Def: let actualIncomeRemainingPercent = summary.actualIncomeTotal > 0
  Dynamic-Risk Checklist: none flagged
- savingsOutlookContent (var) — OffshoreBudgeting/Views/HomeView.swift:2841
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2841
  Def: private var savingsOutlookContent: some View {
  Dynamic-Risk Checklist: none flagged
- budgetContent (var) — OffshoreBudgeting/Views/HomeView.swift:2863
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2863
  Def: private var budgetContent: some View {
  Dynamic-Risk Checklist: none flagged
- nextExpenseContent (var) — OffshoreBudgeting/Views/HomeView.swift:2867
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2867
  Def: private var nextExpenseContent: some View {
  Dynamic-Risk Checklist: none flagged
- categoryContent (var) — OffshoreBudgeting/Views/HomeView.swift:2891
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2891
  Def: private var categoryContent: some View {
  Dynamic-Risk Checklist: none flagged
- totalForList (let) — OffshoreBudgeting/Views/HomeView.swift:2897
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2897
  Def: let totalForList = max(totalExpenses, 1)
  Dynamic-Risk Checklist: none flagged
- topSlices (let) — OffshoreBudgeting/Views/HomeView.swift:2898
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2898
  Def: let topSlices = Array(slices.prefix(3))
  Dynamic-Risk Checklist: none flagged
- availabilityContent (var) — OffshoreBudgeting/Views/HomeView.swift:2929
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2929
  Def: private var availabilityContent: some View {
  Dynamic-Risk Checklist: none flagged
- rowPadding (let) — OffshoreBudgeting/Views/HomeView.swift:2933
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2933
  Def: let rowPadding: CGFloat = isAccessibilitySize ? 8 : 4
  Dynamic-Risk Checklist: none flagged
- scenarioContent (var) — OffshoreBudgeting/Views/HomeView.swift:2978
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2978
  Def: private var scenarioContent: some View {
  Dynamic-Risk Checklist: none flagged
- toggleExpandedCategory (func) — OffshoreBudgeting/Views/HomeView.swift:2993
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:2993
  Def: private func toggleExpandedCategory(_ item: CategoryAvailability) {
  Dynamic-Risk Checklist: none flagged
- expandedCategoryExpensesView (var) — OffshoreBudgeting/Views/HomeView.swift:3004
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3004
  Def: private var expandedCategoryExpensesView: some View {
  Dynamic-Risk Checklist: none flagged
- categoryExpenseRow (func) — OffshoreBudgeting/Views/HomeView.swift:3027
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3027
  Def: private func categoryExpenseRow(_ expense: CategoryExpenseItem) -> some View {
  Dynamic-Risk Checklist: none flagged
- categoryExpenseCardPreview (func) — OffshoreBudgeting/Views/HomeView.swift:3049
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3049
  Def: private func categoryExpenseCardPreview(_ card: Card?) -> some View {
  Dynamic-Risk Checklist: none flagged
- expenseDateString (func) — OffshoreBudgeting/Views/HomeView.swift:3075
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3075
  Def: private func expenseDateString(_ date: Date?) -> String {
  Dynamic-Risk Checklist: none flagged
- loadExpandedCategoryExpenses (func) — OffshoreBudgeting/Views/HomeView.swift:3082
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3082
  Def: private func loadExpandedCategoryExpenses(categoryName: String, segment: CategoryAvailabilitySegment) {
  Dynamic-Risk Checklist: none flagged
- fetchCategoryExpenses (func) — OffshoreBudgeting/Views/HomeView.swift:3094
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3094
  Def: private func fetchCategoryExpenses(categoryName: String, segment: CategoryAvailabilitySegment) async -> [CategoryExpenseItem] {
  Dynamic-Risk Checklist: none flagged
- scenarioPlanner (func) — OffshoreBudgeting/Views/HomeView.swift:3177
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3177
  Def: private func scenarioPlanner(items: [CategoryAvailability], remainingIncome: Double, segment: CategoryAvailabilitySegment) -> some View {
  Dynamic-Risk Checklist: none flagged
- scenarioAllocationRow (func) — OffshoreBudgeting/Views/HomeView.swift:3295
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3295
  Def: private func scenarioAllocationRow(item: CategoryAvailability, segment: CategoryAvailabilitySegment) -> some View {
  Dynamic-Risk Checklist: none flagged
- scenarioKey (func) — OffshoreBudgeting/Views/HomeView.swift:3330
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3330
  Def: private func scenarioKey(for item: CategoryAvailability, segment: CategoryAvailabilitySegment) -> String {
  Dynamic-Risk Checklist: none flagged
- scenarioKeyPrefix (func) — OffshoreBudgeting/Views/HomeView.swift:3334
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3334
  Def: private func scenarioKeyPrefix(for segment: CategoryAvailabilitySegment) -> String {
  Dynamic-Risk Checklist: none flagged
- allocationValue (func) — OffshoreBudgeting/Views/HomeView.swift:3338
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3338
  Def: private func allocationValue(for item: CategoryAvailability, segment: CategoryAvailabilitySegment) -> Double {
  Dynamic-Risk Checklist: none flagged
- allocationBinding (func) — OffshoreBudgeting/Views/HomeView.swift:3343
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3343
  Def: private func allocationBinding(for item: CategoryAvailability, segment: CategoryAvailabilitySegment) -> Binding<Double> {
  Dynamic-Risk Checklist: none flagged
- scenarioPlannerDefaultWidth (func) — OffshoreBudgeting/Views/HomeView.swift:3355
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3355
  Def: private func scenarioPlannerDefaultWidth() -> CGFloat {
  Dynamic-Risk Checklist: none flagged
- scenarioSlices (func) — OffshoreBudgeting/Views/HomeView.swift:3376
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3376
  Def: private func scenarioSlices(items: [CategoryAvailability], savings: Double, segment: CategoryAvailabilitySegment) -> [CategorySlice] {
  Dynamic-Risk Checklist: none flagged
- scenarioGradient (func) — OffshoreBudgeting/Views/HomeView.swift:3398
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3398
  Def: private func scenarioGradient(for items: [CategoryAvailability]) -> AngularGradient? {
  Dynamic-Risk Checklist: none flagged
- scenarioAverageColor (func) — OffshoreBudgeting/Views/HomeView.swift:3405
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3405
  Def: private func scenarioAverageColor(for items: [CategoryAvailability]) -> Color {
  Dynamic-Risk Checklist: none flagged
- decodeScenarioAllocations (func) — OffshoreBudgeting/Views/HomeView.swift:3433
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3433
  Def: fileprivate func decodeScenarioAllocations(from raw: String) -> [String: Double] {
  Dynamic-Risk Checklist: none flagged
- encodeScenarioAllocations (func) — OffshoreBudgeting/Views/HomeView.swift:3446
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3446
  Def: fileprivate func encodeScenarioAllocations(_ values: [String: Double]) -> String {
  Dynamic-Risk Checklist: none flagged
- allocationFormatter (var) — OffshoreBudgeting/Views/HomeView.swift:3456
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3456
  Def: private var allocationFormatter: NumberFormatter {
  Dynamic-Risk Checklist: none flagged
- LegendSymbol (enum) — OffshoreBudgeting/Views/HomeView.swift:3499
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3499
  Def: private enum LegendSymbol {
  Dynamic-Risk Checklist: none flagged
- legendSymbolView (func) — OffshoreBudgeting/Views/HomeView.swift:3516
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3516
  Def: private func legendSymbolView(symbol: LegendSymbol, color: Color) -> some View {
  Dynamic-Risk Checklist: none flagged
- axisCurrencyLabel (func) — OffshoreBudgeting/Views/HomeView.swift:3530
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3530
  Def: private func axisCurrencyLabel(_ value: Double) -> some View {
  Dynamic-Risk Checklist: none flagged
- axisCurrencyLabelCompact (func) — OffshoreBudgeting/Views/HomeView.swift:3537
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3537
  Def: private func axisCurrencyLabelCompact(_ value: Double) -> some View {
  Dynamic-Risk Checklist: none flagged
- axisDateLabel (func) — OffshoreBudgeting/Views/HomeView.swift:3544
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3544
  Def: private func axisDateLabel(_ date: Date) -> some View {
  Dynamic-Risk Checklist: none flagged
- formatAxisCurrency (func) — OffshoreBudgeting/Views/HomeView.swift:3553
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3553
  Def: private func formatAxisCurrency(_ value: Double, compact: Bool) -> String {
  Dynamic-Risk Checklist: none flagged
- incomeTimelineSection (func) — OffshoreBudgeting/Views/HomeView.swift:3568
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3568
  Def: private func incomeTimelineSection(total: Double) -> some View {
  Dynamic-Risk Checklist: none flagged
- paceBadge (func) — OffshoreBudgeting/Views/HomeView.swift:3582
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3582
  Def: private func paceBadge(total: Double) -> some View {
  Dynamic-Risk Checklist: none flagged
- heatmapCategoryButton (func) — OffshoreBudgeting/Views/HomeView.swift:3605
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3605
  Def: private func heatmapCategoryButton(title: String, action: @escaping () -> Void) -> some View {
  Dynamic-Risk Checklist: none flagged
- categoryHeatmapColors (var) — OffshoreBudgeting/Views/HomeView.swift:3669
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3669
  Def: private var categoryHeatmapColors: [Color]? {
  Dynamic-Risk Checklist: none flagged
- rawColors (let) — OffshoreBudgeting/Views/HomeView.swift:3670
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3670
  Def: let rawColors = summary.categoryBreakdown.compactMap { UBColorFromHex($0.hexColor) }
  Dynamic-Risk Checklist: none flagged
- softenedHeatmapColors (func) — OffshoreBudgeting/Views/HomeView.swift:3676
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3676
  Def: private func softenedHeatmapColors(from colors: [Color]) -> [Color] {
  Dynamic-Risk Checklist: none flagged
- softenHeatmapColor (func) — OffshoreBudgeting/Views/HomeView.swift:3680
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3680
  Def: private func softenHeatmapColor(_ color: Color) -> Color {
  Dynamic-Risk Checklist: none flagged
- timelineChart (var) — OffshoreBudgeting/Views/HomeView.swift:3707
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3707
  Def: private var timelineChart: some View {
  Dynamic-Risk Checklist: none flagged
- receiptColor (let) — OffshoreBudgeting/Views/HomeView.swift:3714
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3714
  Def: let receiptColor = Color.green
  Dynamic-Risk Checklist: none flagged
- plannedSeries (let) — OffshoreBudgeting/Views/HomeView.swift:3716
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3716
  Def: let plannedSeries = expectedTimeline.isEmpty ? fallbackExpectedSeries() : expectedTimeline
  Dynamic-Risk Checklist: none flagged
- latestPlanned (let) — OffshoreBudgeting/Views/HomeView.swift:3719
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3719
  Def: let latestPlanned = plannedSeries.last?.value
  Dynamic-Risk Checklist: none flagged
- latestActual (let) — OffshoreBudgeting/Views/HomeView.swift:3720
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3720
  Def: let latestActual = actualLineSeries.last?.value
  Dynamic-Risk Checklist: none flagged
- maxVal (let) — OffshoreBudgeting/Views/HomeView.swift:3722
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3722
  Def: let maxVal = max((actualLineSeries.map(\.value).max() ?? 0), (plannedSeries.map(\.value).max() ?? 0), 1)
  Dynamic-Risk Checklist: none flagged
- locationX (let) — OffshoreBudgeting/Views/HomeView.swift:3833
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3833
  Def: let locationX = gesture.location.x - origin.x
  Dynamic-Risk Checklist: none flagged
- incomeMoMSection (var) — OffshoreBudgeting/Views/HomeView.swift:3897
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3897
  Def: private var incomeMoMSection: some View {
  Dynamic-Risk Checklist: none flagged
- latestBucket (let) — OffshoreBudgeting/Views/HomeView.swift:3931
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3931
  Def: let latestBucket = incomeBuckets.last
  Dynamic-Risk Checklist: none flagged
- quickIncomeActions (var) — OffshoreBudgeting/Views/HomeView.swift:4003
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:4003
  Def: private var quickIncomeActions: some View {
  Dynamic-Risk Checklist: none flagged
- addIncomeButton (var) — OffshoreBudgeting/Views/HomeView.swift:4027
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:4027
  Def: private var addIncomeButton: some View {
  Dynamic-Risk Checklist: none flagged
- editLatestButton (var) — OffshoreBudgeting/Views/HomeView.swift:4038
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:4038
  Def: private var editLatestButton: some View {
  Dynamic-Risk Checklist: none flagged
- dateString (func) — OffshoreBudgeting/Views/HomeView.swift:4068
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:4068
  Def: private func dateString(_ date: Date) -> String {
  Dynamic-Risk Checklist: none flagged
- nextExpenseList (var) — OffshoreBudgeting/Views/HomeView.swift:4074
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:4074
  Def: private var nextExpenseList: some View {
  Dynamic-Risk Checklist: none flagged
- detachedCardItem (func) — OffshoreBudgeting/Views/HomeView.swift:4100
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:4100
  Def: private func detachedCardItem(from card: Card?) -> CardItem? {
  Dynamic-Risk Checklist: none flagged
- deletePlannedExpense (func) — OffshoreBudgeting/Views/HomeView.swift:4105
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:4105
  Def: private func deletePlannedExpense(_ expense: PlannedExpense?) {
  Dynamic-Risk Checklist: none flagged
- fallbackRatioSeries (func) — OffshoreBudgeting/Views/HomeView.swift:4115
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:4115
  Def: private func fallbackRatioSeries(expenses: Double, income: Double) -> [DatedValue] {
  Dynamic-Risk Checklist: none flagged
- fallbackSavingsSeries (func) — OffshoreBudgeting/Views/HomeView.swift:4120
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:4120
  Def: private func fallbackSavingsSeries(projected: Double, actual: Double) -> [SavingsPoint] {
  Dynamic-Risk Checklist: none flagged
- twoPointDates (func) — OffshoreBudgeting/Views/HomeView.swift:4130
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:4130
  Def: private func twoPointDates() -> [Date] {
  Dynamic-Risk Checklist: none flagged
- actualIncomeLineSeries (func) — OffshoreBudgeting/Views/HomeView.swift:4151
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:4151
  Def: private func actualIncomeLineSeries(from receiptPoints: [DatedValue]) -> [DatedValue] {
  Dynamic-Risk Checklist: none flagged
- expectedIncomeSoFar (func) — OffshoreBudgeting/Views/HomeView.swift:4164
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:4164
  Def: private func expectedIncomeSoFar(progressFallback: Double, on date: Date) -> Double {
  Dynamic-Risk Checklist: none flagged
- fallbackExpectedSeries (func) — OffshoreBudgeting/Views/HomeView.swift:4175
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:4175
  Def: private func fallbackExpectedSeries() -> [DatedValue] {
  Dynamic-Risk Checklist: none flagged
- nearestPoint (func) — OffshoreBudgeting/Views/HomeView.swift:4182
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:4182
  Def: private func nearestPoint(in points: [DatedValue], to date: Date) -> DatedValue? {
  Dynamic-Risk Checklist: none flagged
- nearestSavingsPoint (func) — OffshoreBudgeting/Views/HomeView.swift:4186
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:4186
  Def: private func nearestSavingsPoint(in points: [SavingsPoint], to date: Date) -> SavingsPoint? {
  Dynamic-Risk Checklist: none flagged
- smoothSavings (func) — OffshoreBudgeting/Views/HomeView.swift:4190
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:4190
  Def: private func smoothSavings(_ points: [SavingsPoint], maxCount: Int) -> [SavingsPoint] {
  Dynamic-Risk Checklist: none flagged
- deduplicate (func) — OffshoreBudgeting/Views/HomeView.swift:4213
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:4213
  Def: private func deduplicate(_ points: [SavingsPoint]) -> [SavingsPoint] {
  Dynamic-Risk Checklist: none flagged
- loadSeriesIfNeeded (func) — OffshoreBudgeting/Views/HomeView.swift:4226
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:4226
  Def: private func loadSeriesIfNeeded() async {
  Dynamic-Risk Checklist: none flagged
- IncomeTimelineResult (struct) — OffshoreBudgeting/Views/HomeView.swift:4252
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:4252
  Def: private struct IncomeTimelineResult {
  Dynamic-Risk Checklist: none flagged
- computeDailySeries (func) — OffshoreBudgeting/Views/HomeView.swift:4259
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:4259
  Def: private func computeDailySeries() async -> DailySeriesResult {
  Dynamic-Risk Checklist: none flagged
- computeSpendSections (func) — OffshoreBudgeting/Views/HomeView.swift:4391
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:4391
  Def: private func computeSpendSections() async -> [SpendChartSection] {
  Dynamic-Risk Checklist: none flagged
- toggleSpendSelection (func) — OffshoreBudgeting/Views/HomeView.swift:4448
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:4448
  Def: private func toggleSpendSelection(in section: SpendChartSection, label: String) {
  Dynamic-Risk Checklist: none flagged
- spendCategoryChips (func) — OffshoreBudgeting/Views/HomeView.swift:4459
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:4459
  Def: private func spendCategoryChips(for bucket: SpendBucket) -> some View {
  Dynamic-Risk Checklist: none flagged
- allDates (func) — OffshoreBudgeting/Views/HomeView.swift:4501
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:4501
  Def: private func allDates(in range: ClosedRange<Date>) -> [Date] {
  Dynamic-Risk Checklist: none flagged
- computeIncomeTimeline (func) — OffshoreBudgeting/Views/HomeView.swift:4526
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:4526
  Def: private func computeIncomeTimeline() async -> IncomeTimelineResult {
  Dynamic-Risk Checklist: none flagged
- computeIncomeBuckets (func) — OffshoreBudgeting/Views/HomeView.swift:4579
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:4579
  Def: private func computeIncomeBuckets(using ctx: NSManagedObjectContext,
  Dynamic-Risk Checklist: none flagged
- bucketRange (func) — OffshoreBudgeting/Views/HomeView.swift:4600
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:4600
  Def: private func bucketRange(endingAt end: Date, index: Int, period: IncomeComparisonPeriod, calendar: Calendar) -> (start: Date, end: Date)? {
  Dynamic-Risk Checklist: none flagged
- bucketLabel (func) — OffshoreBudgeting/Views/HomeView.swift:4631
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:4631
  Def: private func bucketLabel(for range: (start: Date, end: Date), period: IncomeComparisonPeriod, calendar: Calendar) -> String {
  Dynamic-Risk Checklist: none flagged
- expenseIncomeChart (func) — OffshoreBudgeting/Views/HomeView.swift:4656
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:4656
  Def: private func expenseIncomeChart(expensePoints: [DatedValue], incomePoints: [DatedValue], plannedPoints: [DatedValue]) -> some View {
  Dynamic-Risk Checklist: none flagged
- savingsChart (func) — OffshoreBudgeting/Views/HomeView.swift:4836
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:4836
  Def: private func savingsChart(points: [SavingsPoint]) -> some View {
  Dynamic-Risk Checklist: none flagged
- categoryBars (func) — OffshoreBudgeting/Views/HomeView.swift:5025
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5025
  Def: private func categoryBars(totalOverride: Double? = nil) -> some View {
  Dynamic-Risk Checklist: none flagged
- categoriesCompactList (func) — OffshoreBudgeting/Views/HomeView.swift:5036
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5036
  Def: private func categoriesCompactList(_ items: [BudgetSummary.CategorySpending], total: Double) -> some View {
  Dynamic-Risk Checklist: none flagged
- categoryRow (func) — OffshoreBudgeting/Views/HomeView.swift:5044
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5044
  Def: private func categoryRow(_ cat: BudgetSummary.CategorySpending, total: Double) -> some View {
  Dynamic-Risk Checklist: none flagged
- NextPlannedDetailRow (struct) — OffshoreBudgeting/Views/HomeView.swift:5086
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5086
  Def: private struct NextPlannedDetailRow: View {
  Dynamic-Risk Checklist: none flagged
- showDeleteAlert (var) — OffshoreBudgeting/Views/HomeView.swift:5094
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5094
  Def: @State private var showDeleteAlert = false
  Dynamic-Risk Checklist: none flagged
- cardIndicatorWidth (var) — OffshoreBudgeting/Views/HomeView.swift:5097
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5097
  Def: @ScaledMetric(relativeTo: .body) private var cardIndicatorWidth: CGFloat = 12
  Dynamic-Risk Checklist: none flagged
- cardIndicatorHeight (var) — OffshoreBudgeting/Views/HomeView.swift:5098
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5098
  Def: @ScaledMetric(relativeTo: .body) private var cardIndicatorHeight: CGFloat = 8
  Dynamic-Risk Checklist: none flagged
- dotColor (let) — OffshoreBudgeting/Views/HomeView.swift:5101
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5101
  Def: let dotColor = UBColorFromHex(expense?.expenseCategory?.color) ?? .secondary
  Dynamic-Risk Checklist: none flagged
- cardIndicator (var) — OffshoreBudgeting/Views/HomeView.swift:5141
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5141
  Def: private var cardIndicator: some View {
  Dynamic-Risk Checklist: none flagged
- PresetExpenseRowView (struct) — OffshoreBudgeting/Views/HomeView.swift:5184
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5184
  Def: private struct PresetExpenseRowView: View {
  Dynamic-Risk Checklist: none flagged
- NextPlannedExpenseWidgetRow (struct) — OffshoreBudgeting/Views/HomeView.swift:5209
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5209
  Def: private struct NextPlannedExpenseWidgetRow: View {
  Dynamic-Risk Checklist: none flagged
- actualText (let) — OffshoreBudgeting/Views/HomeView.swift:5214
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5214
  Def: let actualText: String
  Dynamic-Risk Checklist: none flagged
- cardAspectRatio (let) — OffshoreBudgeting/Views/HomeView.swift:5216
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5216
  Def: private let cardAspectRatio: CGFloat = 1.586
  Dynamic-Risk Checklist: none flagged
- isCompactWidth (var) — OffshoreBudgeting/Views/HomeView.swift:5224
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5224
  Def: private var isCompactWidth: Bool {
  Dynamic-Risk Checklist: none flagged
- previewWidth (var) — OffshoreBudgeting/Views/HomeView.swift:5228
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5228
  Def: private var previewWidth: CGFloat {
  Dynamic-Risk Checklist: none flagged
- previewHeight (var) — OffshoreBudgeting/Views/HomeView.swift:5232
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5232
  Def: private var previewHeight: CGFloat {
  Dynamic-Risk Checklist: none flagged
- details (var) — OffshoreBudgeting/Views/HomeView.swift:5253
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5253
  Def: private var details: some View {
  Dynamic-Risk Checklist: none flagged
- cardPreview (var) — OffshoreBudgeting/Views/HomeView.swift:5274
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5274
  Def: private var cardPreview: some View {
  Dynamic-Risk Checklist: none flagged
- NextPlannedPresetsView (struct) — OffshoreBudgeting/Views/HomeView.swift:5307
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5307
  Def: private struct NextPlannedPresetsView: View {
  Dynamic-Risk Checklist: none flagged
- ExpenseBox (struct) — OffshoreBudgeting/Views/HomeView.swift:5315
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5315
  Def: private struct ExpenseBox: Identifiable {
  Dynamic-Risk Checklist: none flagged
- headerView (var) — OffshoreBudgeting/Views/HomeView.swift:5333
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5333
  Def: private var headerView: AnyView? {
  Dynamic-Risk Checklist: none flagged
- presentEditor (func) — OffshoreBudgeting/Views/HomeView.swift:5376
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5376
  Def: private func presentEditor(for snapshot: HomeView.PlannedExpenseSnapshot) {
  Dynamic-Risk Checklist: none flagged
- deletePlannedExpense (func) — OffshoreBudgeting/Views/HomeView.swift:5381
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5381
  Def: private func deletePlannedExpense(for snapshot: HomeView.PlannedExpenseSnapshot) {
  Dynamic-Risk Checklist: none flagged
- nextExpenseGradientColors (func) — OffshoreBudgeting/Views/HomeView.swift:5396
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5396
  Def: private func nextExpenseGradientColors(for expense: PlannedExpense?) -> [Color] {
  Dynamic-Risk Checklist: none flagged
- cardTheme (func) — OffshoreBudgeting/Views/HomeView.swift:5416
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5416
  Def: private func cardTheme(from card: Card?) -> CardTheme? {
  Dynamic-Risk Checklist: none flagged
- categorySlices (func) — OffshoreBudgeting/Views/HomeView.swift:5439
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5439
  Def: private func categorySlices(from categories: [BudgetSummary.CategorySpending], limit: Int) -> [CategorySlice] {
  Dynamic-Risk Checklist: none flagged
- resolvedPeriod (func) — OffshoreBudgeting/Views/HomeView.swift:5453
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5453
  Def: private func resolvedPeriod(_ period: BudgetPeriod, range: ClosedRange<Date>) -> BudgetPeriod {
  Dynamic-Risk Checklist: none flagged
- weeksInRange (func) — OffshoreBudgeting/Views/HomeView.swift:5482
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5482
  Def: private func weeksInRange(_ range: ClosedRange<Date>) -> [ClosedRange<Date>] {
  Dynamic-Risk Checklist: none flagged
- fullWeekRange (func) — OffshoreBudgeting/Views/HomeView.swift:5498
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5498
  Def: private func fullWeekRange(for date: Date) -> ClosedRange<Date> {
  Dynamic-Risk Checklist: none flagged
- monthsInRange (func) — OffshoreBudgeting/Views/HomeView.swift:5509
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5509
  Def: private func monthsInRange(_ range: ClosedRange<Date>) -> [ClosedRange<Date>] {
  Dynamic-Risk Checklist: none flagged
- fullYearRange (func) — OffshoreBudgeting/Views/HomeView.swift:5525
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5525
  Def: private func fullYearRange(for date: Date) -> ClosedRange<Date> {
  Dynamic-Risk Checklist: none flagged
- splitRange (func) — OffshoreBudgeting/Views/HomeView.swift:5536
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5536
  Def: private func splitRange(_ range: ClosedRange<Date>, daysPerBucket: Int) -> [ClosedRange<Date>] {
  Dynamic-Risk Checklist: none flagged
- dayRangeLabel (func) — OffshoreBudgeting/Views/HomeView.swift:5551
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5551
  Def: private func dayRangeLabel(for range: ClosedRange<Date>) -> String {
  Dynamic-Risk Checklist: none flagged
- daySpendTotals (func) — OffshoreBudgeting/Views/HomeView.swift:5566
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5566
  Def: private func daySpendTotals(for summary: BudgetSummary, in range: ClosedRange<Date>) async -> [Date: DaySpendTotal] {
  Dynamic-Risk Checklist: none flagged
- bucketsForDays (func) — OffshoreBudgeting/Views/HomeView.swift:5623
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5623
  Def: private func bucketsForDays(in range: ClosedRange<Date>, dayTotals: [Date: DaySpendTotal], includeAllWeekdays: Bool) -> [SpendBucket] {
  Dynamic-Risk Checklist: none flagged
- bucketsForWeeks (func) — OffshoreBudgeting/Views/HomeView.swift:5655
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5655
  Def: private func bucketsForWeeks(in range: ClosedRange<Date>, dayTotals: [Date: DaySpendTotal]) -> [SpendBucket] {
  Dynamic-Risk Checklist: none flagged
- bucketsForRanges (func) — OffshoreBudgeting/Views/HomeView.swift:5681
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5681
  Def: private func bucketsForRanges(_ ranges: [ClosedRange<Date>], dayTotals: [Date: DaySpendTotal]) -> [SpendBucket] {
  Dynamic-Risk Checklist: none flagged
- bucketsForMonths (func) — OffshoreBudgeting/Views/HomeView.swift:5707
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5707
  Def: private func bucketsForMonths(in range: ClosedRange<Date>, dayTotals: [Date: DaySpendTotal]) -> [SpendBucket] {
  Dynamic-Risk Checklist: none flagged
- spendGradientColors (func) — OffshoreBudgeting/Views/HomeView.swift:5735
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5735
  Def: private func spendGradientColors(for bucket: SpendBucket, summary: BudgetSummary, maxColors: Int) -> [Color] {
  Dynamic-Risk Checklist: none flagged
- uniqueHexes (func) — OffshoreBudgeting/Views/HomeView.swift:5752
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5752
  Def: private func uniqueHexes(from hexes: [String], maxCount: Int) -> [String] {
  Dynamic-Risk Checklist: none flagged
- blendTail (func) — OffshoreBudgeting/Views/HomeView.swift:5764
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5764
  Def: private func blendTail(colors: [Color], totalCount: Int, maxCount: Int) -> [Color] {
  Dynamic-Risk Checklist: none flagged
- detailBarOrientation (func) — OffshoreBudgeting/Views/HomeView.swift:5775
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5775
  Def: private func detailBarOrientation(for period: BudgetPeriod, bucketCount: Int) -> SpendBarOrientation {
  Dynamic-Risk Checklist: none flagged
- blend (func) — OffshoreBudgeting/Views/HomeView.swift:5784
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5784
  Def: func blend(with other: Color, fraction: Double) -> Color {
  Dynamic-Risk Checklist: none flagged
- fetchCapStatuses (func) — OffshoreBudgeting/Views/HomeView.swift:5812
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5812
  Def: private func fetchCapStatuses(for summary: BudgetSummary) async -> [CapStatus] {
  Dynamic-Risk Checklist: none flagged
- capsPeriodKey (func) — OffshoreBudgeting/Views/HomeView.swift:5819
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5819
  Def: private func capsPeriodKey(start: Date, end: Date, segment: String) -> String {
  Dynamic-Risk Checklist: none flagged
- normalizeCategoryName (func) — OffshoreBudgeting/Views/HomeView.swift:5831
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5831
  Def: fileprivate func normalizeCategoryName(_ name: String) -> String {
  Dynamic-Risk Checklist: none flagged
- categoryCaps (func) — OffshoreBudgeting/Views/HomeView.swift:5835
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5835
  Def: fileprivate func categoryCaps(for summary: BudgetSummary) -> [String: (planned: Double?, variable: Double?)] {
  Dynamic-Risk Checklist: none flagged
- computeCategoryAvailability (func) — OffshoreBudgeting/Views/HomeView.swift:5861
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5861
  Def: fileprivate func computeCategoryAvailability(summary: BudgetSummary, caps: [String: (planned: Double?, variable: Double?)], segment: CategoryAvailabilitySegment) -> [CategoryAvailability] {
  Dynamic-Risk Checklist: none flagged
- computeCapStatuses (func) — OffshoreBudgeting/Views/HomeView.swift:5914
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5914
  Def: fileprivate func computeCapStatuses(summary: BudgetSummary, caps: [String: (planned: Double?, variable: Double?)], segment: CategoryAvailabilitySegment) -> [CapStatus] {
  Dynamic-Risk Checklist: none flagged
- ubWidgetTitle (let) — OffshoreBudgeting/Views/HomeView.swift:5971
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5971
  Def: static let ubWidgetTitle = Font.headline.weight(.semibold)
  Dynamic-Risk Checklist: none flagged
- ubWidgetSubtitle (let) — OffshoreBudgeting/Views/HomeView.swift:5972
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5972
  Def: static let ubWidgetSubtitle = Font.subheadline
  Dynamic-Risk Checklist: none flagged
- ubSectionTitle (let) — OffshoreBudgeting/Views/HomeView.swift:5973
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5973
  Def: static let ubSectionTitle = Font.headline.weight(.semibold)
  Dynamic-Risk Checklist: none flagged
- ubMetricValue (let) — OffshoreBudgeting/Views/HomeView.swift:5974
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5974
  Def: static let ubMetricValue = Font.title3.weight(.bold)
  Dynamic-Risk Checklist: none flagged
- ubChip (let) — OffshoreBudgeting/Views/HomeView.swift:5977
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5977
  Def: static let ubChip = Font.caption.weight(.semibold)
  Dynamic-Risk Checklist: none flagged
- ubSmallCaption (let) — OffshoreBudgeting/Views/HomeView.swift:5979
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5979
  Def: static let ubSmallCaption = Font.caption2
  Dynamic-Risk Checklist: none flagged
- centerValueGradient (var) — OffshoreBudgeting/Views/HomeView.swift:5987
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:5987
  Def: var centerValueGradient: AngularGradient? = nil
  Dynamic-Risk Checklist: none flagged
- centerStyle (var) — OffshoreBudgeting/Views/HomeView.swift:6060
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:6060
  Def: private var centerStyle: AnyShapeStyle {
  Dynamic-Risk Checklist: none flagged
- specialOutline (var) — OffshoreBudgeting/Views/HomeView.swift:6079
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:6079
  Def: private var specialOutline: (start: Angle, end: Angle, color: Color)? {
  Dynamic-Risk Checklist: none flagged
- totalAmount (let) — OffshoreBudgeting/Views/HomeView.swift:6080
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:6080
  Def: let totalAmount = max(total, 1)
  Dynamic-Risk Checklist: none flagged
- uniformAngularGradient (func) — OffshoreBudgeting/Views/HomeView.swift:6097
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:6097
  Def: fileprivate func uniformAngularGradient(_ color: Color) -> AngularGradient {
  Dynamic-Risk Checklist: none flagged
- DonutSliceOutline (struct) — OffshoreBudgeting/Views/HomeView.swift:6101
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:6101
  Def: private struct DonutSliceOutline: Shape {
  Dynamic-Risk Checklist: none flagged
- innerRadiusRatio (let) — OffshoreBudgeting/Views/HomeView.swift:6104
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:6104
  Def: let innerRadiusRatio: CGFloat
  Dynamic-Risk Checklist: none flagged
- outerRadiusRatio (let) — OffshoreBudgeting/Views/HomeView.swift:6105
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:6105
  Def: let outerRadiusRatio: CGFloat
  Dynamic-Risk Checklist: none flagged
- CategoryTopRow (struct) — OffshoreBudgeting/Views/HomeView.swift:6120
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:6120
  Def: private struct CategoryTopRow: View {
  Dynamic-Risk Checklist: none flagged
- share (let) — OffshoreBudgeting/Views/HomeView.swift:6131
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:6131
  Def: let share = max(min(slice.amount / max(total, 1), 1), 0)
  Dynamic-Risk Checklist: none flagged
- categoryPredicate (func) — OffshoreBudgeting/Views/HomeView.swift:6195
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:6195
  Def: private func categoryPredicate(from uri: URL?) -> NSPredicate? {
  Dynamic-Risk Checklist: none flagged
- PlannedRowsList (struct) — OffshoreBudgeting/Views/HomeView.swift:6206
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:6206
  Def: struct PlannedRowsList: View {
  Dynamic-Risk Checklist: none flagged
- cardPreviewHeight (var) — OffshoreBudgeting/Views/HomeView.swift:6217
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:6217
  Def: @ScaledMetric(relativeTo: .body) private var cardPreviewHeight: CGFloat = 8
  Dynamic-Risk Checklist: none flagged
- dotColor (let) — OffshoreBudgeting/Views/HomeView.swift:6263
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:6263
  Def: let dotColor = UBColorFromHex(exp.expenseCategory?.color) ?? .secondary
  Dynamic-Risk Checklist: none flagged
- dateString (func) — OffshoreBudgeting/Views/HomeView.swift:6337
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:6337
  Def: private static func dateString(_ date: Date?) -> String {
  Dynamic-Risk Checklist: none flagged
- readPlannedDescription (func) — OffshoreBudgeting/Views/HomeView.swift:6343
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:6343
  Def: private static func readPlannedDescription(_ object: NSManagedObject) -> String? {
  Dynamic-Risk Checklist: none flagged
- SegmentedGlassStyleModifier (struct) — OffshoreBudgeting/Views/HomeView.swift:6371
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:6371
  Def: private struct SegmentedGlassStyleModifier: ViewModifier {
  Dynamic-Risk Checklist: none flagged
- ubSegmentedGlassStyle (func) — OffshoreBudgeting/Views/HomeView.swift:6411
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:6411
  Def: func ubSegmentedGlassStyle(cornerRadius: CGFloat = 18) -> some View {
  Dynamic-Risk Checklist: none flagged
- VariableRowsList (struct) — OffshoreBudgeting/Views/HomeView.swift:6416
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:6416
  Def: struct VariableRowsList: View {
  Dynamic-Risk Checklist: none flagged
- cardPreviewHeight (var) — OffshoreBudgeting/Views/HomeView.swift:6428
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:6428
  Def: @ScaledMetric(relativeTo: .body) private var cardPreviewHeight: CGFloat = 8
  Dynamic-Risk Checklist: none flagged
- dotColor (let) — OffshoreBudgeting/Views/HomeView.swift:6478
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:6478
  Def: let dotColor = UBColorFromHex(exp.expenseCategory?.color) ?? .secondary
  Dynamic-Risk Checklist: none flagged
- readUnplannedDescription (func) — OffshoreBudgeting/Views/HomeView.swift:6550
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:6550
  Def: private static func readUnplannedDescription(_ object: NSManagedObject) -> String? {
  Dynamic-Risk Checklist: none flagged
- dateString (func) — OffshoreBudgeting/Views/HomeView.swift:6560
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:6560
  Def: private static func dateString(_ date: Date?) -> String {
  Dynamic-Risk Checklist: none flagged
- amountDouble (var) — OffshoreBudgeting/Views/IncomeEditorView.swift:47
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeEditorView.swift:47
  Def: var amountDouble: Double { Double(amountString.replacingOccurrences(of: ",", with: "")) ?? 0 }
  Dynamic-Risk Checklist: none flagged
- recurrenceString (var) — OffshoreBudgeting/Views/IncomeEditorView.swift:48
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeEditorView.swift:48
  Def: var recurrenceString: String? {
  Dynamic-Risk Checklist: none flagged
- RecurrenceOption (enum) — OffshoreBudgeting/Views/IncomeEditorView.swift:58
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeEditorView.swift:58
  Def: enum RecurrenceOption: String, CaseIterable, Identifiable {
  Dynamic-Risk Checklist: none flagged
- IncomeEditorView (struct) — OffshoreBudgeting/Views/IncomeEditorView.swift:78
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeEditorView.swift:78
  Def: struct IncomeEditorView: View {
  Dynamic-Risk Checklist: none flagged
- titleText (var) — OffshoreBudgeting/Views/IncomeEditorView.swift:178
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeEditorView.swift:178
  Def: private var titleText: String {
  Dynamic-Risk Checklist: none flagged
- saveButtonTitle (var) — OffshoreBudgeting/Views/IncomeEditorView.swift:184
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeEditorView.swift:184
  Def: private var saveButtonTitle: String {
  Dynamic-Risk Checklist: none flagged
- amountField (var) — OffshoreBudgeting/Views/IncomeEditorView.swift:198
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeEditorView.swift:198
  Def: private var amountField: some View {
  Dynamic-Risk Checklist: none flagged
- handleSave (func) — OffshoreBudgeting/Views/IncomeEditorView.swift:214
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeEditorView.swift:214
  Def: private func handleSave() -> Bool {
  Dynamic-Risk Checklist: none flagged
- makeInitialForm (func) — OffshoreBudgeting/Views/IncomeEditorView.swift:249
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeEditorView.swift:249
  Def: private static func makeInitialForm(mode: IncomeEditorMode, seed: Income?) -> IncomeEditorForm {
  Dynamic-Risk Checklist: none flagged
- IncomeView (struct) — OffshoreBudgeting/Views/IncomeView.swift:11
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:11
  Def: struct IncomeView: View {
  Dynamic-Risk Checklist: none flagged
- uiTest (var) — OffshoreBudgeting/Views/IncomeView.swift:15
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:15
  Def: @Environment(\.uiTestingFlags) private var uiTest
  Dynamic-Risk Checklist: none flagged
- addIncomeSheetDate (var) — OffshoreBudgeting/Views/IncomeView.swift:21
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:21
  Def: @State private var addIncomeSheetDate: Date? = nil
  Dynamic-Risk Checklist: none flagged
- editingIncome (var) — OffshoreBudgeting/Views/IncomeView.swift:22
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:22
  Def: @State private var editingIncome: Income? = nil
  Dynamic-Risk Checklist: none flagged
- moc (var) — OffshoreBudgeting/Views/IncomeView.swift:25
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:25
  Def: @Environment(\.managedObjectContext) private var moc
  Dynamic-Risk Checklist: none flagged
- incomePendingDeletion (var) — OffshoreBudgeting/Views/IncomeView.swift:33
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:33
  Def: @State private var incomePendingDeletion: Income?
  Dynamic-Risk Checklist: none flagged
- calendarNavLabelMinWidth (var) — OffshoreBudgeting/Views/IncomeView.swift:38
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:38
  Def: @ScaledMetric(relativeTo: .body) private var calendarNavLabelMinWidth: CGFloat = 64
  Dynamic-Risk Checklist: none flagged
- calendarNavSpacing (var) — OffshoreBudgeting/Views/IncomeView.swift:39
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:39
  Def: @ScaledMetric(relativeTo: .body) private var calendarNavSpacing: CGFloat = 12
  Dynamic-Risk Checklist: none flagged
- minCalendarHeightCompact (var) — OffshoreBudgeting/Views/IncomeView.swift:40
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:40
  Def: @ScaledMetric(relativeTo: .body) private var minCalendarHeightCompact: CGFloat = 260
  Dynamic-Risk Checklist: none flagged
- minCalendarHeightRegular (var) — OffshoreBudgeting/Views/IncomeView.swift:41
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:41
  Def: @ScaledMetric(relativeTo: .body) private var minCalendarHeightRegular: CGFloat = 320
  Dynamic-Risk Checklist: none flagged
- calendarHeaderHeight (var) — OffshoreBudgeting/Views/IncomeView.swift:42
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:42
  Def: @ScaledMetric(relativeTo: .body) private var calendarHeaderHeight: CGFloat = 64
  Dynamic-Risk Checklist: none flagged
- calendarHeightScale (var) — OffshoreBudgeting/Views/IncomeView.swift:43
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:43
  Def: @ScaledMetric(relativeTo: .body) private var calendarHeightScale: CGFloat = 1
  Dynamic-Risk Checklist: none flagged
- weekHeaderSpacing (var) — OffshoreBudgeting/Views/IncomeView.swift:44
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:44
  Def: @ScaledMetric(relativeTo: .body) private var weekHeaderSpacing: CGFloat = 8
  Dynamic-Risk Checklist: none flagged
- weekCellSpacing (var) — OffshoreBudgeting/Views/IncomeView.swift:45
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:45
  Def: @ScaledMetric(relativeTo: .body) private var weekCellSpacing: CGFloat = 6
  Dynamic-Risk Checklist: none flagged
- weekCellPadding (var) — OffshoreBudgeting/Views/IncomeView.swift:46
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:46
  Def: @ScaledMetric(relativeTo: .body) private var weekCellPadding: CGFloat = 6
  Dynamic-Risk Checklist: none flagged
- weekCellMinHeight (var) — OffshoreBudgeting/Views/IncomeView.swift:47
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:47
  Def: @ScaledMetric(relativeTo: .body) private var weekCellMinHeight: CGFloat = 84
  Dynamic-Risk Checklist: none flagged
- weekCellCornerRadius (var) — OffshoreBudgeting/Views/IncomeView.swift:48
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:48
  Def: @ScaledMetric(relativeTo: .body) private var weekCellCornerRadius: CGFloat = 8
  Dynamic-Risk Checklist: none flagged
- weekCellInnerSpacing (var) — OffshoreBudgeting/Views/IncomeView.swift:49
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:49
  Def: @ScaledMetric(relativeTo: .body) private var weekCellInnerSpacing: CGFloat = 4
  Dynamic-Risk Checklist: none flagged
- incomeContent (var) — OffshoreBudgeting/Views/IncomeView.swift:66
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:66
  Def: private var incomeContent: some View {
  Dynamic-Risk Checklist: none flagged
- calendarNav (var) — OffshoreBudgeting/Views/IncomeView.swift:131
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:131
  Def: private var calendarNav: some View {
  Dynamic-Risk Checklist: none flagged
- calendarNavRow (var) — OffshoreBudgeting/Views/IncomeView.swift:139
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:139
  Def: private var calendarNavRow: some View {
  Dynamic-Risk Checklist: none flagged
- calendarNavWrapped (var) — OffshoreBudgeting/Views/IncomeView.swift:154
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:154
  Def: private var calendarNavWrapped: some View {
  Dynamic-Risk Checklist: none flagged
- navIcon (func) — OffshoreBudgeting/Views/IncomeView.swift:171
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:171
  Def: private func navIcon(_ systemName: String, action: @escaping () -> Void) -> some View {
  Dynamic-Risk Checklist: none flagged
- navLabel (func) — OffshoreBudgeting/Views/IncomeView.swift:195
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:195
  Def: private func navLabel(_ title: String, action: @escaping () -> Void) -> some View {
  Dynamic-Risk Checklist: none flagged
- navText (func) — OffshoreBudgeting/Views/IncomeView.swift:220
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:220
  Def: private func navText(_ title: String, action: @escaping () -> Void) -> some View {
  Dynamic-Risk Checklist: none flagged
- calendarView (var) — OffshoreBudgeting/Views/IncomeView.swift:243
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:243
  Def: private var calendarView: some View {
  Dynamic-Risk Checklist: none flagged
- monthCalendarView (var) — OffshoreBudgeting/Views/IncomeView.swift:251
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:251
  Def: private var monthCalendarView: some View {
  Dynamic-Risk Checklist: none flagged
- accessibilityWeekCalendar (var) — OffshoreBudgeting/Views/IncomeView.swift:292
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:292
  Def: private var accessibilityWeekCalendar: some View {
  Dynamic-Risk Checklist: none flagged
- weekDates (let) — OffshoreBudgeting/Views/IncomeView.swift:294
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:294
  Def: let weekDates = weekDates(for: selected)
  Dynamic-Risk Checklist: none flagged
- weekDayRow (func) — OffshoreBudgeting/Views/IncomeView.swift:311
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:311
  Def: private func weekDayRow(date: Date) -> some View {
  Dynamic-Risk Checklist: none flagged
- weekDates (func) — OffshoreBudgeting/Views/IncomeView.swift:359
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:359
  Def: private func weekDates(for date: Date) -> [Date] {
  Dynamic-Risk Checklist: none flagged
- monthTitle (func) — OffshoreBudgeting/Views/IncomeView.swift:365
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:365
  Def: private func monthTitle(for date: Date) -> String {
  Dynamic-Risk Checklist: none flagged
- weekDayAccessibilityLabel (func) — OffshoreBudgeting/Views/IncomeView.swift:371
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:371
  Def: private func weekDayAccessibilityLabel(for date: Date, planned: Double, actual: Double) -> String {
  Dynamic-Risk Checklist: none flagged
- horizontalInsets (let) — OffshoreBudgeting/Views/IncomeView.swift:399
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:399
  Def: let horizontalInsets: CGFloat = dynamicTypeSize.isAccessibilitySize ? 20 : 40
  Dynamic-Risk Checklist: none flagged
- dayDimension (let) — OffshoreBudgeting/Views/IncomeView.swift:401
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:401
  Def: let dayDimension = max(35, (availableWidth / 7).rounded(.down))
  Dynamic-Risk Checklist: none flagged
- computedHeight (let) — OffshoreBudgeting/Views/IncomeView.swift:402
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:402
  Def: let computedHeight = dayDimension * 4 * heightScale
  Dynamic-Risk Checklist: none flagged
- panelWidth (let) — OffshoreBudgeting/Views/IncomeView.swift:410
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:410
  Def: let panelWidth = calendarPanelWidth(in: container)
  Dynamic-Risk Checklist: none flagged
- targetHeight (let) — OffshoreBudgeting/Views/IncomeView.swift:411
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:411
  Def: let targetHeight = targetCalendarHeight(in: container)
  Dynamic-Risk Checklist: none flagged
- headerHeight (let) — OffshoreBudgeting/Views/IncomeView.swift:412
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:412
  Def: let headerHeight: CGFloat = calendarHeaderHeight
  Dynamic-Risk Checklist: none flagged
- dayDimension (let) — OffshoreBudgeting/Views/IncomeView.swift:413
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:413
  Def: let dayDimension = max(28, min(panelWidth / 7, (targetHeight - headerHeight) / 6))
  Dynamic-Risk Checklist: none flagged
- calendarWidth (let) — OffshoreBudgeting/Views/IncomeView.swift:414
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:414
  Def: let calendarWidth = min(panelWidth, dayDimension * 7)
  Dynamic-Risk Checklist: none flagged
- calendarHeight (let) — OffshoreBudgeting/Views/IncomeView.swift:415
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:415
  Def: let calendarHeight = max(minCalendarHeight, dayDimension * 6 * heightScale + headerHeight)
  Dynamic-Risk Checklist: none flagged
- scaleBase (let) — OffshoreBudgeting/Views/IncomeView.swift:416
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:416
  Def: let scaleBase = min(1.0, max(0.75, dayDimension / 46))
  Dynamic-Risk Checklist: none flagged
- calendarPanelWidth (func) — OffshoreBudgeting/Views/IncomeView.swift:426
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:426
  Def: private func calendarPanelWidth(in container: CGSize) -> CGFloat {
  Dynamic-Risk Checklist: none flagged
- targetCalendarHeight (func) — OffshoreBudgeting/Views/IncomeView.swift:433
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:433
  Def: private func targetCalendarHeight(in container: CGSize) -> CGFloat {
  Dynamic-Risk Checklist: none flagged
- splitPanelSpacing (var) — OffshoreBudgeting/Views/IncomeView.swift:441
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:441
  Def: private var splitPanelSpacing: CGFloat { 16 }
  Dynamic-Risk Checklist: none flagged
- splitPanelHeight (var) — OffshoreBudgeting/Views/IncomeView.swift:442
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:442
  Def: private var splitPanelHeight: CGFloat {
  Dynamic-Risk Checklist: none flagged
- topPadding (let) — OffshoreBudgeting/Views/IncomeView.swift:444
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:444
  Def: let topPadding: CGFloat = 12
  Dynamic-Risk Checklist: none flagged
- navHeight (let) — OffshoreBudgeting/Views/IncomeView.swift:445
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:445
  Def: let navHeight: CGFloat = calendarNavButtonSize
  Dynamic-Risk Checklist: none flagged
- isPhonePortraitLayout (var) — OffshoreBudgeting/Views/IncomeView.swift:456
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:456
  Def: private var isPhonePortraitLayout: Bool {
  Dynamic-Risk Checklist: none flagged
- listIncomeContent (var) — OffshoreBudgeting/Views/IncomeView.swift:463
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:463
  Def: private var listIncomeContent: some View {
  Dynamic-Risk Checklist: none flagged
- splitIncomeContent (var) — OffshoreBudgeting/Views/IncomeView.swift:515
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:515
  Def: private var splitIncomeContent: some View {
  Dynamic-Risk Checklist: none flagged
- calendarPanel (var) — OffshoreBudgeting/Views/IncomeView.swift:535
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:535
  Def: private var calendarPanel: some View {
  Dynamic-Risk Checklist: none flagged
- selectedDayPanel (var) — OffshoreBudgeting/Views/IncomeView.swift:544
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:544
  Def: private var selectedDayPanel: some View {
  Dynamic-Risk Checklist: none flagged
- IncomeSplitCellModifier (struct) — OffshoreBudgeting/Views/IncomeView.swift:575
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:575
  Def: private struct IncomeSplitCellModifier: ViewModifier {
  Dynamic-Risk Checklist: none flagged
- splitCellBackground (var) — OffshoreBudgeting/Views/IncomeView.swift:589
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:589
  Def: private var splitCellBackground: Color {
  Dynamic-Risk Checklist: none flagged
- splitPageBackground (var) — OffshoreBudgeting/Views/IncomeView.swift:593
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:593
  Def: private var splitPageBackground: Color {
  Dynamic-Risk Checklist: none flagged
- selectedDayHeaderView (var) — OffshoreBudgeting/Views/IncomeView.swift:602
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:602
  Def: private var selectedDayHeaderView: some View {
  Dynamic-Risk Checklist: none flagged
- weeklyTotalsSection (var) — OffshoreBudgeting/Views/IncomeView.swift:614
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:614
  Def: private var weeklyTotalsSection: some View {
  Dynamic-Risk Checklist: none flagged
- incomeRow (func) — OffshoreBudgeting/Views/IncomeView.swift:630
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:630
  Def: private func incomeRow(_ income: Income) -> some View {
  Dynamic-Risk Checklist: none flagged
- rowAccessibilityID (func) — OffshoreBudgeting/Views/IncomeView.swift:647
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:647
  Def: private func rowAccessibilityID(for income: Income) -> String {
  Dynamic-Risk Checklist: none flagged
- totalsColumn (func) — OffshoreBudgeting/Views/IncomeView.swift:652
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:652
  Def: private func totalsColumn(label: String, amount: Double, color: Color) -> some View {
  Dynamic-Risk Checklist: none flagged
- addIncome (func) — OffshoreBudgeting/Views/IncomeView.swift:660
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:660
  Def: private func addIncome() { addIncomeSheetDate = vm.selectedDate ?? Date() }
  Dynamic-Risk Checklist: none flagged
- goToPreviousMonth (func) — OffshoreBudgeting/Views/IncomeView.swift:661
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:661
  Def: private func goToPreviousMonth() { adjustMonth(by: -1) }
  Dynamic-Risk Checklist: none flagged
- goToNextMonth (func) — OffshoreBudgeting/Views/IncomeView.swift:662
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:662
  Def: private func goToNextMonth() { adjustMonth(by: 1) }
  Dynamic-Risk Checklist: none flagged
- goToPreviousDay (func) — OffshoreBudgeting/Views/IncomeView.swift:663
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:663
  Def: private func goToPreviousDay() { adjustDay(by: -1) }
  Dynamic-Risk Checklist: none flagged
- goToNextDay (func) — OffshoreBudgeting/Views/IncomeView.swift:664
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:664
  Def: private func goToNextDay() { adjustDay(by: 1) }
  Dynamic-Risk Checklist: none flagged
- goToPreviousWeek (func) — OffshoreBudgeting/Views/IncomeView.swift:665
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:665
  Def: private func goToPreviousWeek() { adjustWeek(by: -1) }
  Dynamic-Risk Checklist: none flagged
- goToNextWeek (func) — OffshoreBudgeting/Views/IncomeView.swift:666
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:666
  Def: private func goToNextWeek() { adjustWeek(by: 1) }
  Dynamic-Risk Checklist: none flagged
- goToToday (func) — OffshoreBudgeting/Views/IncomeView.swift:667
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:667
  Def: private func goToToday() { calendarScrollDate = normalize(Date()); vm.selectedDate = normalize(Date()) }
  Dynamic-Risk Checklist: none flagged
- refreshSelectedDay (func) — OffshoreBudgeting/Views/IncomeView.swift:668
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:668
  Def: private func refreshSelectedDay() {
  Dynamic-Risk Checklist: none flagged
- adjustDay (func) — OffshoreBudgeting/Views/IncomeView.swift:674
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:674
  Def: private func adjustDay(by delta: Int) {
  Dynamic-Risk Checklist: none flagged
- adjustMonth (func) — OffshoreBudgeting/Views/IncomeView.swift:681
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:681
  Def: private func adjustMonth(by delta: Int) {
  Dynamic-Risk Checklist: none flagged
- adjustWeek (func) — OffshoreBudgeting/Views/IncomeView.swift:690
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:690
  Def: private func adjustWeek(by delta: Int) {
  Dynamic-Risk Checklist: none flagged
- confirmDeleteIfNeeded (func) — OffshoreBudgeting/Views/IncomeView.swift:707
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:707
  Def: private func confirmDeleteIfNeeded() {
  Dynamic-Risk Checklist: none flagged
- sundayFirstCalendar (var) — OffshoreBudgeting/Views/IncomeView.swift:723
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:723
  Def: private var sundayFirstCalendar: Calendar {
  Dynamic-Risk Checklist: none flagged
- weekBounds (func) — OffshoreBudgeting/Views/IncomeView.swift:727
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:727
  Def: private func weekBounds(for date: Date) -> (start: Date, end: Date) {
  Dynamic-Risk Checklist: none flagged
- SheetDateBox (struct) — OffshoreBudgeting/Views/IncomeView.swift:736
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/IncomeView.swift:736
  Def: private struct SheetDateBox: Identifiable {
  Dynamic-Risk Checklist: none flagged
- ManageBudgetCardsSheet (struct) — OffshoreBudgeting/Views/ManageBudgetCardsSheet.swift:5
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ManageBudgetCardsSheet.swift:5
  Def: struct ManageBudgetCardsSheet: View {
  Dynamic-Risk Checklist: none flagged
- isAttached (func) — OffshoreBudgeting/Views/ManageBudgetCardsSheet.swift:58
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ManageBudgetCardsSheet.swift:58
  Def: private func isAttached(_ card: Card) -> Bool {
  Dynamic-Risk Checklist: none flagged
- attach (func) — OffshoreBudgeting/Views/ManageBudgetCardsSheet.swift:63
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ManageBudgetCardsSheet.swift:63
  Def: private func attach(_ card: Card) {
  Dynamic-Risk Checklist: none flagged
- detach (func) — OffshoreBudgeting/Views/ManageBudgetCardsSheet.swift:69
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ManageBudgetCardsSheet.swift:69
  Def: private func detach(_ card: Card) {
  Dynamic-Risk Checklist: none flagged
- ManageBudgetPresetsSheet (struct) — OffshoreBudgeting/Views/ManageBudgetPresetsSheet.swift:5
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ManageBudgetPresetsSheet.swift:5
  Def: struct ManageBudgetPresetsSheet: View {
  Dynamic-Risk Checklist: none flagged
- assignedTemplateObjectIDs (var) — OffshoreBudgeting/Views/ManageBudgetPresetsSheet.swift:14
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ManageBudgetPresetsSheet.swift:14
  Def: @State private var assignedTemplateObjectIDs: Set<NSManagedObjectID> = []
  Dynamic-Risk Checklist: none flagged
- presetRow (func) — OffshoreBudgeting/Views/ManageBudgetPresetsSheet.swift:68
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ManageBudgetPresetsSheet.swift:68
  Def: private func presetRow(for template: PlannedExpense) -> some View {
  Dynamic-Risk Checklist: none flagged
- updateAssignment (func) — OffshoreBudgeting/Views/ManageBudgetPresetsSheet.swift:104
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ManageBudgetPresetsSheet.swift:104
  Def: private func updateAssignment(for template: PlannedExpense, shouldAssign: Bool) {
  Dynamic-Risk Checklist: none flagged
- dismissAndComplete (func) — OffshoreBudgeting/Views/ManageBudgetPresetsSheet.swift:159
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/ManageBudgetPresetsSheet.swift:159
  Def: private func dismissAndComplete() {
  Dynamic-Risk Checklist: none flagged
- OnboardingView (struct) — OffshoreBudgeting/Views/OnboardingView.swift:5
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/OnboardingView.swift:5
  Def: struct OnboardingView: View {
  Dynamic-Risk Checklist: none flagged
- Step (enum) — OffshoreBudgeting/Views/OnboardingView.swift:11
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/OnboardingView.swift:11
  Def: enum Step { case welcome, categories, cards, presets, loading }
  Dynamic-Risk Checklist: none flagged
- WelcomeStep2 (struct) — OffshoreBudgeting/Views/OnboardingView.swift:54
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/OnboardingView.swift:54
  Def: private struct WelcomeStep2: View {
  Dynamic-Risk Checklist: none flagged
- CategoriesStep2 (struct) — OffshoreBudgeting/Views/OnboardingView.swift:75
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/OnboardingView.swift:75
  Def: private struct CategoriesStep2: View {
  Dynamic-Risk Checklist: none flagged
- CardsStep2 (struct) — OffshoreBudgeting/Views/OnboardingView.swift:90
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/OnboardingView.swift:90
  Def: private struct CardsStep2: View {
  Dynamic-Risk Checklist: none flagged
- PresetsStep2 (struct) — OffshoreBudgeting/Views/OnboardingView.swift:105
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/OnboardingView.swift:105
  Def: private struct PresetsStep2: View {
  Dynamic-Risk Checklist: none flagged
- LoadingStep2 (struct) — OffshoreBudgeting/Views/OnboardingView.swift:120
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/OnboardingView.swift:120
  Def: private struct LoadingStep2: View {
  Dynamic-Risk Checklist: none flagged
- onFinish (let) — OffshoreBudgeting/Views/OnboardingView.swift:121
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/OnboardingView.swift:121
  Def: let onFinish: () -> Void
  Dynamic-Risk Checklist: none flagged
- primaryButton (func) — OffshoreBudgeting/Views/OnboardingView.swift:150
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/OnboardingView.swift:150
  Def: private func primaryButton(title: String, action: @escaping () -> Void) -> some View {
  Dynamic-Risk Checklist: none flagged
- secondaryButton (func) — OffshoreBudgeting/Views/OnboardingView.swift:180
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/OnboardingView.swift:180
  Def: private func secondaryButton(title: String, action: @escaping () -> Void) -> some View {
  Dynamic-Risk Checklist: none flagged
- PresetBudgetAssignmentSheet (struct) — OffshoreBudgeting/Views/PresetBudgetAssignmentSheet.swift:15
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/PresetBudgetAssignmentSheet.swift:15
  Def: struct PresetBudgetAssignmentSheet: View {
  Dynamic-Risk Checklist: none flagged
- membership (var) — OffshoreBudgeting/Views/PresetBudgetAssignmentSheet.swift:30
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/PresetBudgetAssignmentSheet.swift:30
  Def: @State private var membership: [UUID: Bool] = [:] // Budget.id : isAssigned
  Dynamic-Risk Checklist: none flagged
- isAssigned (func) — OffshoreBudgeting/Views/PresetBudgetAssignmentSheet.swift:154
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/PresetBudgetAssignmentSheet.swift:154
  Def: private func isAssigned(to budget: Budget) -> Bool {
  Dynamic-Risk Checklist: none flagged
- toggleAssignment (func) — OffshoreBudgeting/Views/PresetBudgetAssignmentSheet.swift:159
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/PresetBudgetAssignmentSheet.swift:159
  Def: private func toggleAssignment(for budget: Budget, to newValue: Bool) {
  Dynamic-Risk Checklist: none flagged
- requestDeleteBudget (func) — OffshoreBudgeting/Views/PresetBudgetAssignmentSheet.swift:172
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/PresetBudgetAssignmentSheet.swift:172
  Def: private func requestDeleteBudget(_ budget: Budget) {
  Dynamic-Risk Checklist: none flagged
- performDeleteBudget (func) — OffshoreBudgeting/Views/PresetBudgetAssignmentSheet.swift:182
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/PresetBudgetAssignmentSheet.swift:182
  Def: private func performDeleteBudget() {
  Dynamic-Risk Checklist: none flagged
- dateSpanLabel (func) — OffshoreBudgeting/Views/PresetBudgetAssignmentSheet.swift:206
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/PresetBudgetAssignmentSheet.swift:206
  Def: private func dateSpanLabel(start: Date, end: Date) -> String {
  Dynamic-Risk Checklist: none flagged
- PresetRowView (struct) — OffshoreBudgeting/Views/PresetRowView.swift:21
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/PresetRowView.swift:21
  Def: struct PresetRowView: View {
  Dynamic-Risk Checklist: none flagged
- onAssignTapped (let) — OffshoreBudgeting/Views/PresetRowView.swift:27
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/PresetRowView.swift:27
  Def: let onAssignTapped: (PlannedExpense) -> Void
  Dynamic-Risk Checklist: none flagged
- titleRow (var) — OffshoreBudgeting/Views/PresetRowView.swift:43
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/PresetRowView.swift:43
  Def: private var titleRow: some View {
  Dynamic-Risk Checklist: none flagged
- assignButton (var) — OffshoreBudgeting/Views/PresetRowView.swift:70
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/PresetRowView.swift:70
  Def: private var assignButton: some View {
  Dynamic-Risk Checklist: none flagged
- amountsRow (var) — OffshoreBudgeting/Views/PresetRowView.swift:85
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/PresetRowView.swift:85
  Def: private var amountsRow: some View {
  Dynamic-Risk Checklist: none flagged
- nextDateBlock (func) — OffshoreBudgeting/Views/PresetRowView.swift:110
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/PresetRowView.swift:110
  Def: private func nextDateBlock(alignment: HorizontalAlignment) -> some View {
  Dynamic-Risk Checklist: none flagged
- AssignedBudgetsBadge (struct) — OffshoreBudgeting/Views/PresetRowView.swift:154
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/PresetRowView.swift:154
  Def: private struct AssignedBudgetsBadge: View {
  Dynamic-Risk Checklist: none flagged
- countCircleSize (var) — OffshoreBudgeting/Views/PresetRowView.swift:159
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/PresetRowView.swift:159
  Def: @ScaledMetric(relativeTo: .body) private var countCircleSize: CGFloat = 28
  Dynamic-Risk Checklist: none flagged
- titleColor (var) — OffshoreBudgeting/Views/PresetRowView.swift:189
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/PresetRowView.swift:189
  Def: private var titleColor: Color {
  Dynamic-Risk Checklist: none flagged
- circleBackgroundColor (var) — OffshoreBudgeting/Views/PresetRowView.swift:193
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/PresetRowView.swift:193
  Def: private var circleBackgroundColor: Color {
  Dynamic-Risk Checklist: none flagged
- circleForegroundColor (var) — OffshoreBudgeting/Views/PresetRowView.swift:201
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/PresetRowView.swift:201
  Def: private var circleForegroundColor: Color {
  Dynamic-Risk Checklist: none flagged
- circleBackgroundColorLight (var) — OffshoreBudgeting/Views/PresetRowView.swift:205
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/PresetRowView.swift:205
  Def: private var circleBackgroundColorLight: Color {
  Dynamic-Risk Checklist: none flagged
- circleBackgroundColorDark (var) — OffshoreBudgeting/Views/PresetRowView.swift:215
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/PresetRowView.swift:215
  Def: private var circleBackgroundColorDark: Color {
  Dynamic-Risk Checklist: none flagged
- isPresentingAdd (var) — OffshoreBudgeting/Views/PresetsView.swift:18
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/PresetsView.swift:18
  Def: @State private var isPresentingAdd = false
  Dynamic-Risk Checklist: none flagged
- sheetTemplateToAssign (var) — OffshoreBudgeting/Views/PresetsView.swift:19
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/PresetsView.swift:19
  Def: @State private var sheetTemplateToAssign: PlannedExpense? = nil
  Dynamic-Risk Checklist: none flagged
- editingTemplate (var) — OffshoreBudgeting/Views/PresetsView.swift:20
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/PresetsView.swift:20
  Def: @State private var editingTemplate: PlannedExpense? = nil
  Dynamic-Risk Checklist: none flagged
- templateToDelete (var) — OffshoreBudgeting/Views/PresetsView.swift:21
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/PresetsView.swift:21
  Def: @State private var templateToDelete: PlannedExpense? = nil
  Dynamic-Risk Checklist: none flagged
- presetsContent (var) — OffshoreBudgeting/Views/PresetsView.swift:32
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/PresetsView.swift:32
  Def: private var presetsContent: some View {
  Dynamic-Risk Checklist: none flagged
- AddGlobalPresetSheet (struct) — OffshoreBudgeting/Views/PresetsView.swift:143
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/PresetsView.swift:143
  Def: private struct AddGlobalPresetSheet: View {
  Dynamic-Risk Checklist: none flagged
- RecurrencePickerView (struct) — OffshoreBudgeting/Views/RecurrencePickerView.swift:14
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/RecurrencePickerView.swift:14
  Def: struct RecurrencePickerView: View {
  Dynamic-Risk Checklist: none flagged
- Preset (enum) — OffshoreBudgeting/Views/RecurrencePickerView.swift:31
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/RecurrencePickerView.swift:31
  Def: enum Preset: String, CaseIterable, Identifiable {
  Dynamic-Risk Checklist: none flagged
- seedFromRuleIfNeeded (func) — OffshoreBudgeting/Views/RecurrencePickerView.swift:114
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/RecurrencePickerView.swift:114
  Def: private func seedFromRuleIfNeeded() {
  Dynamic-Risk Checklist: none flagged
- WeekdayPicker (struct) — OffshoreBudgeting/Views/RecurrencePickerView.swift:194
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/RecurrencePickerView.swift:194
  Def: private struct WeekdayPicker: View {
  Dynamic-Risk Checklist: none flagged
- shortName (func) — OffshoreBudgeting/Views/RecurrencePickerView.swift:209
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/RecurrencePickerView.swift:209
  Def: private func shortName(for day: Weekday) -> String {
  Dynamic-Risk Checklist: none flagged
- DayOfMonthPicker (struct) — OffshoreBudgeting/Views/RecurrencePickerView.swift:223
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/RecurrencePickerView.swift:223
  Def: private struct DayOfMonthPicker: View {
  Dynamic-Risk Checklist: none flagged
- RenameCardSheet (struct) — OffshoreBudgeting/Views/RenameCardSheet.swift:16
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/RenameCardSheet.swift:16
  Def: struct RenameCardSheet: View {
  Dynamic-Risk Checklist: none flagged
- originalName (let) — OffshoreBudgeting/Views/RenameCardSheet.swift:17
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/RenameCardSheet.swift:17
  Def: let originalName: String
  Dynamic-Risk Checklist: none flagged
- showMergeConfirm (var) — OffshoreBudgeting/Views/SettingsView.swift:22
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:22
  Def: @State private var showMergeConfirm = false
  Dynamic-Risk Checklist: none flagged
- showForceReuploadConfirm (var) — OffshoreBudgeting/Views/SettingsView.swift:23
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:23
  Def: @State private var showForceReuploadConfirm = false
  Dynamic-Risk Checklist: none flagged
- showForceReuploadResult (var) — OffshoreBudgeting/Views/SettingsView.swift:24
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:24
  Def: @State private var showForceReuploadResult = false
  Dynamic-Risk Checklist: none flagged
- forceReuploadMessage (var) — OffshoreBudgeting/Views/SettingsView.swift:25
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:25
  Def: @State private var forceReuploadMessage: String = ""
  Dynamic-Risk Checklist: none flagged
- isMerging (var) — OffshoreBudgeting/Views/SettingsView.swift:26
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:26
  Def: @State private var isMerging = false
  Dynamic-Risk Checklist: none flagged
- showMergeDone (var) — OffshoreBudgeting/Views/SettingsView.swift:28
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:28
  Def: @State private var showMergeDone = false
  Dynamic-Risk Checklist: none flagged
- showDisableCloudOptions (var) — OffshoreBudgeting/Views/SettingsView.swift:29
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:29
  Def: @State private var showDisableCloudOptions = false
  Dynamic-Risk Checklist: none flagged
- cloudDiag (var) — OffshoreBudgeting/Views/SettingsView.swift:31
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:31
  Def: @StateObject private var cloudDiag = CloudDiagnostics.shared
  Dynamic-Risk Checklist: none flagged
- settingsContent (var) — OffshoreBudgeting/Views/SettingsView.swift:48
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:48
  Def: private var settingsContent: some View {
  Dynamic-Risk Checklist: none flagged
- settingsList (var) — OffshoreBudgeting/Views/SettingsView.swift:158
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:158
  Def: private var settingsList: some View {
  Dynamic-Risk Checklist: none flagged
- appSection (var) — OffshoreBudgeting/Views/SettingsView.swift:168
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:168
  Def: private var appSection: some View {
  Dynamic-Risk Checklist: none flagged
- generalSection (var) — OffshoreBudgeting/Views/SettingsView.swift:189
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:189
  Def: private var generalSection: some View {
  Dynamic-Risk Checklist: none flagged
- categoriesSection (var) — OffshoreBudgeting/Views/SettingsView.swift:230
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:230
  Def: private var categoriesSection: some View {
  Dynamic-Risk Checklist: none flagged
- presetsSection (var) — OffshoreBudgeting/Views/SettingsView.swift:244
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:244
  Def: private var presetsSection: some View {
  Dynamic-Risk Checklist: none flagged
- performDataWipe (func) — OffshoreBudgeting/Views/SettingsView.swift:258
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:258
  Def: private func performDataWipe() {
  Dynamic-Risk Checklist: none flagged
- runMerge (func) — OffshoreBudgeting/Views/SettingsView.swift:267
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:267
  Def: private func runMerge() {
  Dynamic-Risk Checklist: none flagged
- disableCloud (func) — OffshoreBudgeting/Views/SettingsView.swift:281
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:281
  Def: private func disableCloud(eraseLocal: Bool) {
  Dynamic-Risk Checklist: none flagged
- cloudToggleBinding (var) — OffshoreBudgeting/Views/SettingsView.swift:303
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:303
  Def: var cloudToggleBinding: Binding<Bool> {
  Dynamic-Risk Checklist: none flagged
- overlayStatusLabel (var) — OffshoreBudgeting/Views/SettingsView.swift:329
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:329
  Def: var overlayStatusLabel: String? {
  Dynamic-Risk Checklist: none flagged
- forceReupload (func) — OffshoreBudgeting/Views/SettingsView.swift:338
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:338
  Def: private func forceReupload() {
  Dynamic-Risk Checklist: none flagged
- appDisplayName (var) — OffshoreBudgeting/Views/SettingsView.swift:382
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:382
  Def: var appDisplayName: String {
  Dynamic-Risk Checklist: none flagged
- bundleName (let) — OffshoreBudgeting/Views/SettingsView.swift:385
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:385
  Def: let bundleName = info?["CFBundleName"] as? String
  Dynamic-Risk Checklist: none flagged
- iconTextSpacing (var) — OffshoreBudgeting/Views/SettingsView.swift:407
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:407
  Def: @ScaledMetric(relativeTo: .body) private var iconTextSpacing: CGFloat = 16
  Dynamic-Risk Checklist: none flagged
- SettingsIconStyle (enum) — OffshoreBudgeting/Views/SettingsView.swift:431
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:431
  Def: private enum SettingsIconStyle {
  Dynamic-Risk Checklist: none flagged
- SettingsIconTile (struct) — OffshoreBudgeting/Views/SettingsView.swift:481
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:481
  Def: private struct SettingsIconTile: View {
  Dynamic-Risk Checklist: none flagged
- AppInfoRow (struct) — OffshoreBudgeting/Views/SettingsView.swift:505
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:505
  Def: private struct AppInfoRow: View {
  Dynamic-Risk Checklist: none flagged
- AppInfoView (struct) — OffshoreBudgeting/Views/SettingsView.swift:534
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:534
  Def: private struct AppInfoView: View {
  Dynamic-Risk Checklist: none flagged
- appVersionLine (var) — OffshoreBudgeting/Views/SettingsView.swift:593
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:593
  Def: private var appVersionLine: String {
  Dynamic-Risk Checklist: none flagged
- appInfoIconSize (var) — OffshoreBudgeting/Views/SettingsView.swift:600
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:600
  Def: private var appInfoIconSize: CGFloat {
  Dynamic-Risk Checklist: none flagged
- ReleaseLogsView (struct) — OffshoreBudgeting/Views/SettingsView.swift:613
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:613
  Def: private struct ReleaseLogsView: View {
  Dynamic-Risk Checklist: none flagged
- releaseTitle (func) — OffshoreBudgeting/Views/SettingsView.swift:629
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:629
  Def: private func releaseTitle(for versionToken: String) -> String {
  Dynamic-Risk Checklist: none flagged
- ReleaseLogItemRow (struct) — OffshoreBudgeting/Views/SettingsView.swift:638
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:638
  Def: private struct ReleaseLogItemRow: View {
  Dynamic-Risk Checklist: none flagged
- GeneralSettingsView (struct) — OffshoreBudgeting/Views/SettingsView.swift:667
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:667
  Def: private struct GeneralSettingsView: View {
  Dynamic-Risk Checklist: none flagged
- selectedBudgetPeriod (var) — OffshoreBudgeting/Views/SettingsView.swift:671
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:671
  Def: @State private var selectedBudgetPeriod: BudgetPeriod = .monthly
  Dynamic-Risk Checklist: none flagged
- tipsResetButton (var) — OffshoreBudgeting/Views/SettingsView.swift:742
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:742
  Def: private var tipsResetButton: some View {
  Dynamic-Risk Checklist: none flagged
- PrivacySettingsView (struct) — OffshoreBudgeting/Views/SettingsView.swift:770
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:770
  Def: private struct PrivacySettingsView: View {
  Dynamic-Risk Checklist: none flagged
- isPasscodeAvailable (var) — OffshoreBudgeting/Views/SettingsView.swift:775
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:775
  Def: @State private var isPasscodeAvailable: Bool = true
  Dynamic-Risk Checklist: none flagged
- isRequestingAppLock (var) — OffshoreBudgeting/Views/SettingsView.swift:777
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:777
  Def: @State private var isRequestingAppLock: Bool = false
  Dynamic-Risk Checklist: none flagged
- footerText (let) — OffshoreBudgeting/Views/SettingsView.swift:780
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:780
  Def: let footerText = supportsBiometrics
  Dynamic-Risk Checklist: none flagged
- refreshAvailability (func) — OffshoreBudgeting/Views/SettingsView.swift:819
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:819
  Def: private func refreshAvailability() {
  Dynamic-Risk Checklist: none flagged
- requestAppLockEnablementIfNeeded (func) — OffshoreBudgeting/Views/SettingsView.swift:832
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:832
  Def: private func requestAppLockEnablementIfNeeded() {
  Dynamic-Risk Checklist: none flagged
- NotificationsSettingsView (struct) — OffshoreBudgeting/Views/SettingsView.swift:860
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:860
  Def: private struct NotificationsSettingsView: View {
  Dynamic-Risk Checklist: none flagged
- enableDailyReminder (var) — OffshoreBudgeting/Views/SettingsView.swift:861
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:861
  Def: @AppStorage(AppSettingsKeys.enableDailyReminder.rawValue) private var enableDailyReminder: Bool = false
  Dynamic-Risk Checklist: none flagged
- enablePlannedIncomeReminder (var) — OffshoreBudgeting/Views/SettingsView.swift:862
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:862
  Def: @AppStorage(AppSettingsKeys.enablePlannedIncomeReminder.rawValue) private var enablePlannedIncomeReminder: Bool = false
  Dynamic-Risk Checklist: none flagged
- silencePresetWithActualAmount (var) — OffshoreBudgeting/Views/SettingsView.swift:864
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:864
  Def: @AppStorage(AppSettingsKeys.silencePresetWithActualAmount.rawValue) private var silencePresetWithActualAmount: Bool = false
  Dynamic-Risk Checklist: none flagged
- excludeNonGlobalPresetExpenses (var) — OffshoreBudgeting/Views/SettingsView.swift:865
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:865
  Def: @AppStorage(AppSettingsKeys.excludeNonGlobalPresetExpenses.rawValue) private var excludeNonGlobalPresetExpenses: Bool = false
  Dynamic-Risk Checklist: none flagged
- reminderTimeMinutes (var) — OffshoreBudgeting/Views/SettingsView.swift:866
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:866
  Def: @AppStorage(AppSettingsKeys.notificationReminderTimeMinutes.rawValue) private var reminderTimeMinutes: Int = 20 * 60
  Dynamic-Risk Checklist: none flagged
- authorizationStatus (var) — OffshoreBudgeting/Views/SettingsView.swift:867
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:867
  Def: @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
  Dynamic-Risk Checklist: none flagged
- showPermissionAlert (var) — OffshoreBudgeting/Views/SettingsView.swift:868
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:868
  Def: @State private var showPermissionAlert = false
  Dynamic-Risk Checklist: none flagged
- permissionButton (var) — OffshoreBudgeting/Views/SettingsView.swift:923
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:923
  Def: private var permissionButton: some View {
  Dynamic-Risk Checklist: none flagged
- settingsButton (var) — OffshoreBudgeting/Views/SettingsView.swift:969
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:969
  Def: private var settingsButton: some View {
  Dynamic-Risk Checklist: none flagged
- settingsButtonBackground (var) — OffshoreBudgeting/Views/SettingsView.swift:1000
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:1000
  Def: private var settingsButtonBackground: Color {
  Dynamic-Risk Checklist: none flagged
- reminderTimeBinding (var) — OffshoreBudgeting/Views/SettingsView.swift:1010
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:1010
  Def: private var reminderTimeBinding: Binding<Date> {
  Dynamic-Risk Checklist: none flagged
- requestPermission (func) — OffshoreBudgeting/Views/SettingsView.swift:1048
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:1048
  Def: private func requestPermission() async {
  Dynamic-Risk Checklist: none flagged
- disableRemindersAndAlert (func) — OffshoreBudgeting/Views/SettingsView.swift:1066
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:1066
  Def: private func disableRemindersAndAlert() async {
  Dynamic-Risk Checklist: none flagged
- ICloudSettingsView (struct) — OffshoreBudgeting/Views/SettingsView.swift:1086
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:1086
  Def: private struct ICloudSettingsView: View {
  Dynamic-Risk Checklist: none flagged
- widgetSyncToggle (var) — OffshoreBudgeting/Views/SettingsView.swift:1088
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:1088
  Def: @Binding var widgetSyncToggle: Bool
  Dynamic-Risk Checklist: none flagged
- forceRefreshButton (var) — OffshoreBudgeting/Views/SettingsView.swift:1115
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:1115
  Def: private var forceRefreshButton: some View {
  Dynamic-Risk Checklist: none flagged
- AppIconShape (enum) — OffshoreBudgeting/Views/SettingsView.swift:1157
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:1157
  Def: private enum AppIconShape {
  Dynamic-Risk Checklist: none flagged
- AppIconImageView (struct) — OffshoreBudgeting/Views/SettingsView.swift:1162
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:1162
  Def: private struct AppIconImageView: View {
  Dynamic-Risk Checklist: none flagged
- mask (let) — OffshoreBudgeting/Views/SettingsView.swift:1180
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:1180
  Def: let mask = RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
  Dynamic-Risk Checklist: none flagged
- AppIconProvider (enum) — OffshoreBudgeting/Views/SettingsView.swift:1192
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:1192
  Def: private enum AppIconProvider {
  Dynamic-Risk Checklist: none flagged
- currentIconGraphic (var) — OffshoreBudgeting/Views/SettingsView.swift:1193
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/SettingsView.swift:1193
  Def: static var currentIconGraphic: AppIconGraphic? {
  Dynamic-Risk Checklist: none flagged
- resolvedTitle (var) — OffshoreBudgeting/Views/UBEmptyState.swift:113
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/UBEmptyState.swift:113
  Def: private var resolvedTitle: String? {
  Dynamic-Risk Checklist: none flagged
- messageFont (var) — OffshoreBudgeting/Views/UBEmptyState.swift:119
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/UBEmptyState.swift:119
  Def: private var messageFont: Font {
  Dynamic-Risk Checklist: none flagged
- messageForeground (var) — OffshoreBudgeting/Views/UBEmptyState.swift:123
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/UBEmptyState.swift:123
  Def: private var messageForeground: Color {
  Dynamic-Risk Checklist: none flagged
- resolvedVerticalPadding (var) — OffshoreBudgeting/Views/UBEmptyState.swift:127
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/UBEmptyState.swift:127
  Def: private var resolvedVerticalPadding: CGFloat {
  Dynamic-Risk Checklist: none flagged
- onboardingTint (var) — OffshoreBudgeting/Views/UBEmptyState.swift:131
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/UBEmptyState.swift:131
  Def: private var onboardingTint: Color {
  Dynamic-Risk Checklist: none flagged
- primaryButton (func) — OffshoreBudgeting/Views/UBEmptyState.swift:137
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/UBEmptyState.swift:137
  Def: private func primaryButton(title: String, action: @escaping () -> Void) -> some View {
  Dynamic-Risk Checklist: none flagged
- legacyPrimaryButton (func) — OffshoreBudgeting/Views/UBEmptyState.swift:150
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/UBEmptyState.swift:150
  Def: private func legacyPrimaryButton(title: String, action: @escaping () -> Void) -> some View {
  Dynamic-Risk Checklist: none flagged
- primaryButtonLabel (func) — OffshoreBudgeting/Views/UBEmptyState.swift:159
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/UBEmptyState.swift:159
  Def: private func primaryButtonLabel(title: String) -> some View {
  Dynamic-Risk Checklist: none flagged
- glassPrimaryButton (func) — OffshoreBudgeting/Views/UBEmptyState.swift:166
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/UBEmptyState.swift:166
  Def: private func glassPrimaryButton(
  Dynamic-Risk Checklist: none flagged
- glassStyledPrimaryButton (func) — OffshoreBudgeting/Views/UBEmptyState.swift:181
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/UBEmptyState.swift:181
  Def: private func glassStyledPrimaryButton(
  Dynamic-Risk Checklist: none flagged
- primaryButtonForegroundColor (func) — OffshoreBudgeting/Views/UBEmptyState.swift:200
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/UBEmptyState.swift:200
  Def: private func primaryButtonForegroundColor(isTintedBackground: Bool = false) -> Color {
  Dynamic-Risk Checklist: none flagged
- primaryButtonTint (var) — OffshoreBudgeting/Views/UBEmptyState.swift:209
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/UBEmptyState.swift:209
  Def: private var primaryButtonTint: Color {
  Dynamic-Risk Checklist: none flagged
- primaryButtonGlassTint (var) — OffshoreBudgeting/Views/UBEmptyState.swift:213
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/UBEmptyState.swift:213
  Def: private var primaryButtonGlassTint: Color {
  Dynamic-Risk Checklist: none flagged
- WorkspaceMenuButton (struct) — OffshoreBudgeting/Views/WorkspaceProfilesView.swift:6
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/WorkspaceProfilesView.swift:6
  Def: struct WorkspaceMenuButton: View {
  Dynamic-Risk Checklist: none flagged
- showAdd (var) — OffshoreBudgeting/Views/WorkspaceProfilesView.swift:14
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/WorkspaceProfilesView.swift:14
  Def: @State private var showAdd = false
  Dynamic-Risk Checklist: none flagged
- showManage (var) — OffshoreBudgeting/Views/WorkspaceProfilesView.swift:15
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/WorkspaceProfilesView.swift:15
  Def: @State private var showManage = false
  Dynamic-Risk Checklist: none flagged
- menuButtonSize (var) — OffshoreBudgeting/Views/WorkspaceProfilesView.swift:16
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/WorkspaceProfilesView.swift:16
  Def: @ScaledMetric(relativeTo: .body) private var menuButtonSize: CGFloat = 33
  Dynamic-Risk Checklist: none flagged
- menuButtonPadding (var) — OffshoreBudgeting/Views/WorkspaceProfilesView.swift:17
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/WorkspaceProfilesView.swift:17
  Def: @ScaledMetric(relativeTo: .body) private var menuButtonPadding: CGFloat = 6
  Dynamic-Risk Checklist: none flagged
- menuDotSize (var) — OffshoreBudgeting/Views/WorkspaceProfilesView.swift:18
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/WorkspaceProfilesView.swift:18
  Def: @ScaledMetric(relativeTo: .body) private var menuDotSize: CGFloat = 14
  Dynamic-Risk Checklist: none flagged
- menuContent (var) — OffshoreBudgeting/Views/WorkspaceProfilesView.swift:42
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/WorkspaceProfilesView.swift:42
  Def: private var menuContent: some View {
  Dynamic-Risk Checklist: none flagged
- workspaceListSection (var) — OffshoreBudgeting/Views/WorkspaceProfilesView.swift:57
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/WorkspaceProfilesView.swift:57
  Def: private var workspaceListSection: some View {
  Dynamic-Risk Checklist: none flagged
- workspaceMenuLabel (var) — OffshoreBudgeting/Views/WorkspaceProfilesView.swift:78
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/WorkspaceProfilesView.swift:78
  Def: private var workspaceMenuLabel: some View {
  Dynamic-Risk Checklist: none flagged
- iconColor (let) — OffshoreBudgeting/Views/WorkspaceProfilesView.swift:79
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/WorkspaceProfilesView.swift:79
  Def: let iconColor = activeWorkspaceColor
  Dynamic-Risk Checklist: none flagged
- activeWorkspaceColor (var) — OffshoreBudgeting/Views/WorkspaceProfilesView.swift:110
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/WorkspaceProfilesView.swift:110
  Def: private var activeWorkspaceColor: Color {
  Dynamic-Risk Checklist: none flagged
- activeWorkspaceColorHex (var) — OffshoreBudgeting/Views/WorkspaceProfilesView.swift:114
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/WorkspaceProfilesView.swift:114
  Def: private var activeWorkspaceColorHex: String {
  Dynamic-Risk Checklist: none flagged
- WorkspaceColorDot (struct) — OffshoreBudgeting/Views/WorkspaceProfilesView.swift:124
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/WorkspaceProfilesView.swift:124
  Def: struct WorkspaceColorDot: View {
  Dynamic-Risk Checklist: none flagged
- WorkspaceManagerView (struct) — OffshoreBudgeting/Views/WorkspaceProfilesView.swift:141
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/WorkspaceProfilesView.swift:141
  Def: struct WorkspaceManagerView: View {
  Dynamic-Risk Checklist: none flagged
- editingWorkspace (var) — OffshoreBudgeting/Views/WorkspaceProfilesView.swift:150
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/WorkspaceProfilesView.swift:150
  Def: @State private var editingWorkspace: Workspace?
  Dynamic-Risk Checklist: none flagged
- showAddSheet (var) — OffshoreBudgeting/Views/WorkspaceProfilesView.swift:152
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/WorkspaceProfilesView.swift:152
  Def: @State private var showAddSheet = false
  Dynamic-Risk Checklist: none flagged
- rowDotSize (var) — OffshoreBudgeting/Views/WorkspaceProfilesView.swift:153
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/WorkspaceProfilesView.swift:153
  Def: @ScaledMetric(relativeTo: .body) private var rowDotSize: CGFloat = 18
  Dynamic-Risk Checklist: none flagged
- workspaceRow (func) — OffshoreBudgeting/Views/WorkspaceProfilesView.swift:200
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/WorkspaceProfilesView.swift:200
  Def: private func workspaceRow(for workspace: Workspace) -> some View {
  Dynamic-Risk Checklist: none flagged
- loadInitialName (func) — OffshoreBudgeting/Views/WorkspaceProfilesView.swift:305
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/WorkspaceProfilesView.swift:305
  Def: private func loadInitialName() {
  Dynamic-Risk Checklist: none flagged
- WorkspaceSetupView (struct) — OffshoreBudgeting/Views/WorkspaceSetupView.swift:6
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/WorkspaceSetupView.swift:6
  Def: struct WorkspaceSetupView: View {
  Dynamic-Risk Checklist: none flagged
- isSyncing (let) — OffshoreBudgeting/Views/WorkspaceSetupView.swift:7
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/WorkspaceSetupView.swift:7
  Def: let isSyncing: Bool
  Dynamic-Risk Checklist: none flagged
- corner (let) — OffshoreBudgeting/Views/WorkspaceSetupView.swift:17
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/WorkspaceSetupView.swift:17
  Def: let corner = max(16, min(proxy.size.width, proxy.size.height) * 0.04)
  Dynamic-Risk Checklist: none flagged
- BudgetMetricsTests (class) — OffshoreBudgetingTests/BudgetMetricsTests.swift:4
  Evidence: 0 refs (token-based); def at OffshoreBudgetingTests/BudgetMetricsTests.swift:4
  Def: final class BudgetMetricsTests: XCTestCase {
  Dynamic-Risk Checklist: none flagged
- testExpenseToIncomeFlagsCashDeficitWhenExpensesExceedReceivedIncome (func) — OffshoreBudgetingTests/BudgetMetricsTests.swift:6
  Evidence: 0 refs (token-based); def at OffshoreBudgetingTests/BudgetMetricsTests.swift:6
  Def: func testExpenseToIncomeFlagsCashDeficitWhenExpensesExceedReceivedIncome() {
  Dynamic-Risk Checklist: none flagged
- testExpenseToIncomeDetectsOverExpectedWhenCashPositive (func) — OffshoreBudgetingTests/BudgetMetricsTests.swift:19
  Evidence: 0 refs (token-based); def at OffshoreBudgetingTests/BudgetMetricsTests.swift:19
  Def: func testExpenseToIncomeDetectsOverExpectedWhenCashPositive() {
  Dynamic-Risk Checklist: none flagged
- testSavingsOutlookUsesRemainingIncomeWithoutDoubleCounting (func) — OffshoreBudgetingTests/BudgetMetricsTests.swift:32
  Evidence: 0 refs (token-based); def at OffshoreBudgetingTests/BudgetMetricsTests.swift:32
  Def: func testSavingsOutlookUsesRemainingIncomeWithoutDoubleCounting() {
  Dynamic-Risk Checklist: none flagged
- testSavingsOutlookSubtractsRemainingPlannedExpenses (func) — OffshoreBudgetingTests/BudgetMetricsTests.swift:46
  Evidence: 0 refs (token-based); def at OffshoreBudgetingTests/BudgetMetricsTests.swift:46
  Def: func testSavingsOutlookSubtractsRemainingPlannedExpenses() {
  Dynamic-Risk Checklist: none flagged
- HomeViewSummaryTests (class) — OffshoreBudgetingTests/HomeViewSummaryTests.swift:5
  Evidence: 0 refs (token-based); def at OffshoreBudgetingTests/HomeViewSummaryTests.swift:5
  Def: final class HomeViewSummaryTests: XCTestCase {
  Dynamic-Risk Checklist: none flagged
- originalTimeZone (var) — OffshoreBudgetingTests/HomeViewSummaryTests.swift:7
  Evidence: 0 refs (token-based); def at OffshoreBudgetingTests/HomeViewSummaryTests.swift:7
  Def: private var originalTimeZone: TimeZone?
  Dynamic-Risk Checklist: none flagged
- testSummaryForCurrentMonth (func) — OffshoreBudgetingTests/HomeViewSummaryTests.swift:27
  Evidence: 0 refs (token-based); def at OffshoreBudgetingTests/HomeViewSummaryTests.swift:27
  Def: func testSummaryForCurrentMonth() throws {
  Dynamic-Risk Checklist: none flagged
- testSummaryForCustomRange (func) — OffshoreBudgetingTests/HomeViewSummaryTests.swift:67
  Evidence: 0 refs (token-based); def at OffshoreBudgetingTests/HomeViewSummaryTests.swift:67
  Def: func testSummaryForCustomRange() throws {
  Dynamic-Risk Checklist: none flagged
- testSummaryForCurrentQuarter (func) — OffshoreBudgetingTests/HomeViewSummaryTests.swift:107
  Evidence: 0 refs (token-based); def at OffshoreBudgetingTests/HomeViewSummaryTests.swift:107
  Def: func testSummaryForCurrentQuarter() throws {
  Dynamic-Risk Checklist: none flagged
- testSummaryForYearlyRange (func) — OffshoreBudgetingTests/HomeViewSummaryTests.swift:146
  Evidence: 0 refs (token-based); def at OffshoreBudgetingTests/HomeViewSummaryTests.swift:146
  Def: func testSummaryForYearlyRange() throws {
  Dynamic-Risk Checklist: none flagged
- expensesTotal (var) — OffshoreBudgetingTests/HomeViewSummaryTests.swift:220
  Evidence: 0 refs (token-based); def at OffshoreBudgetingTests/HomeViewSummaryTests.swift:220
  Def: var expensesTotal: Double { plannedExpensesActual + variableExpenses }
  Dynamic-Risk Checklist: none flagged
- assertSummary (func) — OffshoreBudgetingTests/HomeViewSummaryTests.swift:335
  Evidence: 0 refs (token-based); def at OffshoreBudgetingTests/HomeViewSummaryTests.swift:335
  Def: private func assertSummary(_ summary: BudgetSummary, matches expected: ExpectedTotals, file: StaticString = #file, line: UInt = #line) {
  Dynamic-Risk Checklist: none flagged
- assertWidgetMetrics (func) — OffshoreBudgetingTests/HomeViewSummaryTests.swift:344
  Evidence: 0 refs (token-based); def at OffshoreBudgetingTests/HomeViewSummaryTests.swift:344
  Def: private func assertWidgetMetrics(_ summary: BudgetSummary, matches expected: ExpectedTotals, file: StaticString = #file, line: UInt = #line) {
  Dynamic-Risk Checklist: none flagged
- makeInMemoryContext (func) — OffshoreBudgetingTests/HomeViewSummaryTests.swift:368
  Evidence: 0 refs (token-based); def at OffshoreBudgetingTests/HomeViewSummaryTests.swift:368
  Def: private func makeInMemoryContext(file: StaticString = #file, line: UInt = #line) throws -> NSManagedObjectContext {
  Dynamic-Risk Checklist: none flagged
- themeName (let) — OffshoreWidgets/CardWidget.swift:35
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CardWidget.swift:35
  Def: let themeName: String?
  Dynamic-Risk Checklist: none flagged
- patternName (let) — OffshoreWidgets/CardWidget.swift:38
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CardWidget.swift:38
  Def: let patternName: String?
  Dynamic-Risk Checklist: none flagged
- defaultCardID (func) — OffshoreWidgets/CardWidget.swift:65
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CardWidget.swift:65
  Def: static func defaultCardID() -> String? {
  Dynamic-Risk Checklist: none flagged
- CardWidgetListMode (enum) — OffshoreWidgets/CardWidget.swift:101
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CardWidget.swift:101
  Def: enum CardWidgetListMode: String, CaseIterable, AppEnum {
  Dynamic-Risk Checklist: none flagged
- caseDisplayRepresentations (var) — OffshoreWidgets/CardWidget.swift:107
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CardWidget.swift:107
  Def: static var caseDisplayRepresentations: [CardWidgetListMode: DisplayRepresentation] = [
  Dynamic-Risk Checklist: none flagged
- defaultQuery (var) — OffshoreWidgets/CardWidget.swift:116
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CardWidget.swift:116
  Def: static var defaultQuery = CardWidgetCardQuery()
  Dynamic-Risk Checklist: none flagged
- displayRepresentation (var) — OffshoreWidgets/CardWidget.swift:123
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CardWidget.swift:123
  Def: var displayRepresentation: DisplayRepresentation {
  Dynamic-Risk Checklist: none flagged
- CardWidgetCardQuery (struct) — OffshoreWidgets/CardWidget.swift:129
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CardWidget.swift:129
  Def: struct CardWidgetCardQuery: EntityQuery {
  Dynamic-Risk Checklist: none flagged
- suggestedEntities (func) — OffshoreWidgets/CardWidget.swift:143
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CardWidget.swift:143
  Def: func suggestedEntities() async throws -> [CardWidgetCard] {
  Dynamic-Risk Checklist: none flagged
- CardWidgetIntentProvider (struct) — OffshoreWidgets/CardWidget.swift:156
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CardWidget.swift:156
  Def: struct CardWidgetIntentProvider: AppIntentTimelineProvider {
  Dynamic-Risk Checklist: none flagged
- timeline (func) — OffshoreWidgets/CardWidget.swift:181
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CardWidget.swift:181
  Def: func timeline(for configuration: CardWidgetConfigurationIntent, in context: Context) async -> Timeline<CardWidgetEntry> {
  Dynamic-Risk Checklist: none flagged
- CardWidgetView (struct) — OffshoreWidgets/CardWidget.swift:212
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CardWidget.swift:212
  Def: struct CardWidgetView: View {
  Dynamic-Risk Checklist: none flagged
- cardEntry (let) — OffshoreWidgets/CardWidget.swift:220
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CardWidget.swift:220
  Def: let cardEntry = CardWidgetStore.readCards().first { $0.id == cardID }
  Dynamic-Risk Checklist: none flagged
- smallLayout (func) — OffshoreWidgets/CardWidget.swift:260
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CardWidget.swift:260
  Def: private func smallLayout(cardName: String, primaryHex: String?, secondaryHex: String?, totalSpent: Double) -> some View {
  Dynamic-Risk Checklist: none flagged
- mediumLayout (func) — OffshoreWidgets/CardWidget.swift:275
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CardWidget.swift:275
  Def: private func mediumLayout(cardName: String, primaryHex: String?, secondaryHex: String?, transactions: [CardWidgetStore.CardSnapshot.Transaction]) -> some View {
  Dynamic-Risk Checklist: none flagged
- largeLayout (func) — OffshoreWidgets/CardWidget.swift:288
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CardWidget.swift:288
  Def: private func largeLayout(cardName: String, primaryHex: String?, secondaryHex: String?, transactions: [CardWidgetStore.CardSnapshot.Transaction]) -> some View {
  Dynamic-Risk Checklist: none flagged
- transactionList (func) — OffshoreWidgets/CardWidget.swift:298
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CardWidget.swift:298
  Def: private func transactionList(_ transactions: [CardWidgetStore.CardSnapshot.Transaction]) -> some View {
  Dynamic-Risk Checklist: none flagged
- transactionRow (func) — OffshoreWidgets/CardWidget.swift:316
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CardWidget.swift:316
  Def: private func transactionRow(_ transaction: CardWidgetStore.CardSnapshot.Transaction) -> some View {
  Dynamic-Risk Checklist: none flagged
- CardWidget (struct) — OffshoreWidgets/CardWidget.swift:352
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CardWidget.swift:352
  Def: struct CardWidget: Widget {
  Dynamic-Risk Checklist: none flagged
- defaultSegmentKey (let) — OffshoreWidgets/CategoryAvailabilityWidget.swift:9
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategoryAvailabilityWidget.swift:9
  Def: private static let defaultSegmentKey = "widget.categoryAvailability.defaultSegment"
  Dynamic-Risk Checklist: none flagged
- defaultSortKey (let) — OffshoreWidgets/CategoryAvailabilityWidget.swift:10
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategoryAvailabilityWidget.swift:10
  Def: private static let defaultSortKey = "widget.categoryAvailability.defaultSort"
  Dynamic-Risk Checklist: none flagged
- readCategories (func) — OffshoreWidgets/CategoryAvailabilityWidget.swift:62
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategoryAvailabilityWidget.swift:62
  Def: static func readCategories() -> [String] {
  Dynamic-Risk Checklist: none flagged
- caseDisplayRepresentations (var) — OffshoreWidgets/CategoryAvailabilityWidget.swift:89
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategoryAvailabilityWidget.swift:89
  Def: static var caseDisplayRepresentations: [CategoryAvailabilityWidgetSegment: DisplayRepresentation] = [
  Dynamic-Risk Checklist: none flagged
- caseDisplayRepresentations (var) — OffshoreWidgets/CategoryAvailabilityWidget.swift:105
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategoryAvailabilityWidget.swift:105
  Def: static var caseDisplayRepresentations: [CategoryAvailabilityWidgetSort: DisplayRepresentation] = [
  Dynamic-Risk Checklist: none flagged
- defaultQuery (var) — OffshoreWidgets/CategoryAvailabilityWidget.swift:118
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategoryAvailabilityWidget.swift:118
  Def: static var defaultQuery = CategoryAvailabilityWidgetCategoryQuery()
  Dynamic-Risk Checklist: none flagged
- displayRepresentation (var) — OffshoreWidgets/CategoryAvailabilityWidget.swift:120
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategoryAvailabilityWidget.swift:120
  Def: var displayRepresentation: DisplayRepresentation {
  Dynamic-Risk Checklist: none flagged
- CategoryAvailabilityWidgetCategoryQuery (struct) — OffshoreWidgets/CategoryAvailabilityWidget.swift:126
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategoryAvailabilityWidget.swift:126
  Def: struct CategoryAvailabilityWidgetCategoryQuery: EntityQuery {
  Dynamic-Risk Checklist: none flagged
- suggestedEntities (func) — OffshoreWidgets/CategoryAvailabilityWidget.swift:131
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategoryAvailabilityWidget.swift:131
  Def: func suggestedEntities() async throws -> [CategoryAvailabilityWidgetCategory] {
  Dynamic-Risk Checklist: none flagged
- CategoryAvailabilityWidgetIntentProvider (struct) — OffshoreWidgets/CategoryAvailabilityWidget.swift:146
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategoryAvailabilityWidget.swift:146
  Def: struct CategoryAvailabilityWidgetIntentProvider: AppIntentTimelineProvider {
  Dynamic-Risk Checklist: none flagged
- timeline (func) — OffshoreWidgets/CategoryAvailabilityWidget.swift:177
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategoryAvailabilityWidget.swift:177
  Def: func timeline(for configuration: CategoryAvailabilityWidgetConfigurationIntent, in context: Context) async -> Timeline<CategoryAvailabilityEntry> {
  Dynamic-Risk Checklist: none flagged
- CategoryAvailabilitySmallWidgetIntentProvider (struct) — OffshoreWidgets/CategoryAvailabilityWidget.swift:215
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategoryAvailabilityWidget.swift:215
  Def: struct CategoryAvailabilitySmallWidgetIntentProvider: AppIntentTimelineProvider {
  Dynamic-Risk Checklist: none flagged
- timeline (func) — OffshoreWidgets/CategoryAvailabilityWidget.swift:245
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategoryAvailabilityWidget.swift:245
  Def: func timeline(for configuration: CategoryAvailabilitySmallWidgetConfigurationIntent, in context: Context) async -> Timeline<CategoryAvailabilityEntry> {
  Dynamic-Risk Checklist: none flagged
- CategoryAvailabilityWidgetView (struct) — OffshoreWidgets/CategoryAvailabilityWidget.swift:286
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategoryAvailabilityWidget.swift:286
  Def: struct CategoryAvailabilityWidgetView: View {
  Dynamic-Risk Checklist: none flagged
- sortedItems (func) — OffshoreWidgets/CategoryAvailabilityWidget.swift:333
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategoryAvailabilityWidget.swift:333
  Def: private func sortedItems(_ items: [CategoryAvailabilityWidgetStore.Snapshot.Item], sort: CategoryAvailabilityWidgetSort) -> [CategoryAvailabilityWidgetStore.Snapshot.Item] {
  Dynamic-Risk Checklist: none flagged
- smallCategoryView (func) — OffshoreWidgets/CategoryAvailabilityWidget.swift:350
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategoryAvailabilityWidget.swift:350
  Def: private func smallCategoryView(items: [CategoryAvailabilityWidgetStore.Snapshot.Item], selected: String?) -> some View {
  Dynamic-Risk Checklist: none flagged
- mediumCategoryView (func) — OffshoreWidgets/CategoryAvailabilityWidget.swift:384
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategoryAvailabilityWidget.swift:384
  Def: private func mediumCategoryView(items: [CategoryAvailabilityWidgetStore.Snapshot.Item]) -> some View {
  Dynamic-Risk Checklist: none flagged
- largeCategoryView (func) — OffshoreWidgets/CategoryAvailabilityWidget.swift:411
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategoryAvailabilityWidget.swift:411
  Def: private func largeCategoryView(items: [CategoryAvailabilityWidgetStore.Snapshot.Item]) -> some View {
  Dynamic-Risk Checklist: none flagged
- limitedItems (func) — OffshoreWidgets/CategoryAvailabilityWidget.swift:422
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategoryAvailabilityWidget.swift:422
  Def: private func limitedItems(items: [CategoryAvailabilityWidgetStore.Snapshot.Item], maxItems: Int) -> [AvailabilityDisplayItem] {
  Dynamic-Risk Checklist: none flagged
- availabilityListItem (func) — OffshoreWidgets/CategoryAvailabilityWidget.swift:433
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategoryAvailabilityWidget.swift:433
  Def: private func availabilityListItem(_ item: AvailabilityDisplayItem, layout: AvailabilityLayout) -> some View {
  Dynamic-Risk Checklist: none flagged
- categoryRow (func) — OffshoreWidgets/CategoryAvailabilityWidget.swift:455
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategoryAvailabilityWidget.swift:455
  Def: private func categoryRow(item: CategoryAvailabilityWidgetStore.Snapshot.Item, compact: Bool) -> some View {
  Dynamic-Risk Checklist: none flagged
- mediumCategoryRow (func) — OffshoreWidgets/CategoryAvailabilityWidget.swift:494
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategoryAvailabilityWidget.swift:494
  Def: private func mediumCategoryRow(item: CategoryAvailabilityWidgetStore.Snapshot.Item) -> some View {
  Dynamic-Risk Checklist: none flagged
- AvailabilityLayout (enum) — OffshoreWidgets/CategoryAvailabilityWidget.swift:536
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategoryAvailabilityWidget.swift:536
  Def: private enum AvailabilityLayout {
  Dynamic-Risk Checklist: none flagged
- CategoryAvailabilityWidget (struct) — OffshoreWidgets/CategoryAvailabilityWidget.swift:547
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategoryAvailabilityWidget.swift:547
  Def: struct CategoryAvailabilityWidget: Widget {
  Dynamic-Risk Checklist: none flagged
- CategoryAvailabilitySmallWidget (struct) — OffshoreWidgets/CategoryAvailabilityWidget.swift:561
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategoryAvailabilityWidget.swift:561
  Def: struct CategoryAvailabilitySmallWidget: Widget {
  Dynamic-Risk Checklist: none flagged
- CategorySpotlightWidgetIntentProvider (struct) — OffshoreWidgets/CategorySpotlightWidget.swift:64
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategorySpotlightWidget.swift:64
  Def: struct CategorySpotlightWidgetIntentProvider: AppIntentTimelineProvider {
  Dynamic-Risk Checklist: none flagged
- timeline (func) — OffshoreWidgets/CategorySpotlightWidget.swift:78
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategorySpotlightWidget.swift:78
  Def: func timeline(for configuration: CategorySpotlightWidgetConfigurationIntent, in context: Context) async -> Timeline<CategorySpotlightEntry> {
  Dynamic-Risk Checklist: none flagged
- CategorySpotlightWidgetView (struct) — OffshoreWidgets/CategorySpotlightWidget.swift:101
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategorySpotlightWidget.swift:101
  Def: struct CategorySpotlightWidgetView: View {
  Dynamic-Risk Checklist: none flagged
- categoryList (func) — OffshoreWidgets/CategorySpotlightWidget.swift:192
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategorySpotlightWidget.swift:192
  Def: private func categoryList(
  Dynamic-Risk Checklist: none flagged
- CategorySpotlightWidget (struct) — OffshoreWidgets/CategorySpotlightWidget.swift:231
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategorySpotlightWidget.swift:231
  Def: struct CategorySpotlightWidget: Widget {
  Dynamic-Risk Checklist: none flagged
- DonutSegment (struct) — OffshoreWidgets/CategorySpotlightWidget.swift:250
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategorySpotlightWidget.swift:250
  Def: private struct DonutSegment: Identifiable {
  Dynamic-Risk Checklist: none flagged
- DonutChart (struct) — OffshoreWidgets/CategorySpotlightWidget.swift:257
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategorySpotlightWidget.swift:257
  Def: private struct DonutChart: View {
  Dynamic-Risk Checklist: none flagged
- showBackground (let) — OffshoreWidgets/CategorySpotlightWidget.swift:260
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategorySpotlightWidget.swift:260
  Def: let showBackground: Bool
  Dynamic-Risk Checklist: none flagged
- DayOfWeekSpendWidgetIntentProvider (struct) — OffshoreWidgets/DayOfWeekSpendWidget.swift:69
  Evidence: 0 refs (token-based); def at OffshoreWidgets/DayOfWeekSpendWidget.swift:69
  Def: struct DayOfWeekSpendWidgetIntentProvider: AppIntentTimelineProvider {
  Dynamic-Risk Checklist: none flagged
- timeline (func) — OffshoreWidgets/DayOfWeekSpendWidget.swift:83
  Evidence: 0 refs (token-based); def at OffshoreWidgets/DayOfWeekSpendWidget.swift:83
  Def: func timeline(for configuration: DayOfWeekSpendWidgetConfigurationIntent, in context: Context) async -> Timeline<DayOfWeekSpendEntry> {
  Dynamic-Risk Checklist: none flagged
- DayOfWeekSpendWidgetView (struct) — OffshoreWidgets/DayOfWeekSpendWidget.swift:106
  Evidence: 0 refs (token-based); def at OffshoreWidgets/DayOfWeekSpendWidget.swift:106
  Def: struct DayOfWeekSpendWidgetView: View {
  Dynamic-Risk Checklist: none flagged
- effectivePeriod (let) — OffshoreWidgets/DayOfWeekSpendWidget.swift:112
  Evidence: 0 refs (token-based); def at OffshoreWidgets/DayOfWeekSpendWidget.swift:112
  Def: let effectivePeriod = resolvePeriod(entry.period, family: family)
  Dynamic-Risk Checklist: none flagged
- barOrientation (func) — OffshoreWidgets/DayOfWeekSpendWidget.swift:159
  Evidence: 0 refs (token-based); def at OffshoreWidgets/DayOfWeekSpendWidget.swift:159
  Def: private func barOrientation(for period: WidgetPeriod, family: WidgetFamily, bucketCount: Int) -> BarOrientation {
  Dynamic-Risk Checklist: none flagged
- adjustedBuckets (func) — OffshoreWidgets/DayOfWeekSpendWidget.swift:181
  Evidence: 0 refs (token-based); def at OffshoreWidgets/DayOfWeekSpendWidget.swift:181
  Def: private func adjustedBuckets(_ buckets: [DayOfWeekSpendWidgetStore.DayOfWeekSnapshot.Bucket]) -> [DayOfWeekSpendWidgetStore.DayOfWeekSnapshot.Bucket] {
  Dynamic-Risk Checklist: none flagged
- resolvePeriod (func) — OffshoreWidgets/DayOfWeekSpendWidget.swift:196
  Evidence: 0 refs (token-based); def at OffshoreWidgets/DayOfWeekSpendWidget.swift:196
  Def: private func resolvePeriod(_ period: WidgetPeriod, family: WidgetFamily) -> WidgetPeriod {
  Dynamic-Risk Checklist: none flagged
- DayOfWeekSpendWidget (struct) — OffshoreWidgets/DayOfWeekSpendWidget.swift:205
  Evidence: 0 refs (token-based); def at OffshoreWidgets/DayOfWeekSpendWidget.swift:205
  Def: struct DayOfWeekSpendWidget: Widget {
  Dynamic-Risk Checklist: none flagged
- DayOfWeekBarChart (struct) — OffshoreWidgets/DayOfWeekSpendWidget.swift:218
  Evidence: 0 refs (token-based); def at OffshoreWidgets/DayOfWeekSpendWidget.swift:218
  Def: private struct DayOfWeekBarChart: View {
  Dynamic-Risk Checklist: none flagged
- barMaxWidth (let) — OffshoreWidgets/DayOfWeekSpendWidget.swift:236
  Evidence: 0 refs (token-based); def at OffshoreWidgets/DayOfWeekSpendWidget.swift:236
  Def: let barMaxWidth = max(geo.size.width - labelWidth - 6, 20)
  Dynamic-Risk Checklist: none flagged
- showLabel (let) — OffshoreWidgets/DayOfWeekSpendWidget.swift:246
  Evidence: 0 refs (token-based); def at OffshoreWidgets/DayOfWeekSpendWidget.swift:246
  Def: let showLabel = shouldShowLabel(index: index, count: count)
  Dynamic-Risk Checklist: none flagged
- minBarWidth (let) — OffshoreWidgets/DayOfWeekSpendWidget.swift:269
  Evidence: 0 refs (token-based); def at OffshoreWidgets/DayOfWeekSpendWidget.swift:269
  Def: let minBarWidth: CGFloat = family == .systemSmall ? 8 : (family == .systemLarge ? 14 : 10)
  Dynamic-Risk Checklist: none flagged
- barWidth (let) — OffshoreWidgets/DayOfWeekSpendWidget.swift:270
  Evidence: 0 refs (token-based); def at OffshoreWidgets/DayOfWeekSpendWidget.swift:270
  Def: let barWidth = max((geo.size.width - spacing * CGFloat(count - 1)) / CGFloat(count), minBarWidth)
  Dynamic-Risk Checklist: none flagged
- barAreaHeight (let) — OffshoreWidgets/DayOfWeekSpendWidget.swift:272
  Evidence: 0 refs (token-based); def at OffshoreWidgets/DayOfWeekSpendWidget.swift:272
  Def: let barAreaHeight = max(40, geo.size.height - labelHeight)
  Dynamic-Risk Checklist: none flagged
- showLabel (let) — OffshoreWidgets/DayOfWeekSpendWidget.swift:283
  Evidence: 0 refs (token-based); def at OffshoreWidgets/DayOfWeekSpendWidget.swift:283
  Def: let showLabel = shouldShowLabel(index: index, count: count)
  Dynamic-Risk Checklist: none flagged
- shouldShowLabel (func) — OffshoreWidgets/DayOfWeekSpendWidget.swift:330
  Evidence: 0 refs (token-based); def at OffshoreWidgets/DayOfWeekSpendWidget.swift:330
  Def: private func shouldShowLabel(index: Int, count: Int) -> Bool {
  Dynamic-Risk Checklist: none flagged
- uniqueHexes (func) — OffshoreWidgets/DayOfWeekSpendWidget.swift:344
  Evidence: 0 refs (token-based); def at OffshoreWidgets/DayOfWeekSpendWidget.swift:344
  Def: private func uniqueHexes(from hexes: [String], maxCount: Int) -> [String] {
  Dynamic-Risk Checklist: none flagged
- blendTail (func) — OffshoreWidgets/DayOfWeekSpendWidget.swift:356
  Evidence: 0 refs (token-based); def at OffshoreWidgets/DayOfWeekSpendWidget.swift:356
  Def: private func blendTail(colors: [Color], totalCount: Int, maxCount: Int) -> [Color] {
  Dynamic-Risk Checklist: none flagged
- labelText (func) — OffshoreWidgets/DayOfWeekSpendWidget.swift:367
  Evidence: 0 refs (token-based); def at OffshoreWidgets/DayOfWeekSpendWidget.swift:367
  Def: private func labelText(for raw: String) -> String {
  Dynamic-Risk Checklist: none flagged
- labelWidthForHorizontal (func) — OffshoreWidgets/DayOfWeekSpendWidget.swift:385
  Evidence: 0 refs (token-based); def at OffshoreWidgets/DayOfWeekSpendWidget.swift:385
  Def: private func labelWidthForHorizontal() -> CGFloat {
  Dynamic-Risk Checklist: none flagged
- yearlyContent (func) — OffshoreWidgets/DayOfWeekSpendWidget.swift:406
  Evidence: 0 refs (token-based); def at OffshoreWidgets/DayOfWeekSpendWidget.swift:406
  Def: private func yearlyContent(geo: GeometryProxy, spacing: CGFloat, count: Int) -> some View {
  Dynamic-Risk Checklist: none flagged
- YearlyLabelMode (enum) — OffshoreWidgets/DayOfWeekSpendWidget.swift:420
  Evidence: 0 refs (token-based); def at OffshoreWidgets/DayOfWeekSpendWidget.swift:420
  Def: private enum YearlyLabelMode {
  Dynamic-Risk Checklist: none flagged
- yearlyVerticalBars (func) — OffshoreWidgets/DayOfWeekSpendWidget.swift:426
  Evidence: 0 refs (token-based); def at OffshoreWidgets/DayOfWeekSpendWidget.swift:426
  Def: private func yearlyVerticalBars(geo: GeometryProxy, spacing: CGFloat, buckets: [DayOfWeekSpendWidgetStore.DayOfWeekSnapshot.Bucket], showLabels: Bool, labelMode: YearlyLabelMode) -> some View {
  Dynamic-Risk Checklist: none flagged
- yearlyMediumGrid (func) — OffshoreWidgets/DayOfWeekSpendWidget.swift:461
  Evidence: 0 refs (token-based); def at OffshoreWidgets/DayOfWeekSpendWidget.swift:461
  Def: private func yearlyMediumGrid(geo: GeometryProxy, spacing: CGFloat, buckets: [DayOfWeekSpendWidgetStore.DayOfWeekSnapshot.Bucket]) -> some View {
  Dynamic-Risk Checklist: none flagged
- yearlyMediumColumn (func) — OffshoreWidgets/DayOfWeekSpendWidget.swift:477
  Evidence: 0 refs (token-based); def at OffshoreWidgets/DayOfWeekSpendWidget.swift:477
  Def: private func yearlyMediumColumn(buckets: [DayOfWeekSpendWidgetStore.DayOfWeekSnapshot.Bucket], columnWidth: CGFloat, rowHeight: CGFloat, rowSpacing: CGFloat) -> some View {
  Dynamic-Risk Checklist: none flagged
- yearlyLabel (func) — OffshoreWidgets/DayOfWeekSpendWidget.swift:507
  Evidence: 0 refs (token-based); def at OffshoreWidgets/DayOfWeekSpendWidget.swift:507
  Def: private func yearlyLabel(for index: Int, mode: YearlyLabelMode) -> String {
  Dynamic-Risk Checklist: none flagged
- yearlyBuckets (func) — OffshoreWidgets/DayOfWeekSpendWidget.swift:518
  Evidence: 0 refs (token-based); def at OffshoreWidgets/DayOfWeekSpendWidget.swift:518
  Def: private func yearlyBuckets() -> [DayOfWeekSpendWidgetStore.DayOfWeekSnapshot.Bucket] {
  Dynamic-Risk Checklist: none flagged
- BarOrientation (enum) — OffshoreWidgets/DayOfWeekSpendWidget.swift:536
  Evidence: 0 refs (token-based); def at OffshoreWidgets/DayOfWeekSpendWidget.swift:536
  Def: private enum BarOrientation {
  Dynamic-Risk Checklist: none flagged
- blend (func) — OffshoreWidgets/DayOfWeekSpendWidget.swift:542
  Evidence: 0 refs (token-based); def at OffshoreWidgets/DayOfWeekSpendWidget.swift:542
  Def: func blend(with other: Color, fraction: Double) -> Color {
  Dynamic-Risk Checklist: none flagged
- ExpenseToIncomeWidgetIntentProvider (struct) — OffshoreWidgets/ExpenseToIncomeWidget.swift:51
  Evidence: 0 refs (token-based); def at OffshoreWidgets/ExpenseToIncomeWidget.swift:51
  Def: struct ExpenseToIncomeWidgetIntentProvider: AppIntentTimelineProvider {
  Dynamic-Risk Checklist: none flagged
- timeline (func) — OffshoreWidgets/ExpenseToIncomeWidget.swift:65
  Evidence: 0 refs (token-based); def at OffshoreWidgets/ExpenseToIncomeWidget.swift:65
  Def: func timeline(for configuration: ExpenseToIncomeWidgetConfigurationIntent, in context: Context) async -> Timeline<ExpenseToIncomeWidgetEntry> {
  Dynamic-Risk Checklist: none flagged
- ExpenseToIncomeWidgetView (struct) — OffshoreWidgets/ExpenseToIncomeWidget.swift:88
  Evidence: 0 refs (token-based); def at OffshoreWidgets/ExpenseToIncomeWidget.swift:88
  Def: struct ExpenseToIncomeWidgetView: View {
  Dynamic-Risk Checklist: none flagged
- gaugeValue (let) — OffshoreWidgets/ExpenseToIncomeWidget.swift:101
  Evidence: 0 refs (token-based); def at OffshoreWidgets/ExpenseToIncomeWidget.swift:101
  Def: let gaugeValue = hasReceived ? min(max((receivedPercent ?? 0) / 100, 0), 1) : (expenses > 0 ? 1 : 0)
  Dynamic-Risk Checklist: none flagged
- ExpenseToIncomeWidget (struct) — OffshoreWidgets/ExpenseToIncomeWidget.swift:170
  Evidence: 0 refs (token-based); def at OffshoreWidgets/ExpenseToIncomeWidget.swift:170
  Def: struct ExpenseToIncomeWidget: Widget {
  Dynamic-Risk Checklist: none flagged
- IncomeWidgetIntentProvider (struct) — OffshoreWidgets/IncomeWidget.swift:59
  Evidence: 0 refs (token-based); def at OffshoreWidgets/IncomeWidget.swift:59
  Def: struct IncomeWidgetIntentProvider: AppIntentTimelineProvider {
  Dynamic-Risk Checklist: none flagged
- timeline (func) — OffshoreWidgets/IncomeWidget.swift:73
  Evidence: 0 refs (token-based); def at OffshoreWidgets/IncomeWidget.swift:73
  Def: func timeline(for configuration: IncomeWidgetConfigurationIntent, in context: Context) async -> Timeline<IncomeWidgetEntry> {
  Dynamic-Risk Checklist: none flagged
- IncomeWidgetView (struct) — OffshoreWidgets/IncomeWidget.swift:96
  Evidence: 0 refs (token-based); def at OffshoreWidgets/IncomeWidget.swift:96
  Def: struct IncomeWidgetView: View {
  Dynamic-Risk Checklist: none flagged
- IncomeWidget (struct) — OffshoreWidgets/IncomeWidget.swift:171
  Evidence: 0 refs (token-based); def at OffshoreWidgets/IncomeWidget.swift:171
  Def: struct IncomeWidget: Widget {
  Dynamic-Risk Checklist: none flagged
- NextPlannedExpenseProvider (struct) — OffshoreWidgets/NextPlannedExpenseWidget.swift:52
  Evidence: 0 refs (token-based); def at OffshoreWidgets/NextPlannedExpenseWidget.swift:52
  Def: struct NextPlannedExpenseProvider: TimelineProvider {
  Dynamic-Risk Checklist: none flagged
- getSnapshot (func) — OffshoreWidgets/NextPlannedExpenseWidget.swift:57
  Evidence: 0 refs (token-based); def at OffshoreWidgets/NextPlannedExpenseWidget.swift:57
  Def: func getSnapshot(in context: Context, completion: @escaping (NextPlannedExpenseEntry) -> Void) {
  Dynamic-Risk Checklist: none flagged
- getTimeline (func) — OffshoreWidgets/NextPlannedExpenseWidget.swift:62
  Evidence: 0 refs (token-based); def at OffshoreWidgets/NextPlannedExpenseWidget.swift:62
  Def: func getTimeline(in context: Context, completion: @escaping (Timeline<NextPlannedExpenseEntry>) -> Void) {
  Dynamic-Risk Checklist: none flagged
- NextPlannedExpenseWidgetView (struct) — OffshoreWidgets/NextPlannedExpenseWidget.swift:68
  Evidence: 0 refs (token-based); def at OffshoreWidgets/NextPlannedExpenseWidget.swift:68
  Def: struct NextPlannedExpenseWidgetView: View {
  Dynamic-Risk Checklist: none flagged
- NextPlannedExpenseWidget (struct) — OffshoreWidgets/NextPlannedExpenseWidget.swift:146
  Evidence: 0 refs (token-based); def at OffshoreWidgets/NextPlannedExpenseWidget.swift:146
  Def: struct NextPlannedExpenseWidget: Widget {
  Dynamic-Risk Checklist: none flagged
- OffshoreWidgetsBundle (struct) — OffshoreWidgets/OffshoreWidgetsBundle.swift:13
  Evidence: 0 refs (token-based); def at OffshoreWidgets/OffshoreWidgetsBundle.swift:13
  Def: struct OffshoreWidgetsBundle: WidgetBundle {
  Dynamic-Risk Checklist: none flagged
- SavingsOutlookWidgetIntentProvider (struct) — OffshoreWidgets/SavingsOutlookWidget.swift:51
  Evidence: 0 refs (token-based); def at OffshoreWidgets/SavingsOutlookWidget.swift:51
  Def: struct SavingsOutlookWidgetIntentProvider: AppIntentTimelineProvider {
  Dynamic-Risk Checklist: none flagged
- timeline (func) — OffshoreWidgets/SavingsOutlookWidget.swift:65
  Evidence: 0 refs (token-based); def at OffshoreWidgets/SavingsOutlookWidget.swift:65
  Def: func timeline(for configuration: SavingsOutlookWidgetConfigurationIntent, in context: Context) async -> Timeline<SavingsOutlookWidgetEntry> {
  Dynamic-Risk Checklist: none flagged
- SavingsOutlookWidgetView (struct) — OffshoreWidgets/SavingsOutlookWidget.swift:88
  Evidence: 0 refs (token-based); def at OffshoreWidgets/SavingsOutlookWidget.swift:88
  Def: struct SavingsOutlookWidgetView: View {
  Dynamic-Risk Checklist: none flagged
- percentOfProjected (let) — OffshoreWidgets/SavingsOutlookWidget.swift:100
  Evidence: 0 refs (token-based); def at OffshoreWidgets/SavingsOutlookWidget.swift:100
  Def: let percentOfProjected = projectedPositive ? (actual / projected) * 100 : nil
  Dynamic-Risk Checklist: none flagged
- SavingsOutlookWidget (struct) — OffshoreWidgets/SavingsOutlookWidget.swift:178
  Evidence: 0 refs (token-based); def at OffshoreWidgets/SavingsOutlookWidget.swift:178
  Def: struct SavingsOutlookWidget: Widget {
  Dynamic-Risk Checklist: none flagged
- caseDisplayRepresentations (var) — OffshoreWidgets/WidgetPeriod.swift:16
  Evidence: 0 refs (token-based); def at OffshoreWidgets/WidgetPeriod.swift:16
  Def: static var caseDisplayRepresentations: [WidgetPeriod: DisplayRepresentation] = [
  Dynamic-Risk Checklist: none flagged

DYNAMIC-RISK
- startObservingDataChanges (func) — OffshoreBudgeting/OffshoreBudgetingApp.swift:220
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/OffshoreBudgetingApp.swift:220
  Def: private func startObservingDataChanges() {
  Dynamic-Risk Checklist: NotificationCenter
- startObservingHomeReadiness (func) — OffshoreBudgeting/OffshoreBudgetingApp.swift:234
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/OffshoreBudgetingApp.swift:234
  Def: private func startObservingHomeReadiness() {
  Dynamic-Risk Checklist: NotificationCenter
- objectsDidChangePublisher (let) — OffshoreBudgeting/Resources/CoreDataEntityChangeMonitor.swift:55
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/CoreDataEntityChangeMonitor.swift:55
  Def: let objectsDidChangePublisher = NotificationCenter.default
  Dynamic-Risk Checklist: NotificationCenter
- didSavePublisher (let) — OffshoreBudgeting/Resources/CoreDataEntityChangeMonitor.swift:77
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/CoreDataEntityChangeMonitor.swift:77
  Def: let didSavePublisher = NotificationCenter.default
  Dynamic-Risk Checklist: NotificationCenter
- didMergeObjectIDsPublisher (let) — OffshoreBudgeting/Resources/CoreDataEntityChangeMonitor.swift:99
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/CoreDataEntityChangeMonitor.swift:99
  Def: let didMergeObjectIDsPublisher = NotificationCenter.default
  Dynamic-Risk Checklist: NotificationCenter
- objectIdentifier (let) — OffshoreBudgeting/Resources/CoreDataEntityChangeMonitor.swift:147
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/CoreDataEntityChangeMonitor.swift:147
  Def: let objectIdentifier: ObjectIdentifier?
  Dynamic-Risk Checklist: NotificationCenter
- payloadDigest (let) — OffshoreBudgeting/Resources/CoreDataEntityChangeMonitor.swift:148
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/CoreDataEntityChangeMonitor.swift:148
  Def: let payloadDigest: NotificationPayloadDigest
  Dynamic-Risk Checklist: NotificationCenter
- homeViewInitialDataLoaded (let) — OffshoreBudgeting/Resources/NotificationName+Extensions.swift:23
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/NotificationName+Extensions.swift:23
  Def: static let homeViewInitialDataLoaded = Notification.Name("homeViewInitialDataLoaded")
  Dynamic-Risk Checklist: NotificationCenter
- workspaceDidChange (let) — OffshoreBudgeting/Resources/NotificationName+Extensions.swift:24
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Resources/NotificationName+Extensions.swift:24
  Def: static let workspaceDidChange = Notification.Name("workspaceDidChange")
  Dynamic-Risk Checklist: NotificationCenter
- presetExpenseLookaheadDays (let) — OffshoreBudgeting/Services/LocalNotificationScheduler.swift:21
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Services/LocalNotificationScheduler.swift:21
  Def: private let presetExpenseLookaheadDays = 45
  Dynamic-Risk Checklist: NotificationCenter
- NotificationCenterAdapter (class) — OffshoreBudgeting/Systems/AppTheme.swift:35
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:35
  Def: final class NotificationCenterAdapter: NotificationCentering {
  Dynamic-Risk Checklist: NotificationCenter
- pendingInjectedCloudStatusProvider (var) — OffshoreBudgeting/Systems/AppTheme.swift:800
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:800
  Def: private var pendingInjectedCloudStatusProvider: CloudAvailabilityProviding?
  Dynamic-Risk Checklist: NotificationCenter
- availabilityCancellable (var) — OffshoreBudgeting/Systems/AppTheme.swift:803
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:803
  Def: private var availabilityCancellable: AnyCancellable?
  Dynamic-Risk Checklist: NotificationCenter
- hasRequestedCloudAvailabilityCheck (var) — OffshoreBudgeting/Systems/AppTheme.swift:804
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/AppTheme.swift:804
  Def: private var hasRequestedCloudAvailabilityCheck = false
  Dynamic-Risk Checklist: NotificationCenter
- observeWorkspaceChanges (func) — OffshoreBudgeting/Systems/CardPickerStore.swift:85
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/CardPickerStore.swift:85
  Def: private func observeWorkspaceChanges() {
  Dynamic-Risk Checklist: NotificationCenter
- didMoveToSuperview (func) — OffshoreBudgeting/Systems/Compatibility.swift:187
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:187
  Def: override func didMoveToSuperview() {
  Dynamic-Risk Checklist: override
- layoutSubviews (func) — OffshoreBudgeting/Systems/Compatibility.swift:192
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/Compatibility.swift:192
  Def: override func layoutSubviews() {
  Dynamic-Risk Checklist: override
- setupLifecycleObservers (func) — OffshoreBudgeting/Systems/MotionSupport.swift:125
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/MotionSupport.swift:125
  Def: func setupLifecycleObservers() {
  Dynamic-Risk Checklist: NotificationCenter
- removeLifecycleObservers (func) — OffshoreBudgeting/Systems/MotionSupport.swift:139
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/MotionSupport.swift:139
  Def: func removeLifecycleObservers() {
  Dynamic-Risk Checklist: NotificationCenter
- UBSafeAreaInsetsPreferenceKey (struct) — OffshoreBudgeting/Systems/SafeAreaInsetsCompatibility.swift:32
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/SafeAreaInsetsCompatibility.swift:32
  Def: private struct UBSafeAreaInsetsPreferenceKey: PreferenceKey {
  Dynamic-Risk Checklist: SwiftUI indirect key
- cardWidgetKind (let) — OffshoreBudgeting/Systems/WidgetSharedStore.swift:33
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Systems/WidgetSharedStore.swift:33
  Def: static let cardWidgetKind = "com.mb.offshore.card.widget"
  Dynamic-Risk Checklist: Codable
- observeLifecycle (func) — OffshoreBudgeting/View Models/AppLockViewModel.swift:134
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AppLockViewModel.swift:134
  Def: private func observeLifecycle() {
  Dynamic-Risk Checklist: NotificationCenter
- appDidResignActive (func) — OffshoreBudgeting/View Models/AppLockViewModel.swift:174
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/AppLockViewModel.swift:174
  Def: @objc private func appDidResignActive() {
  Dynamic-Risk Checklist: @objc
- allCats (let) — OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:123
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift:123
  Def: let allCats = (try? context.fetch(req)) ?? []
  Dynamic-Risk Checklist: #selector
- startObservingUbiquitousChangesIfNeeded (func) — OffshoreBudgeting/Views/BudgetsView.swift:479
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:479
  Def: private func startObservingUbiquitousChangesIfNeeded() {
  Dynamic-Risk Checklist: NotificationCenter
- stopObservingUbiquitousChanges (func) — OffshoreBudgeting/Views/BudgetsView.swift:490
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/BudgetsView.swift:490
  Def: private func stopObservingUbiquitousChanges() {
  Dynamic-Risk Checklist: NotificationCenter
- overridesLabelForeground (var) — OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:22
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:22
  Def: var overridesLabelForeground: Bool = true
  Dynamic-Risk Checklist: override
- startObservingWidgetSyncIfNeeded (func) — OffshoreBudgeting/Views/HomeView.swift:1472
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1472
  Def: private func startObservingWidgetSyncIfNeeded() {
  Dynamic-Risk Checklist: NotificationCenter
- stopObservingWidgetSync (func) — OffshoreBudgeting/Views/HomeView.swift:1484
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:1484
  Def: private func stopObservingWidgetSync() {
  Dynamic-Risk Checklist: NotificationCenter
- ScenarioPlannerWidthPreferenceKey (struct) — OffshoreBudgeting/Views/HomeView.swift:3365
  Evidence: 0 refs (token-based); def at OffshoreBudgeting/Views/HomeView.swift:3365
  Def: private struct ScenarioPlannerWidthPreferenceKey: PreferenceKey {
  Dynamic-Risk Checklist: SwiftUI indirect key
- setUp (func) — OffshoreBudgetingTests/HomeViewSummaryTests.swift:14
  Evidence: 0 refs (token-based); def at OffshoreBudgetingTests/HomeViewSummaryTests.swift:14
  Def: override func setUp() {
  Dynamic-Risk Checklist: override
- tearDown (func) — OffshoreBudgetingTests/HomeViewSummaryTests.swift:20
  Evidence: 0 refs (token-based); def at OffshoreBudgetingTests/HomeViewSummaryTests.swift:20
  Def: override func tearDown() {
  Dynamic-Risk Checklist: override
- cardsKey (let) — OffshoreWidgets/CardWidget.swift:9
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CardWidget.swift:9
  Def: static let cardsKey = "widget.card.cards"
  Dynamic-Risk Checklist: Codable
- CardEntry (struct) — OffshoreWidgets/CardWidget.swift:32
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CardWidget.swift:32
  Def: struct CardEntry: Codable, Hashable {
  Dynamic-Risk Checklist: Codable
- categoriesKey (let) — OffshoreWidgets/CategoryAvailabilityWidget.swift:11
  Evidence: 0 refs (token-based); def at OffshoreWidgets/CategoryAvailabilityWidget.swift:11
  Def: private static let categoriesKey = "widget.categoryAvailability.categories"
  Dynamic-Risk Checklist: Codable
- snapshotKey (let) — OffshoreWidgets/NextPlannedExpenseWidget.swift:6
  Evidence: 0 refs (token-based); def at OffshoreWidgets/NextPlannedExpenseWidget.swift:6
  Def: static let snapshotKey = "widget.nextPlannedExpense.snapshot"
  Dynamic-Risk Checklist: Codable