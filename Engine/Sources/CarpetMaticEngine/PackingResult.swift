import Foundation

public struct PackingResult: Equatable, Sendable {
    public let totalLengthCM: Int
    public let perRoom: [RoomBreakdown]
    public let placements: [StripPlacement]

    public var totalLengthMetres: Double {
        Double(totalLengthCM) / 100.0
    }

    public init(totalLengthCM: Int, perRoom: [RoomBreakdown], placements: [StripPlacement]) {
        self.totalLengthCM = totalLengthCM
        self.perRoom = perRoom
        self.placements = placements
    }
}

public struct RoomBreakdown: Equatable, Sendable {
    public let roomID: UUID
    public let roomName: String
    public let kind: RoomKind
    public let strips: [StripPlacement]

    public init(roomID: UUID, roomName: String, kind: RoomKind, strips: [StripPlacement]) {
        self.roomID = roomID
        self.roomName = roomName
        self.kind = kind
        self.strips = strips
    }
}

/// One strip cut from the roll, placed at a specific position.
public struct StripPlacement: Equatable, Sendable {
    public let id: UUID
    public let roomID: UUID
    public let widthCM: Int
    public let lengthCM: Int
    public let pileDirection: PileDirection
    public let xCM: Int
    public let yCM: Int

    public init(
        id: UUID = UUID(),
        roomID: UUID,
        widthCM: Int,
        lengthCM: Int,
        pileDirection: PileDirection,
        xCM: Int,
        yCM: Int
    ) {
        self.id = id
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
    case invalidRoomDimensions(roomID: UUID)
}
