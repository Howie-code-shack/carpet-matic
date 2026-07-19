import SwiftUI
import SwiftData
import CarpetMaticEngine

struct ProjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ProjectModel.createdAt, order: .reverse)
    private var projects: [ProjectModel]

    @State private var showingNewProjectSheet = false
    @State private var pendingDeletion: IndexSet?

    var body: some View {
        NavigationStack {
            Group {
                if projects.isEmpty {
                    ContentUnavailableView(
                        "No projects yet",
                        systemImage: "house",
                        description: Text("Tap + to add your first project.")
                    )
                } else {
                    List {
                        ForEach(projects) { project in
                            NavigationLink {
                                ProjectDetailView(project: project)
                            } label: {
                                ProjectRow(project: project)
                            }
                        }
                        .onDelete { offsets in
                            pendingDeletion = offsets
                        }
                    }
                }
            }
            .confirmationDialog(
                deletionTitle,
                isPresented: Binding(
                    get: { pendingDeletion != nil },
                    set: { if !$0 { pendingDeletion = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let pendingDeletion {
                        deleteProjects(at: pendingDeletion)
                    }
                    pendingDeletion = nil
                }
                Button("Cancel", role: .cancel) {
                    pendingDeletion = nil
                }
            } message: {
                Text("This also deletes all of its rooms. You can't undo this.")
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewProjectSheet = true
                    } label: {
                        Label("New Project", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewProjectSheet) {
                NewProjectSheet { name, rollWidth in
                    let project = ProjectModel(name: name, rollWidthMetres: rollWidth)
                    modelContext.insert(project)
                }
            }
        }
    }

    private var deletionTitle: String {
        guard let pendingDeletion else { return "Delete project?" }
        if pendingDeletion.count == 1, let idx = pendingDeletion.first, idx < projects.count {
            let name = projects[idx].name
            return "Delete “\(name.isEmpty ? "Untitled" : name)”?"
        }
        return "Delete \(pendingDeletion.count) projects?"
    }

    private func deleteProjects(at offsets: IndexSet) {
        for idx in offsets where idx < projects.count {
            modelContext.delete(projects[idx])
        }
    }
}

private struct ProjectRow: View {
    let project: ProjectModel

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(project.name.isEmpty ? "Untitled" : project.name)
                .font(.headline)
            Text("\(project.rollWidthMetres) m roll · \((project.rooms ?? []).count) rooms")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

private struct NewProjectSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onCreate: (String, Int) -> Void

    @State private var name: String = ""
    @State private var rollWidth: Int = 4

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. 12 Acacia Ave", text: $name)
                }
                Section("Roll width") {
                    Picker("Roll width", selection: $rollWidth) {
                        ForEach(CarpetMaticEngine.Project.allowedRollWidthsMetres, id: \.self) { m in
                            Text("\(m) m").tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        onCreate(trimmed, rollWidth)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
