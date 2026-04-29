import SwiftUI
import CarpetMaticEngine

struct PileArrowView: View {
    let direction: PileDirection
    var size: CGFloat = 18

    var body: some View {
        Image(systemName: "arrow.up")
            .font(.system(size: size, weight: .semibold))
            .rotationEffect(rotation)
            .foregroundStyle(.tint)
            .accessibilityLabel("Pile direction: \(direction.rawValue)")
    }

    private var rotation: Angle {
        switch direction {
        case .up:    return .degrees(0)
        case .right: return .degrees(90)
        case .down:  return .degrees(180)
        case .left:  return .degrees(270)
        }
    }
}
