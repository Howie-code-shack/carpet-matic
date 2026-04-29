import Foundation

public enum RoomKind: String, Codable, Sendable, CaseIterable {
    case rectangle
    case stairs
}

public enum PileDirection: String, Codable, Sendable, CaseIterable {
    case up, down, left, right

    public func rotated90Clockwise() -> PileDirection {
        switch self {
        case .up: return .right
        case .right: return .down
        case .down: return .left
        case .left: return .up
        }
    }
}

public struct Piece: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var widthCM: Int
    public var lengthCM: Int
    public var pileDirection: PileDirection
    public var isRotated: Bool

    public init(
        id: UUID = UUID(),
        widthCM: Int,
        lengthCM: Int,
        pileDirection: PileDirection = .up,
        isRotated: Bool = false
    ) {
        self.id = id
        self.widthCM = widthCM
        self.lengthCM = lengthCM
        self.pileDirection = pileDirection
        self.isRotated = isRotated
    }

    public var effectiveWidthCM: Int {
        isRotated ? lengthCM : widthCM
    }

    public var effectiveLengthCM: Int {
        isRotated ? widthCM : lengthCM
    }

    public var effectivePileDirection: PileDirection {
        isRotated ? pileDirection.rotated90Clockwise() : pileDirection
    }
}

public struct Room: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var kind: RoomKind
    public var pieces: [Piece]

    public init(
        id: UUID = UUID(),
        name: String,
        kind: RoomKind = .rectangle,
        pieces: [Piece] = []
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.pieces = pieces
    }
}

public struct Project: Identifiable, Hashable, Sendable {
    public static let allowedRollWidthsMetres: [Int] = [1, 2, 3, 4, 5]

    public let id: UUID
    public var name: String
    public var rollWidthMetres: Int
    public var rooms: [Room]

    public init(
        id: UUID = UUID(),
        name: String,
        rollWidthMetres: Int,
        rooms: [Room] = []
    ) {
        self.id = id
        self.name = name
        self.rollWidthMetres = rollWidthMetres
        self.rooms = rooms
    }

    public var rollWidthCM: Int { rollWidthMetres * 100 }
}
