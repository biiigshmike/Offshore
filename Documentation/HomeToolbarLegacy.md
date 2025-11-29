# Legacy Home toolbar controls (saved from HomeView)

These were removed from `HomeView` during the widget-feed redesign but kept here so they can be dropped into `BudgetDetailView` (or elsewhere) later.

```swift
@Namespace private var homeToolbarGlassNamespace

@ToolbarContentBuilder
private var toolbarContent: some ToolbarContent {
    if #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
        ToolbarItem(placement: .navigationBarTrailing) {
            GlassEffectContainer(spacing: 16) {
                HStack(spacing: 16) {
                    calendarMenu
                    if isAddMenuVisible {
                        addExpenseMenu
                            .transition(.opacity.combined(with: .scale))
                    }
                    ellipsisMenu
                }
            }
        }
    } else {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 16) {
                calendarMenu
                if isAddMenuVisible {
                    addExpenseMenu
                        .transition(.opacity.combined(with: .scale))
                }
                ellipsisMenu
            }
        }
    }
}

private var calendarMenu: some View {
    Menu {
        ForEach(BudgetPeriod.selectableCases) { p in
            Button(p.displayName) {
                updateBudgetPeriod(to: p)
            }
        }
    } label: {
        glassToolbarLabel("calendar")
    }
}

private var addExpenseMenu: some View {
    Menu {
        Button("Add Planned Expense") { isPresentingAddPlanned = true }
        Button("Add Variable Expense") { isPresentingAddVariable = true }
    } label: {
        glassToolbarLabel("plus")
    }
}

private var ellipsisMenu: some View {
    Menu {
        if let summary = summary {
            Button("Manage Cards") { isPresentingManageCards = true }
            Button("Manage Presets") { isPresentingManagePresets = true }
            Button("Edit Budget") { editingBudget = summary }
            Button(role: .destructive) { vm.requestDelete(budgetID: summary.id) } label: { Text("Delete Budget") }
        } else {
            Button("Create Budget") { isPresentingAddBudget = true }
        }
    } label: {
        glassToolbarLabel("ellipsis")
    }
}

@ViewBuilder
private func glassToolbarLabel(_ symbol: String) -> some View {
    if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
        let base = Image(systemName: symbol)
            .foregroundStyle(.primary)
            .font(.system(size: 16, weight: .semibold))
            .frame(width: 44, height: 44)
            .glassEffectUnion(id: "home-toolbar", namespace: homeToolbarGlassNamespace)
            .glassEffectID(symbol, in: homeToolbarGlassNamespace)
        if symbol != "plus" {
            base.glassEffectTransition(.matchedGeometry)
        } else {
            base
        }
    } else {
        Image(systemName: symbol)
            .font(.system(size: 16, weight: .semibold))
            .frame(width: 44, height: 44)
    }
}
```
