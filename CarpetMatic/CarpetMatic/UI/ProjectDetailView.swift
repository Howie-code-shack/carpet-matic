import SwiftUI
import SwiftData
import CarpetMaticEngine

struct ProjectDetailView: View {
    @Bindable var project: ProjectModel
    @Environment(\.modelContext) private var modelContext

    @State private var showingNewRoomSheet = false
    @State private var pendingRoomDeletion: IndexSet?
    @State private var priceText: String = ""

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
                HStack {
                    Text("Price per metre (\(MoneyFormat.currencySymbol))")
                    TextField("optional", text: $priceText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }

            Section {
                if rooms.isEmpty {
                    Text("No rooms yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(rooms) { room in
                        NavigationLink {
                            RoomDetailView(room: room, rollWidthMetres: project.rollWidthMetres)
                        } label: {
                            RoomRow(room: room)
                        }
                    }
                    .onDelete { offsets in
                        pendingRoomDeletion = offsets
                    }
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
                .disabled(rooms.isEmpty || rooms.allSatisfy { $0.widthCM == 0 || $0.lengthCM == 0 })
            }
        }
        .navigationTitle(project.name.isEmpty ? "Project" : project.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            seedPriceField()
        }
        .onChange(of: project.id) {
            seedPriceField()
        }
        .onChange(of: priceText) { _, new in
            if new.trimmingCharacters(in: .whitespaces).isEmpty {
                project.pricePerMetrePence = 0
            } else if let pence = MoneyFormat.parsePoundsToPence(new) {
                project.pricePerMetrePence = pence
            }
        }
        .confirmationDialog(
            roomDeletionTitle,
            isPresented: Binding(
                get: { pendingRoomDeletion != nil },
                set: { if !$0 { pendingRoomDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let pendingRoomDeletion {
                    deleteRooms(at: pendingRoomDeletion)
                }
                pendingRoomDeletion = nil
            }
            Button("Cancel", role: .cancel) {
                pendingRoomDeletion = nil
            }
        }
        .sheet(isPresented: $showingNewRoomSheet) {
            NewRoomSheet(rollWidthMetres: project.rollWidthMetres) { name, widthCM, lengthCM, kind in
                let pile = Room.optimalPileDirection(
                    widthCM: widthCM,
                    lengthCM: lengthCM,
                    rollWidthCM: project.rollWidthMetres * 100
                )
                let room = RoomModel(
                    name: name,
                    widthCM: widthCM,
                    lengthCM: lengthCM,
                    kind: kind,
                    pileDirection: pile
                )
                room.project = project
                modelContext.insert(room)
            }
        }
    }

    private func seedPriceField() {
        priceText = project.pricePerMetrePence > 0
            ? MoneyFormat.pounds(fromPence: project.pricePerMetrePence)
            : ""
    }

    private var roomDeletionTitle: String {
        guard let pendingRoomDeletion else { return "Delete room?" }
        if pendingRoomDeletion.count == 1, let idx = pendingRoomDeletion.first, idx < rooms.count {
            let name = rooms[idx].name
            return "Delete “\(name.isEmpty ? "Untitled" : name)”?"
        }
        return "Delete \(pendingRoomDeletion.count) rooms?"
    }

    private func deleteRooms(at offsets: IndexSet) {
        for idx in offsets where idx < rooms.count {
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
            HStack(spacing: 6) {
                if room.widthCM > 0, room.lengthCM > 0 {
                    Text("\(DimensionFormat.metres(fromCM: room.widthCM)) × \(DimensionFormat.metres(fromCM: room.lengthCM)) m")
                } else {
                    Text("Dimensions not set")
                }
                if room.kind == .stairs {
                    Text("· stairs")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

private struct NewRoomSheet: View {
    @Environment(\.dismiss) private var dismiss

    let rollWidthMetres: Int
    let onCreate: (_ name: String, _ widthCM: Int, _ lengthCM: Int, _ kind: RoomKind) -> Void

    @State private var name: String = ""
    @State private var widthText: String = ""
    @State private var lengthText: String = ""
    @State private var kind: RoomKind = .rectangle

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Lounge", text: $name)
                }
                Section("Dimensions (metres)") {
                    HStack {
                        Text("Width")
                        TextField("e.g. 4.50", text: $widthText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Length")
                        TextField("e.g. 5.20", text: $lengthText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
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
                        guard let w = DimensionFormat.parseMetresToCM(widthText), w > 0 else { return }
                        guard let l = DimensionFormat.parseMetresToCM(lengthText), l > 0 else { return }
                        onCreate(
                            name.trimmingCharacters(in: .whitespacesAndNewlines),
                            w, l, kind
                        )
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        guard let w = DimensionFormat.parseMetresToCM(widthText), w > 0,
              let l = DimensionFormat.parseMetresToCM(lengthText), l > 0 else { return false }
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
