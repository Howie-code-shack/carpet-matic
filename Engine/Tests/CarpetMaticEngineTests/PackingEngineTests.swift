import XCTest
@testable import CarpetMaticEngine

final class PackingEngineTests: XCTestCase {

    // MARK: - Boundary cases

    func testEmptyProjectHasZeroLength() throws {
        let project = Project(name: "Empty", rollWidthMetres: 4)
        let result = try PackingEngine.pack(project)
        XCTAssertEqual(result.totalLengthCM, 0)
        XCTAssertTrue(result.perRoom.isEmpty)
        XCTAssertTrue(result.placements.isEmpty)
    }

    func testProjectWithEmptyRoomHasZeroLength() throws {
        let project = Project(
            name: "P",
            rollWidthMetres: 4,
            rooms: [Room(name: "Lounge")]
        )
        let result = try PackingEngine.pack(project)
        XCTAssertEqual(result.totalLengthCM, 0)
        XCTAssertTrue(result.perRoom.isEmpty,
            "Rooms with no pieces should not appear in the breakdown.")
    }

    // MARK: - Single piece

    func testSinglePieceFullRollWidth() throws {
        let piece = Piece(widthCM: 400, lengthCM: 500)
        let project = Project(
            name: "P",
            rollWidthMetres: 4,
            rooms: [Room(name: "Lounge", pieces: [piece])]
        )
        let result = try PackingEngine.pack(project)
        XCTAssertEqual(result.totalLengthCM, 500)
        XCTAssertEqual(result.placements.count, 1)
        XCTAssertEqual(result.placements[0].xCM, 0)
        XCTAssertEqual(result.placements[0].yCM, 0)
    }

    func testSinglePieceNarrowerThanRollStillUsesFullShelfHeight() throws {
        // 1m wide piece on a 4m roll → shelf is 5m tall, only 1m of width used.
        // Total length consumed = 5m (FFD shelf packing wastes the unused width).
        let piece = Piece(widthCM: 100, lengthCM: 500)
        let project = Project(
            name: "P",
            rollWidthMetres: 4,
            rooms: [Room(name: "Hall", pieces: [piece])]
        )
        let result = try PackingEngine.pack(project)
        XCTAssertEqual(result.totalLengthCM, 500)
    }

    // MARK: - Side-by-side packing

    func testTwoPiecesShareShelfWhenWidthFits() throws {
        // 250 + 150 = 400 ≤ 400 roll width. Both same length → one shelf, total 300cm.
        let a = Piece(widthCM: 250, lengthCM: 300)
        let b = Piece(widthCM: 150, lengthCM: 300)
        let project = Project(
            name: "P",
            rollWidthMetres: 4,
            rooms: [Room(name: "Lounge", pieces: [a, b])]
        )
        let result = try PackingEngine.pack(project)
        XCTAssertEqual(result.totalLengthCM, 300)
        XCTAssertEqual(result.placements.count, 2)
        // Both placed at y=0 (same shelf), x positions sum to roll width usage.
        XCTAssertTrue(result.placements.allSatisfy { $0.yCM == 0 })
        let xs = result.placements.map(\.xCM).sorted()
        XCTAssertEqual(xs, [0, 250])
    }

    func testTwoPiecesShelfTakesLongestLength() throws {
        // a is 300 long, b is 200 long, both fit width-wise → shelf height = 300 (longest).
        // Total = 300, even though b is shorter.
        let a = Piece(widthCM: 200, lengthCM: 300)
        let b = Piece(widthCM: 200, lengthCM: 200)
        let project = Project(
            name: "P",
            rollWidthMetres: 4,
            rooms: [Room(name: "Lounge", pieces: [a, b])]
        )
        let result = try PackingEngine.pack(project)
        XCTAssertEqual(result.totalLengthCM, 300)
    }

    func testTwoPiecesStackOnSeparateShelvesWhenTooWide() throws {
        // Each is 300cm wide on a 400cm roll → 600 > 400, can't share.
        // Two shelves, each 200cm tall → total 400cm.
        let a = Piece(widthCM: 300, lengthCM: 200)
        let b = Piece(widthCM: 300, lengthCM: 200)
        let project = Project(
            name: "P",
            rollWidthMetres: 4,
            rooms: [Room(name: "Lounge", pieces: [a, b])]
        )
        let result = try PackingEngine.pack(project)
        XCTAssertEqual(result.totalLengthCM, 400)
        let ys = result.placements.map(\.yCM).sorted()
        XCTAssertEqual(ys, [0, 200])
    }

    // MARK: - Rotation

    func testRotatedPieceUsesSwappedDimensions() throws {
        // Piece is 200 wide × 500 long, rotated → effective 500 wide × 200 long.
        // 500 wide > 400 roll → would error... let's pick dims that don't overflow.
        // Piece is 100 wide × 300 long, rotated → effective 300 wide × 100 long.
        let rotated = Piece(widthCM: 100, lengthCM: 300, isRotated: true)
        let project = Project(
            name: "P",
            rollWidthMetres: 4,
            rooms: [Room(name: "R", pieces: [rotated])]
        )
        let result = try PackingEngine.pack(project)
        XCTAssertEqual(result.totalLengthCM, 100,
            "Rotated piece's effective length should be its original width.")
        XCTAssertEqual(result.placements[0].widthCM, 300)
        XCTAssertEqual(result.placements[0].lengthCM, 100)
    }

    func testRotationRotatesPileDirectionClockwise() throws {
        let rotated = Piece(
            widthCM: 100, lengthCM: 200,
            pileDirection: .up, isRotated: true
        )
        let project = Project(
            name: "P",
            rollWidthMetres: 4,
            rooms: [Room(name: "R", pieces: [rotated])]
        )
        let result = try PackingEngine.pack(project)
        XCTAssertEqual(result.placements[0].pileDirection, .right,
            "An up-pile piece rotated 90° clockwise should have a right-pile.")
    }

    func testPileRotationCycleIsConsistent() {
        XCTAssertEqual(PileDirection.up.rotated90Clockwise(), .right)
        XCTAssertEqual(PileDirection.right.rotated90Clockwise(), .down)
        XCTAssertEqual(PileDirection.down.rotated90Clockwise(), .left)
        XCTAssertEqual(PileDirection.left.rotated90Clockwise(), .up)
    }

    // MARK: - Cross-room nesting (the user's key requirement)

    func testPiecesFromDifferentRoomsShareAShelf() throws {
        // Lounge piece: 450 wide × 300 long.
        // Hall piece: 30 wide × 200 long.
        // 450 + 30 = 480 ≤ 500 roll width. Hall piece nests next to Lounge piece.
        // Single shelf 300 tall → total 300cm.
        let lounge = Room(name: "Lounge", pieces: [
            Piece(widthCM: 450, lengthCM: 300),
        ])
        let hall = Room(name: "Hall", pieces: [
            Piece(widthCM: 30, lengthCM: 200),
        ])
        let project = Project(
            name: "House",
            rollWidthMetres: 5,
            rooms: [lounge, hall]
        )
        let result = try PackingEngine.pack(project)
        XCTAssertEqual(result.totalLengthCM, 300,
            "Cross-room nesting: pieces from different rooms must share a shelf when they fit.")
        XCTAssertEqual(result.perRoom.count, 2)
    }

    func testUserScenarioSplitWideRoom() throws {
        // User's stated example: room is 5.3m × 4m on a 5m roll.
        // User splits into two pieces: 5m × 4m and 0.3m × 4m, both in one room.
        // Both pieces are 400cm long. 500 + 30 > 500 roll → can't share shelf.
        // Two shelves, each 400cm → total 800cm = 8m.
        // (No nesting available without other narrow pieces.)
        let lounge = Room(name: "Lounge", pieces: [
            Piece(widthCM: 500, lengthCM: 400),
            Piece(widthCM: 30,  lengthCM: 400),
        ])
        let project = Project(
            name: "House",
            rollWidthMetres: 5,
            rooms: [lounge]
        )
        let result = try PackingEngine.pack(project)
        XCTAssertEqual(result.totalLengthCM, 800)
    }

    func testUserScenarioWithNestableSecondRoom() throws {
        // Same as above plus a Hall with a 470 × 300 piece.
        // Lounge 5×4 piece takes shelf 1 (height 400, full width).
        // Lounge 0.3×4 piece needs its own shelf width-wise next to nothing... wait:
        //   After sorting by length desc: [500×400, 30×400, 470×300]
        //   Shelf 1 height 400. Place 500×400 (fills width). Try 30×400 — no width.
        //     Try 470×300 — fits height but no width left. → shelf 1 = 400.
        //   Shelf 2 height 400 (next longest unplaced is 30×400). Place 30×400.
        //     Try 470×300 — pieceLength 300 ≤ shelfHeight 400 ✓; widthUsed 30 + 470 = 500 ≤ 500 ✓.
        //     Place. → shelf 2 = 400.
        //   Total = 800cm. Hall piece nested next to the narrow strip.
        let lounge = Room(name: "Lounge", pieces: [
            Piece(widthCM: 500, lengthCM: 400),
            Piece(widthCM: 30,  lengthCM: 400),
        ])
        let hall = Room(name: "Hall", pieces: [
            Piece(widthCM: 470, lengthCM: 300),
        ])
        let project = Project(
            name: "House",
            rollWidthMetres: 5,
            rooms: [lounge, hall]
        )
        let result = try PackingEngine.pack(project)
        XCTAssertEqual(result.totalLengthCM, 800,
            "Hall's 470cm piece should nest next to Lounge's 30cm strip on shelf 2.")
        XCTAssertEqual(result.perRoom.count, 2)
    }

    // MARK: - Stairs

    func testStairsRoomKindPropagatedToBreakdown() throws {
        let stairs = Room(name: "Stairs", kind: .stairs, pieces: [
            Piece(widthCM: 70, lengthCM: 600),
        ])
        let project = Project(
            name: "House",
            rollWidthMetres: 4,
            rooms: [stairs]
        )
        let result = try PackingEngine.pack(project)
        XCTAssertEqual(result.perRoom.count, 1)
        XCTAssertEqual(result.perRoom[0].kind, .stairs)
    }

    // MARK: - Order preservation

    func testPerRoomBreakdownPreservesProjectRoomOrder() throws {
        let rooms = ["A", "B", "C"].map {
            Room(name: $0, pieces: [Piece(widthCM: 100, lengthCM: 200)])
        }
        let project = Project(name: "P", rollWidthMetres: 4, rooms: rooms)
        let result = try PackingEngine.pack(project)
        XCTAssertEqual(result.perRoom.map(\.roomName), ["A", "B", "C"])
    }

    // MARK: - Errors

    func testInvalidRollWidthThrows() {
        let project = Project(name: "P", rollWidthMetres: 6)
        XCTAssertThrowsError(try PackingEngine.pack(project)) { error in
            XCTAssertEqual(error as? PackingError, .invalidRollWidthMetres(6))
        }
    }

    func testZeroRollWidthThrows() {
        let project = Project(name: "P", rollWidthMetres: 0)
        XCTAssertThrowsError(try PackingEngine.pack(project)) { error in
            XCTAssertEqual(error as? PackingError, .invalidRollWidthMetres(0))
        }
    }

    func testPieceWiderThanRollThrows() {
        let oversize = Piece(widthCM: 500, lengthCM: 200)
        let project = Project(
            name: "P", rollWidthMetres: 4,
            rooms: [Room(name: "R", pieces: [oversize])]
        )
        XCTAssertThrowsError(try PackingEngine.pack(project)) { error in
            guard case .pieceWiderThanRoll(_, let w, let r) = (error as? PackingError) else {
                return XCTFail("Expected pieceWiderThanRoll, got \(error)")
            }
            XCTAssertEqual(w, 500)
            XCTAssertEqual(r, 400)
        }
    }

    func testRotatedPieceWiderThanRollThrows() {
        // 100 wide × 600 long, rotated → effective 600 wide → exceeds 4m roll.
        let rotated = Piece(widthCM: 100, lengthCM: 600, isRotated: true)
        let project = Project(
            name: "P", rollWidthMetres: 4,
            rooms: [Room(name: "R", pieces: [rotated])]
        )
        XCTAssertThrowsError(try PackingEngine.pack(project)) { error in
            guard case .pieceWiderThanRoll(_, let w, _) = (error as? PackingError) else {
                return XCTFail("Expected pieceWiderThanRoll for rotated piece, got \(error)")
            }
            XCTAssertEqual(w, 600,
                "Rotation must apply before width-validation.")
        }
    }

    func testZeroDimensionThrows() {
        let bad = Piece(widthCM: 0, lengthCM: 200)
        let project = Project(
            name: "P", rollWidthMetres: 4,
            rooms: [Room(name: "R", pieces: [bad])]
        )
        XCTAssertThrowsError(try PackingEngine.pack(project)) { error in
            guard case .nonPositiveDimension = (error as? PackingError) else {
                return XCTFail("Expected nonPositiveDimension, got \(error)")
            }
        }
    }

    // MARK: - Result conversion

    func testTotalLengthMetresConvertsFromCM() {
        let r = PackingResult(totalLengthCM: 875, perRoom: [], placements: [])
        XCTAssertEqual(r.totalLengthMetres, 8.75, accuracy: 0.0001)
    }
}
