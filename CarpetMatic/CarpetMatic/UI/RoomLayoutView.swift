import SwiftUI
import CarpetMaticEngine

/// Top-down visual of a single room, drawn proportional to its dimensions.
/// Each strip is a tappable rectangle; tapping advances the room's pile
/// direction 90° clockwise (up → right → down → left → up).
struct RoomLayoutView: View {
    let widthCM: Int
    let lengthCM: Int
    let pileDirection: PileDirection
    let rollWidthCM: Int
    let onTapStrip: () -> Void

    var body: some View {
        GeometryReader { geo in
            content(in: geo.size)
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
    }

    private var aspectRatio: CGFloat {
        guard widthCM > 0, lengthCM > 0 else { return 1 }
        return CGFloat(widthCM) / CGFloat(lengthCM)
    }

    @ViewBuilder
    private func content(in size: CGSize) -> some View {
        if widthCM <= 0 || lengthCM <= 0 || rollWidthCM <= 0 {
            placeholder
        } else {
            let scale = computeScale(in: size)
            let roomW = CGFloat(widthCM) * scale
            let roomL = CGFloat(lengthCM) * scale
            let originX = (size.width - roomW) / 2
            let originY = (size.height - roomL) / 2
            let strips = computeStripRects()

            ZStack(alignment: .topLeading) {
                ForEach(Array(strips.enumerated()), id: \.offset) { idx, strip in
                    let stripFrame = CGRect(
                        x: originX + CGFloat(strip.x) * scale,
                        y: originY + CGFloat(strip.y) * scale,
                        width: CGFloat(strip.width) * scale,
                        height: CGFloat(strip.height) * scale
                    )
                    stripView(index: idx, frame: stripFrame)
                }

                Rectangle()
                    .stroke(Color.primary, lineWidth: 2)
                    .frame(width: roomW, height: roomL)
                    .position(x: originX + roomW / 2, y: originY + roomL / 2)
                    .allowsHitTesting(false)
            }
        }
    }

    private func stripView(index: Int, frame: CGRect) -> some View {
        let fill = index.isMultiple(of: 2) ? Color.accentColor.opacity(0.18) : Color.accentColor.opacity(0.32)
        return ZStack {
            Rectangle()
                .fill(fill)
                .overlay(Rectangle().stroke(Color.gray.opacity(0.6), lineWidth: 0.5))
            arrow
        }
        .frame(width: frame.width, height: frame.height)
        .position(x: frame.midX, y: frame.midY)
        .contentShape(Rectangle())
        .onTapGesture { onTapStrip() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Strip \(index + 1) of \(stripCount), pile \(pileDirection.rawValue). Tap to rotate pile direction.")
        .accessibilityAddTraits(.isButton)
    }

    private var arrow: some View {
        Image(systemName: "arrow.up")
            .font(.system(size: 18, weight: .bold))
            .rotationEffect(rotation(for: pileDirection))
            .foregroundStyle(.tint)
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                )
            Text("Enter dimensions to see the layout")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Geometry helpers

    private func computeScale(in size: CGSize) -> CGFloat {
        let usableW = max(size.width - 8, 1)
        let usableH = max(size.height - 8, 1)
        return min(usableW / CGFloat(widthCM), usableH / CGFloat(lengthCM))
    }

    private func computeStripRects() -> [StripRect] {
        var rects: [StripRect] = []
        let stripsAlongLength = pileDirection.stripsAlongLength

        if stripsAlongLength {
            var x = 0
            var remaining = widthCM
            while remaining > 0 {
                let w = min(remaining, rollWidthCM)
                rects.append(StripRect(x: x, y: 0, width: w, height: lengthCM))
                x += w
                remaining -= w
            }
        } else {
            var y = 0
            var remaining = lengthCM
            while remaining > 0 {
                let h = min(remaining, rollWidthCM)
                rects.append(StripRect(x: 0, y: y, width: widthCM, height: h))
                y += h
                remaining -= h
            }
        }
        return rects
    }

    private var stripCount: Int {
        let stripsAlongLength = pileDirection.stripsAlongLength
        let perp = stripsAlongLength ? widthCM : lengthCM
        return (perp + rollWidthCM - 1) / rollWidthCM
    }

    private func rotation(for direction: PileDirection) -> Angle {
        switch direction {
        case .up:    return .degrees(0)
        case .right: return .degrees(90)
        case .down:  return .degrees(180)
        case .left:  return .degrees(270)
        }
    }
}

private struct StripRect {
    let x: Int
    let y: Int
    let width: Int
    let height: Int
}
