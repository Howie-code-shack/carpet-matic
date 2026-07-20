import Foundation

public struct PackingResult: Equatable, Sendable {
    public let totalLengthCM: Int
    public let perRoom: [RoomBreakdown]
    public let placements: [StripPlacement]

    public var totalLengthMetres: Double {
        Double(totalLengthCM) / 100.0
    }

    /// Total area of carpet actually used by all strips, in cm².
    public var usedAreaCM2: Int {
        placements.reduce(0) { $0 + $1.widthCM * $1.lengthCM }
    }

    /// Area of roll consumed (roll width × total length), in cm².
    public func rollAreaCM2(rollWidthCM: Int) -> Int {
        rollWidthCM * totalLengthCM
    }

    /// Offcut area — roll consumed minus carpet used, in cm². Never negative.
    public func wasteAreaCM2(rollWidthCM: Int) -> Int {
        max(0, rollAreaCM2(rollWidthCM: rollWidthCM) - usedAreaCM2)
    }

    /// Offcut area in m².
    public func wasteAreaMetresSquared(rollWidthCM: Int) -> Double {
        Double(wasteAreaCM2(rollWidthCM: rollWidthCM)) / 10_000.0
    }

    /// Fraction of the consumed roll that ends up as carpet (0…1).
    /// Returns 0 when nothing is consumed.
    public func efficiencyFraction(rollWidthCM: Int) -> Double {
        let rollArea = rollAreaCM2(rollWidthCM: rollWidthCM)
        guard rollArea > 0 else { return 0 }
        return Double(usedAreaCM2) / Double(rollArea)
    }

    /// Fraction of the consumed roll that ends up as offcut (0…1).
    public func wasteFraction(rollWidthCM: Int) -> Double {
        guard rollAreaCM2(rollWidthCM: rollWidthCM) > 0 else { return 0 }
        return 1 - efficiencyFraction(rollWidthCM: rollWidthCM)
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
