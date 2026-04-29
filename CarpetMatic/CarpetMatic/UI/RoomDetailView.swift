import SwiftUI
import SwiftData
import CarpetMaticEngine

struct RoomDetailView: View {
    @Bindable var room: RoomModel
    let rollWidthMetres: Int

    @State private var widthText: String = ""
    @State private var lengthText: String = ""

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
                }
                HStack {
                    Text("Length")
                    TextField("e.g. 5.20", text: $lengthText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }

            Section {
                Picker("Pile direction", selection: $room.pileDirection) {
                    ForEach(PileDirection.allCases, id: \.self) { d in
                        Text(arrow(for: d)).tag(d)
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
            widthText = DimensionFormat.metres(fromCM: room.widthCM)
            lengthText = DimensionFormat.metres(fromCM: room.lengthCM)
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

    private var stripsPreviewText: String? {
        guard room.widthCM > 0, room.lengthCM > 0, rollWidthMetres > 0 else { return nil }
        let rollWidthCM = rollWidthMetres * 100
        let stripsAlongLength = room.pileDirection.stripsAlongLength
        let stripWidth = stripsAlongLength ? room.widthCM : room.lengthCM
        let stripLength = stripsAlongLength ? room.lengthCM : room.widthCM
        let count = (stripWidth + rollWidthCM - 1) / rollWidthCM
        let totalCM = count * stripLength
        let s = count == 1 ? "strip" : "strips"
        return "\(count) \(s) · \(DimensionFormat.metres(fromCM: totalCM)) m of carpet for this room"
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
