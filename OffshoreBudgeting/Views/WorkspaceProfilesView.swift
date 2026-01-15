import SwiftUI
import CoreData

// MARK: - WorkspaceMenuButton
/// Toolbar menu for selecting and managing profiles/workspaces.
struct WorkspaceMenuButton: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var settings: AppSettingsState
    @FetchRequest(
        entity: Workspace.entity(),
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
    ) private var workspaces: FetchedResults<Workspace>
    
    @State private var showAdd = false
    @State private var showManage = false
    @ScaledMetric(relativeTo: .body) private var menuButtonSize: CGFloat = 33
    @ScaledMetric(relativeTo: .body) private var menuButtonPadding: CGFloat = 6
    @ScaledMetric(relativeTo: .body) private var menuDotSize: CGFloat = 14
    
    var body: some View {
        DesignSystemV2.Buttons.GlassProminentIconMenu(
            systemImage: "person.3.fill",
            accessibilityLabel: "Profile Menu",
            accessibilityHint: "Switch or manage profiles.",
            tint: activeWorkspaceColor,
            iconSize: menuButtonSize,
            legacyTint: activeWorkspaceColor,
            legacyPadding: menuButtonPadding
        ) {
            workspaceListSection
            Divider()
            Button("Add New Profile") { showAdd = true }
            Button("Manage Profiles") { showManage = true }
        }
        .task { _ = WorkspaceService.shared.ensureActiveWorkspaceID() }
        .sheet(isPresented: $showAdd) {
            WorkspaceEditorView(mode: .add)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showManage) {
            WorkspaceManagerView()
                .environment(\.managedObjectContext, viewContext)
        }
    }

    @ViewBuilder
    private var workspaceListSection: some View {
        let activeID = UUID(uuidString: settings.activeWorkspaceID)
        ForEach(workspaces) { workspace in
            let colorHex = WorkspaceService.shared.colorHex(for: workspace)
            let rowTint = UBColorFromHex(colorHex) ?? .accentColor
            Button {
                guard let id = workspace.id else { return }
                WorkspaceService.shared.setActiveWorkspaceID(id)
                settings.activeWorkspaceID = id.uuidString
            } label: {
                HStack(spacing: Spacing.sPlus) {
                    if activeID == workspace.id {
                        Image(systemName: Icons.sfCheckmark)
                            .foregroundStyle(rowTint)
                    }
                    WorkspaceColorDot(hex: colorHex, size: menuDotSize)
                    Text(workspace.name ?? "Untitled")
                }
            }
        }
    }
    

    private var activeWorkspaceColor: Color {
        UBColorFromHex(activeWorkspaceColorHex) ?? .accentColor
    }

    private var activeWorkspaceColorHex: String {
        let activeID = UUID(uuidString: settings.activeWorkspaceID)
        if let activeID, let workspace = workspaces.first(where: { $0.id == activeID }) {
            return WorkspaceService.shared.colorHex(for: workspace)
        }
        return WorkspaceService.defaultNewWorkspaceColorHex
    }
}

// MARK: - WorkspaceColorDot
struct WorkspaceColorDot: View {
    let hex: String
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(UBColorFromHex(hex) ?? .gray.opacity(0.4))
            .frame(width: size, height: size)
            .overlay(
                Circle().strokeBorder(Color.primary.opacity(0.1))
            )
            .accessibilityHidden(true)
    }
}

// MARK: - WorkspaceManagerView
/// Sheet that lists all profiles and allows renaming or deletion.
struct WorkspaceManagerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettingsState
    @FetchRequest(
        entity: Workspace.entity(),
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
    ) private var workspaces: FetchedResults<Workspace>
    
    @State private var editingWorkspace: Workspace?
    @State private var workspaceToDelete: Workspace?
    @State private var showAddSheet = false
    @ScaledMetric(relativeTo: .body) private var rowDotSize: CGFloat = 18
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(workspaces) { workspace in
                        workspaceRow(for: workspace)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profiles")
            .ub_windowTitle("Profiles")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add") { showAddSheet = true }
                }
            }
            .sheet(item: $editingWorkspace) { workspace in
                WorkspaceEditorView(mode: .edit(workspace))
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showAddSheet) {
                WorkspaceEditorView(mode: .add)
                    .environment(\.managedObjectContext, viewContext)
            }
            .alert("Delete Profile?", isPresented: Binding(get: {
                workspaceToDelete != nil
            }, set: { newValue in
                if !newValue { workspaceToDelete = nil }
            })) {
                Button("Delete", role: .destructive) { confirmDelete() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Deleting this profile will remove all of its budgets, cards, and expenses.")
            }
        }
        .task {
            let id = WorkspaceService.shared.ensureActiveWorkspaceID()
            settings.activeWorkspaceID = id.uuidString
        }
    }
    
    private func workspaceRow(for workspace: Workspace) -> some View {
        let isActive = UUID(uuidString: settings.activeWorkspaceID) == workspace.id
        let isPersonal = WorkspaceService.shared.isPersonalWorkspace(workspace)
        let colorHex = WorkspaceService.shared.colorHex(for: workspace)
        let config = UnifiedSwipeConfig(
            showsDeleteAction: !isPersonal,
            allowsFullSwipeToDelete: !isPersonal
        )
        return HStack {
            WorkspaceColorDot(hex: colorHex, size: rowDotSize)
            VStack(alignment: .leading, spacing: 2) {
                Text(workspace.name ?? "Untitled")
                if isActive {
                    Text("Current Profile")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .unifiedSwipeActions(
            config,
            onEdit: { editingWorkspace = workspace },
            onDelete: { workspaceToDelete = workspace }
        )
    }
    
    private func confirmDelete() {
        guard let workspace = workspaceToDelete else { return }
        _ = WorkspaceService.shared.deleteWorkspace(workspace, in: viewContext)
        workspaceToDelete = nil
    }
}

// MARK: - WorkspaceEditorView
/// Add/Edit sheet for a single profile.
struct WorkspaceEditorView: View {
    enum Mode {
        case add
        case edit(Workspace)
        
        var title: String {
            switch self {
            case .add: return "New Profile"
            case .edit: return "Edit Profile"
            }
        }
        
        var actionTitle: String {
            switch self {
            case .add: return "Create"
            case .edit: return "Save"
            }
        }
    }
    
    let mode: Mode
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var color: Color = UBColorFromHex(WorkspaceService.defaultNewWorkspaceColorHex) ?? .blue
    
    var body: some View {
        NavigationStack {
            List {
                Section("Profile Name") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                }
                Section("Color") {
                    ColorPicker("", selection: $color, supportsOpacity: false)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("Color")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(mode.title)
            .ub_windowTitle(mode.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear { loadInitialName() }
        }
    }
    
    private var canSave: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return false }
        switch mode {
        case .add:
            return WorkspaceService.shared.isWorkspaceNameAvailable(trimmed, excluding: nil, in: viewContext)
        case .edit(let workspace):
            if trimmed == (workspace.name ?? "") { return true }
            return WorkspaceService.shared.isWorkspaceNameAvailable(trimmed, excluding: workspace, in: viewContext)
        }
    }
    
    private func loadInitialName() {
        switch mode {
        case .add:
            name = ""
            color = UBColorFromHex(WorkspaceService.defaultNewWorkspaceColorHex) ?? .blue
        case .edit(let workspace):
            name = workspace.name ?? ""
            let hex = WorkspaceService.shared.colorHex(for: workspace)
            color = UBColorFromHex(hex) ?? .blue
        }
    }
    
    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let hex = colorToHex(color) else { return }
        switch mode {
        case .add:
            if let workspace = WorkspaceService.shared.createWorkspace(named: trimmed, in: viewContext),
               let id = workspace.id {
                if workspace.entity.attributesByName.keys.contains("color") {
                    workspace.setValue(hex, forKey: "color")
                }
                try? viewContext.save()
                WorkspaceService.shared.setActiveWorkspaceID(id)
            }
        case .edit(let workspace):
            if workspace.entity.attributesByName.keys.contains("color") {
                workspace.setValue(hex, forKey: "color")
            }
            _ = WorkspaceService.shared.renameWorkspace(workspace, to: trimmed, in: viewContext)
        }
        dismiss()
    }

    private func colorToHex(_ color: Color) -> String? {
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        let ri = Int(round(r * 255)), gi = Int(round(g * 255)), bi = Int(round(b * 255))
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }
}
