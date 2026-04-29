import Foundation
import SwiftData
import CarpetMaticEngine

@Model
final class PieceModel {
    var id: UUID = UUID()
    var widthCM: Int = 100
    var lengthCM: Int = 100
    var pileDirectionRaw: String = PileDirection.up.rawValue
    var isRotated: Bool = false

    var room: RoomModel?

    var pileDirection: PileDirection {
        get { PileDirection(rawValue: pileDirectionRaw) ?? .up }
        set { pileDirectionRaw = newValue.rawValue }
    }

    init(
        widthCM: Int = 100,
        lengthCM: Int = 100,
        pileDirection: PileDirection = .up,
        isRotated: Bool = false
    ) {
        self.widthCM = widthCM
        self.lengthCM = lengthCM
        self.pileDirectionRaw = pileDirection.rawValue
        self.isRotated = isRotated
    }
}
