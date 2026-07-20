import SwiftUI
import CarpetMaticEngine

/// Whole-roll view: draws every strip where the engine placed it on the roll,
/// coloured by room, with pile arrows and dimensions. The roll width is fitted
/// to the screen; the roll length scrolls vertically.
struct RollLayoutView: View {
    let result: PackingResult
    let rollWidthCM: Int

    private static let palette: [Color] = [
        .blue, .green, .orange, .purple, .pink, .teal, .indigo, .red, .cyan, .brown,
    ]

    private var roomOrder: [UUID] { result.perRoom.map(\.roomID) }

    private var roomNames: [UUID: String] {
        Dictionary(result.perRoom.map { ($0.roomID, $0.roomName) },
                   uniquingKeysWith: { first, _ in first })
    }

    private func color(for roomID: UUID) -> Color {
        guard let idx = roomOrder.firstIndex(of: roomID) else { return .gray }
        return Self.palette[idx % Self.palette.count]
    }

    var body: some View {
        GeometryReader { geo in
            let available = max(geo.size.width - 32, 1)
            let scale = available / CGFloat(max(rollWidthCM, 1))
            let rollW = CGFloat(rollWidthCM) * scale
            let rollL = CGFloat(result.totalLengthCM) * scale

            ScrollView(.vertical) {
                HStack {
                    Spacer(minLength: 0)
                    ZStack(alignment: .topLeading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.12))
                            .overlay(Rectangle().stroke(Color.primary.opacity(0.4), lineWidth: 1))
                            .frame(width: rollW, height: rollL)

                        ForEach(result.placements, id: \.id) { placement in
                            stripCell(placement, scale: scale)
                        }
                    }
                    .frame(width: rollW, height: rollL)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Roll layout")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            summaryBar
        }
    }

    private func stripCell(_ p: StripPlacement, scale: CGFloat) -> some View {
        let w = CGFloat(p.widthCM) * scale
        let h = CGFloat(p.lengthCM) * scale
        let roomColor = color(for: p.roomID)
        let compact = min(w, h) < 44

        return VStack(spacing: 1) {
            if !compact {
                Text(roomNames[p.roomID] ?? "")
                    .font(.caption2).bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            PileArrowView(direction: p.pileDirection, size: compact ? 11 : 16)
            if !compact {
                Text("\(DimensionFormat.metres(fromCM: p.widthCM))×\(DimensionFormat.metres(fromCM: p.lengthCM))")
                    .font(.system(size: 9))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding(2)
        .frame(width: w, height: h)
        .background(roomColor.opacity(0.25))
        .overlay(Rectangle().stroke(roomColor, lineWidth: 1))
        .clipped()
        .tint(roomColor)
        .position(x: CGFloat(p.xCM) * scale + w / 2,
                  y: CGFloat(p.yCM) * scale + h / 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(roomNames[p.roomID] ?? "Room"), strip \(DimensionFormat.metres(fromCM: p.widthCM)) by \(DimensionFormat.metres(fromCM: p.lengthCM)) metres, pile \(p.pileDirection.rawValue)"
        )
    }

    private var summaryBar: some View {
        let wastePct = result.wasteFraction(rollWidthCM: rollWidthCM) * 100
        return HStack {
            Label("\(rollWidthCM / 100) m roll", systemImage: "ruler")
            Spacer()
            Text("\(DimensionFormat.metres(fromCM: result.totalLengthCM)) m")
                .bold()
                .monospacedDigit()
            Text(String(format: "· %.0f%% offcut", wastePct))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .font(.footnote)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }
}
