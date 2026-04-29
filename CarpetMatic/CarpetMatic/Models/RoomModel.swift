import Foundation
import SwiftData
import CarpetMaticEngine

@Model
final class RoomModel {
    var id: UUID = UUID()
    var name: String = ""
    var kindRaw: String = RoomKind.rectangle.rawValue

    var project: ProjectModel?

    @Relationship(deleteRule: .cascade, inverse: \PieceModel.room)
    var pieces: [PieceModel]? = []

    var kind: RoomKind {
        get { RoomKind(rawValue: kindRaw) ?? .rectangle }
        set { kindRaw = newValue.rawValue }
    }

    init(name: String = "", kind: RoomKind = .rectangle) {
        self.name = name
        self.kindRaw = kind.rawValue
    }
}
