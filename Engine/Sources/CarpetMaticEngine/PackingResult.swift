import Foundation

public struct PackingResult: Equatable, Sendable {
    public let totalLengthCM: Int
    public let perRoom: [RoomBreakdown]
    public let placements: [PiecePlacement]

    public var totalLengthMetres: Double {
        Double(totalLengthCM) / 100.0
    }

    public init(totalLengthCM: Int, perRoom: [RoomBreakdown], placements: [PiecePlacement]) {
        self.totalLengthCM = totalLengthCM
        self.perRoom = perRoom
        self.placements = placements
    }
}

public struct RoomBreakdown: Equatable, Sendable {
    public let roomID: UUID
    public let roomName: String
    public let kind: RoomKind
    public let pieces: [PiecePlacement]

    public init(roomID: UUID, roomName: String, kind: RoomKind, pieces: [PiecePlacement]) {
        self.roomID = roomID
        self.roomName = roomName
        self.kind = kind
        self.pieces = pieces
    }
}

public struct PiecePlacement: Equatable, Sendable {
    public let pieceID: UUID
    public let roomID: UUID
    public let widthCM: Int
    public let lengthCM: Int
    public let pileDirection: PileDirection
    public let xCM: Int
    public let yCM: Int

    public init(
        pieceID: UUID,
        roomID: UUID,
        widthCM: Int,
        lengthCM: Int,
        pileDirection: PileDirection,
        xCM: Int,
        yCM: Int
    ) {
        self.pieceID = pieceID
        self.roomID = roomID
        self.widthCM = widthCM
        self.lengthCM = lengthCM
        self.pileDirection = pileDirection
        self.xCM = xCM
        self.yCM = yCM
    }
}

public enum PackingError: Error, Equatable, Sendable {
    case invalidRollWidthMetres(Int)
    case pieceWiderThanRoll(pieceID: UUID, pieceWidthCM: Int, rollWidthCM: Int)
    case nonPositiveDimension(pieceID: UUID)
}
