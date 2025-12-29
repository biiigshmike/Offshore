import SwiftUI
import CoreData

// MARK: - WorkspaceMenuButton
/// Toolbar menu for selecting and managing profiles/workspaces.
struct WorkspaceMenuButton: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Workspace.entity(),
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
    ) private var workspaces: FetchedResults<Workspace>
    @AppStorage(AppSettingsKeys.activeWorkspaceID.rawValue) private var activeWorkspaceIDRaw: String = ""

    @State private var showAdd = false
    @State private var showManage = false

    var body: some View {
        Menu {
            workspaceListSection
            Divider()
            Button("Add New Profile") { showAdd = true }
            Button("Manage Profiles") { showManage = true }
        } label: {
            workspaceMenuLabel
        }
        .accessibilityLabel("Profile Menu")
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
        let activeID = UUID(uuidString: activeWorkspaceIDRaw)
        ForEach(workspaces) { workspace in
            Button {
                guard let id = workspace.id else { return }
                WorkspaceService.shared.setActiveWorkspaceID(id)
                activeWorkspaceIDRaw = id.uuidString
            } label: {
                HStack(spacing: 10) {
                    Text(workspace.name ?? "Untitled")
                    if activeID == workspace.id {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var workspaceMenuLabel: some View {
        if #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
            let label = Label("Profile", systemImage: "person.3.fill")
                .labelStyle(.iconOnly)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 44, height: 44, alignment: .center)
                .glassEffect(.regular.tint(.clear).interactive(true))
            label
                .buttonStyle(.plain)
                .frame(width: 44, height: 44, alignment: .center)
                .clipShape(Circle())
                .compositingGroup()
        } else {
            Image(systemName: "person.3.fill")
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 33, height: 33)
        }
    }
}

// MARK: - WorkspaceManagerView
/// Sheet that lists all profiles and allows renaming or deletion.
struct WorkspaceManagerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(
        entity: Workspace.entity(),
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
    ) private var workspaces: FetchedResults<Workspace>
    @AppStorage(AppSettingsKeys.activeWorkspaceID.rawValue) private var activeWorkspaceIDRaw: String = ""

    @State private var editingWorkspace: Workspace?
    @State private var workspaceToDelete: Workspace?
    @State private var showAddSheet = false

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
            activeWorkspaceIDRaw = id.uuidString
        }
    }

    private func workspaceRow(for workspace: Workspace) -> some View {
        let isActive = UUID(uuidString: activeWorkspaceIDRaw) == workspace.id
        let isPersonal = WorkspaceService.shared.isPersonalWorkspace(workspace)
        let config = UnifiedSwipeConfig(
            showsDeleteAction: !isPersonal,
            allowsFullSwipeToDelete: !isPersonal
        )
        return HStack {
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

    var body: some View {
        NavigationStack {
            List {
                Section("Profile Name") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(mode.title)
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
        case .edit(let workspace):
            name = workspace.name ?? ""
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        switch mode {
        case .add:
            if let workspace = WorkspaceService.shared.createWorkspace(named: trimmed, in: viewContext),
               let id = workspace.id {
                WorkspaceService.shared.setActiveWorkspaceID(id)
            }
        case .edit(let workspace):
            _ = WorkspaceService.shared.renameWorkspace(workspace, to: trimmed, in: viewContext)
        }
        dismiss()
    }
}
