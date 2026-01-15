# ub_dismissKeyboard receipts (read-only)

## 1) Callsites
Command: `rg -n "\bub_dismissKeyboard\b" OffshoreBudgeting -g"*.swift"`
```
OffshoreBudgeting/Views/AddIncomeFormView.swift:240:            ub_dismissKeyboard()
OffshoreBudgeting/Core/UIFoundation/Compatibility.swift:490:func ub_dismissKeyboard() {
OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:297:            ub_dismissKeyboard()
OffshoreBudgeting/Views/AddBudgetView.swift:278:            ub_dismissKeyboard()
OffshoreBudgeting/Views/AddPlannedExpenseView.swift:438:            ub_dismissKeyboard()
```

## 2) Selector / notification / string usage scan
Command: `rg -n "dismissKeyboard|resignFirstResponder|sendAction" OffshoreBudgeting -g"*.swift"`
```
OffshoreBudgeting/Views/AddIncomeFormView.swift:240:            ub_dismissKeyboard()
OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:297:            ub_dismissKeyboard()
OffshoreBudgeting/Views/AddCardFormView.swift:227:        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
OffshoreBudgeting/Core/UIFoundation/Compatibility.swift:490:func ub_dismissKeyboard() {
OffshoreBudgeting/Core/UIFoundation/Compatibility.swift:491:    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
OffshoreBudgeting/Views/AddBudgetView.swift:278:            ub_dismissKeyboard()
OffshoreBudgeting/Views/AddPlannedExpenseView.swift:438:            ub_dismissKeyboard()
```

## Conclusion
- Keep; update classification to KEEP or LEGACY.
- Reason: `ub_dismissKeyboard` has non-defining-file callsites in `AddIncomeFormView`, `AddUnplannedExpenseView`, `AddBudgetView`, and `AddPlannedExpenseView`.
