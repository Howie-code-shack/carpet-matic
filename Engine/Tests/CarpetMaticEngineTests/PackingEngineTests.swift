import XCTest
@testable import CarpetMaticEngine

final class PackingEngineTests: XCTestCase {

    // MARK: - Boundary

    func testEmptyProjectHasZeroLength() throws {
        let project = Project(name: "Empty", rollWidthMetres: 4)
        let result = try PackingEngine.pack(project)
        XCTAssertEqual(result.totalLengthCM, 0)
        XCTAssertTrue(result.perRoom.isEmpty)
        XCTAssertTrue(result.placements.isEmpty)
    }

    func testInvalidRollWidthThrows() {
        let project = Project(name: "P", rollWidthMetres: 6)
        XCTAssertThrowsError(try PackingEngine.pack(project)) { error in
            XCTAssertEqual(error as? PackingError, .invalidRollWidthMetres(6))
        }
    }

    func testZeroDimensionRoomThrows() {
        let room = Room(name: "Bad", widthCM: 0, lengthCM: 200)
        let project = Project(name: "P", rollWidthMetres: 4, rooms: [room])
        XCTAssertThrowsError(try PackingEngine.pack(project)) { error in
            guard case .invalidRoomDimensions = (error as? PackingError) else {
                return XCTFail("Expected invalidRoomDimensions, got \(error)")
            }
        }
    }

    // MARK: - Single room — fits in one strip

    func testSingleRoomNarrowerThanRollFitsOneStrip() throws {
        // 3m wide × 5m long room on a 4m roll, pile up (strips along Length).
        // 1 strip of 3m × 5m. Total = 5m roll consumed.
        let room = Room(name: "Lounge", widthCM: 300, lengthCM: 500, pileDirection: .up)
        let project = Project(name: "P", rollWidthMetres: 4, rooms: [room])
        let result = try PackingEngine.pack(project)
        XCTAssertEqual(result.totalLengthCM, 500)
        XCTAssertEqual(result.placements.count, 1)
        XCTAssertEqual(result.placements[0].widthCM, 300)
        XCTAssertEqual(result.placements[0].lengthCM, 500)
    }

    func testSingleRoomExactlyRollWidth() throws {
        let room = Room(name: "R", widthCM: 400, lengthCM: 600, pileDirection: .up)
        let project = Project(name: "P", rollWidthMetres: 4, rooms: [room])
        let result = try PackingEngine.pack(project)
        XCTAssertEqual(result.totalLengthCM, 600)
        XCTAssertEqual(result.placements.count, 1)
    }

    // MARK: - Single room — multiple strips

    func testRoomWiderThanRollSplitsAutomatically() throws {
        // 5m wide × 4m long room on a 4m roll, pile up.
        // Strips along Length: needs 2 strips (4m + 1m), each 4m long.
        // Can't share shelf (4 + 1 > 4), so 2 shelves × 4m = 8m.
        let room = Room(name: "Big", widthCM: 500, lengthCM: 400, pileDirection: .up)
        let project = Project(name: "P", rollWidthMetres: 4, rooms: [room])
        let result = try PackingEngine.pack(project)
        XCTAssertEqual(result.placements.count, 2)
        XCTAssertEqual(result.totalLengthCM, 800)
        let widths = result.placements.map(\.widthCM).sorted()
        XCTAssertEqual(widths, [100, 400])
    }

    func testThreeStripsForVeryWideRoom() throws {
        // 10m wide × 3m long room on a 4m roll, pile up.
        // Strips along Length: 3 strips (4m + 4m + 2m), each 3m long.
        // Can't pair (4+4>4, 4+2>4) → 3 shelves of 3m = 9m total.
        let room = Room(name: "X", widthCM: 1000, lengthCM: 300, pileDirection: .up)
        let project = Project(name: "P", rollWidthMetres: 4, rooms: [room])
        let result = try PackingEngine.pack(project)
        XCTAssertEqual(result.placements.count, 3)
        XCTAssertEqual(result.totalLengthCM, 900)
    }

    // MARK: - Pile direction selects strip axis

    func testPileUpStripsAlongLength() throws {
        let room = Room(name: "R", widthCM: 200, lengthCM: 500, pileDirection: .up)
        let project = Project(name: "P", rollWidthMetres: 4, rooms: [room])
        let result = try PackingEngine.pack(project)
        // 1 strip of 2m × 5m → 5m consumed.
        XCTAssertEqual(result.totalLengthCM, 500)
        XCTAssertEqual(result.placements[0].widthCM, 200)
        XCTAssertEqual(result.placements[0].lengthCM, 500)
    }

    func testPileRightStripsAlongWidth() throws {
        // Room 2m wide × 5m long with pile right → strips run along the Width axis.
        // perpDim = 5m → ⌈500/400⌉ = 2 strips (400×200 + 100×200).
        // Strips can't share a shelf (400 + 100 > 400 roll width) → 2 shelves of 200 = 400.
        let room = Room(name: "R", widthCM: 200, lengthCM: 500, pileDirection: .right)
        let project = Project(name: "P", rollWidthMetres: 4, rooms: [room])
        let result = try PackingEngine.pack(project)
        XCTAssertEqual(result.placements.count, 2)
        XCTAssertEqual(result.totalLengthCM, 400)
        XCTAssertTrue(result.placements.allSatisfy { $0.lengthCM == 200 })
        XCTAssertEqual(result.placements.map(\.widthCM).sorted(), [100, 400])
    }

    func testPileDirectionPropagatedToStrips() throws {
        let room = Room(name: "R", widthCM: 100, lengthCM: 300, pileDirection: .left)
        let project = Project(name: "P", rollWidthMetres: 4, rooms: [room])
        let result = try PackingEngine.pack(project)
        XCTAssertTrue(result.placements.allSatisfy { $0.pileDirection == .left })
    }

    // MARK: - Optimal pile direction helper

    func testOptimalPileDirectionPicksMinMetres() {
        // 5 × 4 on R=4: along-length = 8, along-width = 5 → .right.
        XCTAssertEqual(
            Room.optimalPileDirection(widthCM: 500, lengthCM: 400, rollWidthCM: 400),
            .right
        )
        // 3 × 5 on R=4: along-length = 5, along-width = 6 → .up.
        XCTAssertEqual(
            Room.optimalPileDirection(widthCM: 300, lengthCM: 500, rollWidthCM: 400),
            .up
        )
        // Tie → .up (default).
        XCTAssertEqual(
            Room.optimalPileDirection(widthCM: 400, lengthCM: 400, rollWidthCM: 400),
            .up
        )
    }

    // MARK: - Cross-room nesting (the user's key requirement)

    func testNarrowStripsFromDifferentRoomsShareShelf() throws {
        // Two rooms whose strips can fit alongside each other:
        //   Lounge: 4.50m wide × 3m long. Pile up → 2 strips: 4m × 3m + 0.5m × 3m.
        //   Hall: 3m wide × 3m long. Pile up → 1 strip: 3m × 3m.
        // After sort by length desc (all 300):
        //   Shelf 1, height 300:
        //     Place 4×3 (lounge full strip) → width used 400. No room for hall (3m) or lounge narrow (0.5m).
        //   Shelf 2, height 300:
        //     Place hall 3×3 → width used 300. Try lounge narrow 0.5×3 → 300+50 = 350 ≤ 400 ✓. Place.
        //   Total = 600.
        let lounge = Room(name: "Lounge", widthCM: 450, lengthCM: 300, pileDirection: .up)
        let hall = Room(name: "Hall", widthCM: 300, lengthCM: 300, pileDirection: .up)
        let project = Project(name: "House", rollWidthMetres: 4, rooms: [lounge, hall])
        let result = try PackingEngine.pack(project)
        XCTAssertEqual(result.totalLengthCM, 600,
            "The 0.5m lounge strip must nest next to the 3m hall strip on shelf 2.")
        XCTAssertEqual(result.perRoom.count, 2)
    }

    // MARK: - User scenario

    func testUserScenarioSingleRoomFiveThreeWide() throws {
        // User's original example: 5.3m × 4m room on a 5m roll.
        // Pile up → 2 strips: 5m × 4m + 0.3m × 4m. Both 4m long, can't share (5 + 0.3 > 5).
        // Total = 8m.
        let room = Room(name: "Lounge", widthCM: 530, lengthCM: 400, pileDirection: .up)
        let project = Project(name: "House", rollWidthMetres: 5, rooms: [room])
        let result = try PackingEngine.pack(project)
        XCTAssertEqual(result.placements.count, 2)
        XCTAssertEqual(result.totalLengthCM, 800)
    }

    func testUserScenarioWithSecondRoomNestingTheNarrowStrip() throws {
        // 5.3m × 4m lounge + 4.7m × 3m hall, all on 5m roll.
        // Lounge pile up → 2 strips: 500×400 + 30×400.
        // Hall pile up → 1 strip: 470×300.
        // After sort (lengths 400, 400, 300):
        //   Shelf 1, h=400: place 500×400 (lounge), no room for 30×400 (500+30>500),
        //     no room for 470×300 (500+470>500).
        //   Shelf 2, h=400: place 30×400 (lounge), try 470×300 → length 300≤400 ✓,
        //     width 30+470=500 ≤500 ✓. Place. Done.
        //   Total = 800.
        let lounge = Room(name: "Lounge", widthCM: 530, lengthCM: 400, pileDirection: .up)
        let hall = Room(name: "Hall", widthCM: 470, lengthCM: 300, pileDirection: .up)
        let project = Project(name: "House", rollWidthMetres: 5, rooms: [lounge, hall])
        let result = try PackingEngine.pack(project)
        XCTAssertEqual(result.totalLengthCM, 800,
            "Hall's 4.7m strip must nest next to the 0.3m lounge strip on shelf 2.")
    }

    // MARK: - Stairs

    func testStairsKindPropagatedToBreakdown() throws {
        let stairs = Room(name: "Stairs", widthCM: 70, lengthCM: 600,
                          kind: .stairs, pileDirection: .up)
        let project = Project(name: "House", rollWidthMetres: 4, rooms: [stairs])
        let result = try PackingEngine.pack(project)
        XCTAssertEqual(result.perRoom.count, 1)
        XCTAssertEqual(result.perRoom[0].kind, .stairs)
        XCTAssertEqual(result.perRoom[0].roomName, "Stairs")
    }

    // MARK: - Order

    func testPerRoomBreakdownPreservesProjectOrder() throws {
        let rooms = ["A", "B", "C"].map {
            Room(name: $0, widthCM: 100, lengthCM: 200, pileDirection: .up)
        }
        let project = Project(name: "P", rollWidthMetres: 4, rooms: rooms)
        let result = try PackingEngine.pack(project)
        XCTAssertEqual(result.perRoom.map(\.roomName), ["A", "B", "C"])
    }

    // MARK: - Internal strip-generation tests

    func testStripsForRoomNarrowerThanRollProducesOne() {
        let room = Room(name: "R", widthCM: 250, lengthCM: 500, pileDirection: .up)
        let strips = PackingEngine.strips(for: room, rollWidthCM: 400)
        XCTAssertEqual(strips.count, 1)
        XCTAssertEqual(strips[0].widthCM, 250)
        XCTAssertEqual(strips[0].lengthCM, 500)
    }

    func testStripsForOversizeRoomProducesFullPlusRemainder() {
        let room = Room(name: "R", widthCM: 530, lengthCM: 400, pileDirection: .up)
        let strips = PackingEngine.strips(for: room, rollWidthCM: 500)
        XCTAssertEqual(strips.count, 2)
        XCTAssertEqual(strips.map(\.widthCM).sorted(), [30, 500])
        XCTAssertTrue(strips.allSatisfy { $0.lengthCM == 400 })
    }

    func testStripsForRoomWithLeftPileGenerateAlongWidth() {
        // Pile left → strips along Width axis. Room width becomes the strip length.
        let room = Room(name: "R", widthCM: 600, lengthCM: 200, pileDirection: .left)
        let strips = PackingEngine.strips(for: room, rollWidthCM: 400)
        // perpDimension = lengthCM = 200; stripLength = widthCM = 600
        // Ceil(200/400) = 1 strip of 200 × 600.
        XCTAssertEqual(strips.count, 1)
        XCTAssertEqual(strips[0].widthCM, 200)
        XCTAssertEqual(strips[0].lengthCM, 600)
    }

    // MARK: - Result conversion

    func testTotalLengthMetresConvertsFromCM() {
        let r = PackingResult(totalLengthCM: 875, perRoom: [], placements: [])
        XCTAssertEqual(r.totalLengthMetres, 8.75, accuracy: 0.0001)
    }

    // MARK: - Pile rotation utility (kept from earlier)

    func testPileRotationCycleIsConsistent() {
        XCTAssertEqual(PileDirection.up.rotated90Clockwise(), .right)
        XCTAssertEqual(PileDirection.right.rotated90Clockwise(), .down)
        XCTAssertEqual(PileDirection.down.rotated90Clockwise(), .left)
        XCTAssertEqual(PileDirection.left.rotated90Clockwise(), .up)
    }
}
