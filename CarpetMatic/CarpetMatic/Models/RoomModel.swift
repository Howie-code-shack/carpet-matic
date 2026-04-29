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
