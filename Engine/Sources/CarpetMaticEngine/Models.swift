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

    /// True if strips for a room with this pile run along the room's Length axis.
    /// Pile up/down → strips along Length; pile left/right → strips along Width.
    public var stripsAlongLength: Bool {
        switch self {
        case .up, .down: return true
        case .left, .right: return false
        }
    }
}

/// A single rectangular room. The engine generates the strips itself; the user
/// never enters strips/pieces directly.
public struct Room: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var widthCM: Int
    public var lengthCM: Int
    public var kind: RoomKind
    public var pileDirection: PileDirection

    public init(
        id: UUID = UUID(),
        name: String = "",
        widthCM: Int,
        lengthCM: Int,
        kind: RoomKind = .rectangle,
        pileDirection: PileDirection = .up
    ) {
        self.id = id
        self.name = name
        self.widthCM = widthCM
        self.lengthCM = lengthCM
        self.kind = kind
        self.pileDirection = pileDirection
    }

    /// The pile direction that yields the fewest linear metres of carpet for this
    /// room on a given roll. Returns `.up` if strips along Length wins (or ties),
    /// `.right` otherwise. Only the axis (up/down vs left/right) matters for the math.
    public static func optimalPileDirection(
        widthCM: Int,
        lengthCM: Int,
        rollWidthCM: Int
    ) -> PileDirection {
        let alongLength = ceilDiv(widthCM, rollWidthCM) * lengthCM
        let alongWidth  = ceilDiv(lengthCM, rollWidthCM) * widthCM
        return alongLength <= alongWidth ? .up : .right
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

/// Internal helper exposed because both the engine and consumers compute strip counts.
@usableFromInline
internal func ceilDiv(_ a: Int, _ b: Int) -> Int {
    precondition(b > 0, "ceilDiv divisor must be positive")
    return (a + b - 1) / b
}

/// A rectangle the packer places on the roll. With the room-input model this is
/// always a strip the engine generated from a Room — not a user input.
public struct Piece: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var widthCM: Int
    public var lengthCM: Int
    public var pileDirection: PileDirection

    public init(
        id: UUID = UUID(),
        widthCM: Int,
        lengthCM: Int,
        pileDirection: PileDirection = .up
    ) {
        self.id = id
        self.widthCM = widthCM
        self.lengthCM = lengthCM
        self.pileDirection = pileDirection
    }
}
