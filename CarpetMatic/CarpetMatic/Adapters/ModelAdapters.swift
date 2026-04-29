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
            kind: kind,
            pieces: (pieces ?? []).map { $0.toEngine() }
        )
    }
}

extension PieceModel {
    func toEngine() -> CarpetMaticEngine.Piece {
        CarpetMaticEngine.Piece(
            id: id,
            widthCM: widthCM,
            lengthCM: lengthCM,
            pileDirection: pileDirection,
            isRotated: isRotated
        )
    }
}
