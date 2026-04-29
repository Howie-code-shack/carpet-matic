import SwiftUI
import SwiftData
import CarpetMaticEngine

struct RoomDetailView: View {
    @Bindable var room: RoomModel
    @Environment(\.modelContext) private var modelContext

    @State private var showingNewPieceSheet = false

    private var pieces: [PieceModel] {
        room.pieces ?? []
    }

    private var rollWidthMetres: Int {
        room.project?.rollWidthMetres ?? 4
    }

    var body: some View {
        Form {
            Section("Room") {
                TextField("Name", text: $room.name)
                Picker("Type", selection: $room.kind) {
                    Text("Rectangle").tag(RoomKind.rectangle)
                    Text("Stairs").tag(RoomKind.stairs)
                }
                .pickerStyle(.segmented)
            }

            Section {
                if pieces.isEmpty {
                    Text("No pieces yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(pieces) { piece in
                        NavigationLink {
                            PieceEditorView(piece: piece, rollWidthMetres: rollWidthMetres)
                        } label: {
                            PieceRow(piece: piece)
                        }
                    }
                    .onDelete(perform: deletePieces)
                }

                Button {
                    showingNewPieceSheet = true
                } label: {
                    Label("Add piece", systemImage: "plus")
                }
            } header: {
                Text("Pieces")
            } footer: {
                Text("Width must be ≤ \(rollWidthMetres) m (the project's roll width). Enter dimensions in metres; round up at input — the software does not pad measurements.")
            }
        }
        .navigationTitle(room.name.isEmpty ? "Room" : room.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingNewPieceSheet) {
            NewPieceSheet(rollWidthMetres: rollWidthMetres) { width, length, pile in
                let piece = PieceModel(widthCM: width, lengthCM: length, pileDirection: pile)
                piece.room = room
                modelContext.insert(piece)
            }
        }
    }

    private func deletePieces(at offsets: IndexSet) {
        for idx in offsets {
            modelContext.delete(pieces[idx])
        }
    }
}

private struct PieceRow: View {
    let piece: PieceModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(DimensionFormat.metres(fromCM: piece.widthCM)) × \(DimensionFormat.metres(fromCM: piece.lengthCM)) m")
                    .font(.headline)
                if piece.isRotated {
                    Text("Rotated 90°")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            PileArrowView(direction: effectivePile)
        }
        .padding(.vertical, 2)
    }

    private var effectivePile: PileDirection {
        piece.isRotated ? piece.pileDirection.rotated90Clockwise() : piece.pileDirection
    }
}

private struct NewPieceSheet: View {
    @Environment(\.dismiss) private var dismiss

    let rollWidthMetres: Int
    let onCreate: (_ widthCM: Int, _ lengthCM: Int, _ pile: PileDirection) -> Void

    @State private var widthText: String = ""
    @State private var lengthText: String = ""
    @State private var pile: PileDirection = .up

    var body: some View {
        NavigationStack {
            Form {
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
                    if let widthCM = parseInputs().widthCM,
                       widthCM > rollWidthMetres * 100 {
                        Text("Width exceeds the \(rollWidthMetres) m roll.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                Section("Pile direction") {
                    Picker("Direction", selection: $pile) {
                        ForEach(PileDirection.allCases, id: \.self) { d in
                            Text(arrow(for: d)).tag(d)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("New Piece")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let parsed = parseInputs()
                        if let w = parsed.widthCM, let l = parsed.lengthCM {
                            onCreate(w, l, pile)
                            dismiss()
                        }
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private func parseInputs() -> (widthCM: Int?, lengthCM: Int?) {
        (DimensionFormat.parseMetresToCM(widthText),
         DimensionFormat.parseMetresToCM(lengthText))
    }

    private var isValid: Bool {
        let parsed = parseInputs()
        guard let w = parsed.widthCM, let l = parsed.lengthCM else { return false }
        return w > 0 && l > 0 && w <= rollWidthMetres * 100
    }

    private func arrow(for d: PileDirection) -> String {
        switch d {
        case .up: return "↑"
        case .right: return "→"
        case .down: return "↓"
        case .left: return "←"
        }
    }
}
