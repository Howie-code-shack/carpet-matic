import SwiftUI
import CarpetMaticEngine

struct PieceEditorView: View {
    @Bindable var piece: PieceModel
    let rollWidthMetres: Int

    @State private var widthText: String = ""
    @State private var lengthText: String = ""

    var body: some View {
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
                if !widthFits {
                    Text("Effective width \(DimensionFormat.metres(fromCM: effectiveWidthCM)) m exceeds the \(rollWidthMetres) m roll.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("Pile direction") {
                Picker("Direction", selection: $piece.pileDirection) {
                    ForEach(PileDirection.allCases, id: \.self) { d in
                        Text(arrow(for: d)).tag(d)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                Toggle(isOn: $piece.isRotated) {
                    Label("Rotated 90°", systemImage: "rotate.right")
                }
            } header: {
                Text("Orientation")
            } footer: {
                Text("Rotation swaps width and length. Pile direction rotates with the piece.")
            }

            Section("Preview") {
                HStack {
                    Text(previewLine)
                    Spacer()
                    PileArrowView(direction: effectivePile)
                }
            }
        }
        .navigationTitle("Edit Piece")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            widthText = DimensionFormat.metres(fromCM: piece.widthCM)
            lengthText = DimensionFormat.metres(fromCM: piece.lengthCM)
        }
        .onChange(of: widthText) { _, new in
            if let cm = DimensionFormat.parseMetresToCM(new), cm > 0 {
                piece.widthCM = cm
            }
        }
        .onChange(of: lengthText) { _, new in
            if let cm = DimensionFormat.parseMetresToCM(new), cm > 0 {
                piece.lengthCM = cm
            }
        }
    }

    private var effectiveWidthCM: Int {
        piece.isRotated ? piece.lengthCM : piece.widthCM
    }

    private var effectiveLengthCM: Int {
        piece.isRotated ? piece.widthCM : piece.lengthCM
    }

    private var widthFits: Bool {
        effectiveWidthCM > 0 && effectiveWidthCM <= rollWidthMetres * 100
    }

    private var effectivePile: PileDirection {
        piece.isRotated ? piece.pileDirection.rotated90Clockwise() : piece.pileDirection
    }

    private var previewLine: String {
        "\(DimensionFormat.metres(fromCM: effectiveWidthCM)) × \(DimensionFormat.metres(fromCM: effectiveLengthCM)) m"
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
