import Foundation
import SwiftData
import CarpetMaticEngine

@Model
final class RoomModel {
    var id: UUID = UUID()
    var name: String = ""
    var widthCM: Int = 0
    var lengthCM: Int = 0
    var kindRaw: String = RoomKind.rectangle.rawValue
    var pileDirectionRaw: String = PileDirection.up.rawValue

    // Stair-calculator inputs (only meaningful when kind == .stairs).
    // 0 = not set. CloudKit-safe defaults; the calculator writes lengthCM.
    var stairSteps: Int = 0
    var stairTreadCM: Int = 0
    var stairRiserCM: Int = 0
    var stairNosingCM: Int = 0

    var project: ProjectModel?

    var kind: RoomKind {
        get { RoomKind(rawValue: kindRaw) ?? .rectangle }
        set { kindRaw = newValue.rawValue }
    }

    var pileDirection: PileDirection {
        get { PileDirection(rawValue: pileDirectionRaw) ?? .up }
        set { pileDirectionRaw = newValue.rawValue }
    }

    init(
        name: String = "",
        widthCM: Int = 0,
        lengthCM: Int = 0,
        kind: RoomKind = .rectangle,
        pileDirection: PileDirection = .up
    ) {
        self.name = name
        self.widthCM = widthCM
        self.lengthCM = lengthCM
        self.kindRaw = kind.rawValue
        self.pileDirectionRaw = pileDirection.rawValue
    }
}
