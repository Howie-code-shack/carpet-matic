import SwiftUI
import SwiftData
import CarpetMaticEngine

struct RoomDetailView: View {
    @Bindable var room: RoomModel
    let rollWidthMetres: Int

    @State private var widthText: String = ""
    @State private var lengthText: String = ""
    @State private var treadText: String = ""
    @State private var riserText: String = ""
    @State private var nosingText: String = ""

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

            Section("Dimensions (metres)") {
                HStack {
                    Text("Width")
                    TextField("e.g. 4.50", text: $widthText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .accessibilityLabel("Room width in metres")
                }
                HStack {
                    Text("Length")
                    TextField("e.g. 5.20", text: $lengthText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .accessibilityLabel("Room length in metres")
                }
            }

            if room.kind == .stairs {
                Section {
                    Stepper(
                        "Steps: \(room.stairSteps)",
                        value: $room.stairSteps,
                        in: 0...60
                    )
                    HStack {
                        Text("Tread depth (cm)")
                        TextField("e.g. 23", text: $treadText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Tread depth in centimetres")
                    }
                    HStack {
                        Text("Riser height (cm)")
                        TextField("e.g. 20", text: $riserText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Riser height in centimetres")
                    }
                    HStack {
                        Text("Nosing allowance (cm)")
                        TextField("e.g. 4", text: $nosingText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Nosing allowance in centimetres per step")
                    }
                    if let totalCM = stairTotalCM {
                        Button {
                            room.lengthCM = totalCM
                            lengthText = DimensionFormat.metres(fromCM: totalCM)
                        } label: {
                            Label(
                                "Use \(DimensionFormat.metres(fromCM: totalCM)) m as length",
                                systemImage: "arrow.down.circle"
                            )
                        }
                    }
                } header: {
                    Text("Stair calculator")
                } footer: {
                    Text("Length per step = tread + riser + nosing. Enter the stair width above.")
                }
            }

            Section {
                Picker("Pile direction", selection: $room.pileDirection) {
                    ForEach(PileDirection.allCases, id: \.self) { d in
                        Text(arrow(for: d))
                            .accessibilityLabel("Pile \(d.rawValue)")
                            .tag(d)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Pile direction")
            } footer: {
                stripsFooter
            }

            Section {
                RoomLayoutView(
                    widthCM: room.widthCM,
                    lengthCM: room.lengthCM,
                    pileDirection: room.pileDirection,
                    rollWidthCM: rollWidthMetres * 100,
                    onTapStrip: cyclePileDirection
                )
                .frame(minHeight: 220)
                .padding(.vertical, 8)
            } header: {
                Text("Layout")
            } footer: {
                Text("Tap any strip to rotate the pile direction 90°.")
            }
        }
        .navigationTitle(room.name.isEmpty ? "Room" : room.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            seedDimensionFields()
        }
        .onChange(of: room.id) {
            seedDimensionFields()
        }
        .onChange(of: widthText) { _, new in
            if let cm = DimensionFormat.parseMetresToCM(new), cm > 0 {
                room.widthCM = cm
            }
        }
        .onChange(of: lengthText) { _, new in
            if let cm = DimensionFormat.parseMetresToCM(new), cm > 0 {
                room.lengthCM = cm
            }
        }
        .onChange(of: treadText) { _, new in
            room.stairTreadCM = Int(new.trimmingCharacters(in: .whitespaces)) ?? 0
        }
        .onChange(of: riserText) { _, new in
            room.stairRiserCM = Int(new.trimmingCharacters(in: .whitespaces)) ?? 0
        }
        .onChange(of: nosingText) { _, new in
            room.stairNosingCM = Int(new.trimmingCharacters(in: .whitespaces)) ?? 0
        }
    }

    /// steps × (tread + riser + nosing); nil until steps, tread, and riser are set.
    private var stairTotalCM: Int? {
        guard room.stairSteps > 0, room.stairTreadCM > 0, room.stairRiserCM > 0 else { return nil }
        return room.stairSteps * (room.stairTreadCM + room.stairRiserCM + max(0, room.stairNosingCM))
    }

    @ViewBuilder
    private var stripsFooter: some View {
        if let preview = stripsPreviewText {
            VStack(alignment: .leading, spacing: 4) {
                Text(preview)
                if !isOptimal {
                    Text("Tip: rotating pile 90° would use less carpet.")
                        .foregroundStyle(.orange)
                }
            }
        } else {
            Text("Enter dimensions to see strip count.")
        }
    }

    private func seedDimensionFields() {
        widthText = DimensionFormat.metres(fromCM: room.widthCM)
        lengthText = DimensionFormat.metres(fromCM: room.lengthCM)
        treadText = room.stairTreadCM > 0 ? String(room.stairTreadCM) : ""
        riserText = room.stairRiserCM > 0 ? String(room.stairRiserCM) : ""
        nosingText = room.stairNosingCM > 0 ? String(room.stairNosingCM) : ""
    }

    private var stripsPreviewText: String? {
        guard room.widthCM > 0, room.lengthCM > 0, rollWidthMetres > 0 else { return nil }
        let strips = PackingEngine.strips(for: room.toEngine(), rollWidthCM: rollWidthMetres * 100)
        guard !strips.isEmpty else { return nil }
        let totalCM = strips.map(\.lengthCM).reduce(0, +)
        let s = strips.count == 1 ? "strip" : "strips"
        return "\(strips.count) \(s) · \(DimensionFormat.metres(fromCM: totalCM)) m of carpet for this room"
    }

    private var isOptimal: Bool {
        let rollWidthCM = rollWidthMetres * 100
        let optimalAxis = Room.optimalPileDirection(
            widthCM: room.widthCM,
            lengthCM: room.lengthCM,
            rollWidthCM: rollWidthCM
        )
        return room.pileDirection.stripsAlongLength == optimalAxis.stripsAlongLength
    }

    private func arrow(for d: PileDirection) -> String {
        switch d {
        case .up: return "↑"
        case .right: return "→"
        case .down: return "↓"
        case .left: return "←"
        }
    }

    private func cyclePileDirection() {
        room.pileDirection = room.pileDirection.rotated90Clockwise()
    }
}
