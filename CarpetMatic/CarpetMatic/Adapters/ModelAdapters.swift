import Foundation
import CarpetMaticEngine

extension ProjectModel {
    func toEngine() -> CarpetMaticEngine.Project {
        CarpetMaticEngine.Project(
            id: id,
            name: name,
            rollWidthMetres: rollWidthMetres,
            rooms: (rooms ?? []).map { $0.toEngine() }
        )
    }
}

extension RoomModel {
    func toEngine() -> CarpetMaticEngine.Room {
        CarpetMaticEngine.Room(
            id: id,
            name: name,
            widthCM: widthCM,
            lengthCM: lengthCM,
            kind: kind,
            pileDirection: pileDirection
        )
    }
}
