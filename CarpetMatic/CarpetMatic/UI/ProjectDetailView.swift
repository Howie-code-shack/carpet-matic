import SwiftUI
import SwiftData
import CarpetMaticEngine

struct ProjectDetailView: View {
    @Bindable var project: ProjectModel
    @Environment(\.modelContext) private var modelContext

    @State private var showingNewRoomSheet = false

    private var rooms: [RoomModel] {
        project.rooms ?? []
    }

    var body: some View {
        Form {
            Section("Project") {
                TextField("Name", text: $project.name)
                Picker("Roll width", selection: $project.rollWidthMetres) {
                    ForEach(CarpetMaticEngine.Project.allowedRollWidthsMetres, id: \.self) { m in
                        Text("\(m) m").tag(m)
                    }
                }
            }

            Section {
                if rooms.isEmpty {
                    Text("No rooms yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(rooms) { room in
                        NavigationLink {
                            RoomDetailView(room: room)
                        } label: {
                            RoomRow(room: room)
                        }
                    }
                    .onDelete(perform: deleteRooms)
                }

                Button {
                    showingNewRoomSheet = true
                } label: {
                    Label("Add room", systemImage: "plus")
                }
            } header: {
                Text("Rooms")
            }

            Section {
                NavigationLink {
                    ResultView(project: project)
                } label: {
                    Label("Calculate", systemImage: "function")
                        .font(.headline)
                }
                .disabled(rooms.allSatisfy { ($0.pieces ?? []).isEmpty })
            }
        }
        .navigationTitle(project.name.isEmpty ? "Project" : project.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingNewRoomSheet) {
            NewRoomSheet { name, kind in
                let room = RoomModel(name: name, kind: kind)
                room.project = project
                modelContext.insert(room)
            }
        }
    }

    private func deleteRooms(at offsets: IndexSet) {
        for idx in offsets {
            modelContext.delete(rooms[idx])
        }
    }
}

private struct RoomRow: View {
    let room: RoomModel

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(room.name.isEmpty ? "Untitled" : room.name)
                .font(.headline)
            Text("\(room.kind == .stairs ? "Stairs" : "Rectangle") · \((room.pieces ?? []).count) pieces")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

private struct NewRoomSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onCreate: (String, RoomKind) -> Void

    @State private var name: String = ""
    @State private var kind: RoomKind = .rectangle

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Lounge", text: $name)
                }
                Section("Type") {
                    Picker("Type", selection: $kind) {
                        Text("Rectangle").tag(RoomKind.rectangle)
                        Text("Stairs").tag(RoomKind.stairs)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("New Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onCreate(name.trimmingCharacters(in: .whitespacesAndNewlines), kind)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
