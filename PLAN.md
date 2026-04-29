# Implementation plan — carpet-matic

Architecture and approach. The actionable build checklist is in `TODO.md`. The "what we're building" is in `REQUIREMENTS.md`.

## Tech stack

- **App:** Single SwiftUI multiplatform target (iOS 17+, macOS 14+).
- **Persistence:** SwiftData (`@Model` classes).
- **Sync:** CloudKit private database, auto-synced via SwiftData's `ModelContainer(... cloudKitDatabase: .private(...))`.
- **PDF export:** SwiftUI's `ImageRenderer` for the page content, written to a PDF context via PDFKit.
- **Distribution:** Apple Developer Program ($99/yr) — required for CloudKit and future TestFlight.

## Project structure

```
carpet-matic/
├── Engine/                          # Swift Package (built first; runs with `swift test`)
│   ├── Package.swift
│   ├── Sources/CarpetMaticEngine/
│   │   ├── Models.swift             # Project, Room, Piece, RoomKind, PileDirection (value types)
│   │   ├── PackingEngine.swift      # FFD shelf packer
│   │   └── PackingResult.swift      # PackingResult, RoomBreakdown, PiecePlacement, PackingError
│   └── Tests/CarpetMaticEngineTests/
│       └── PackingEngineTests.swift
└── CarpetMatic/                     # (Phase 1) Xcode app, depends on Engine/ as a local package
    ├── CarpetMaticApp.swift         # @main, ModelContainer setup
    ├── Models/                      # SwiftData @Model classes (Project/Room/Piece)
    ├── Adapters/                    # Convert @Model classes → Engine value types
    ├── UI/
    │   ├── ProjectListView.swift
    │   ├── ProjectDetailView.swift
    │   ├── RoomDetailView.swift
    │   ├── PieceEditorView.swift
    │   ├── ResultView.swift
    │   └── PileArrowView.swift
    └── Export/
        └── PDFExporter.swift
```

**Why split into a Swift Package?** The engine has no UI / SwiftData / CloudKit dependencies — it's pure logic. Keeping it in a separate package lets us test it in isolation with `swift test` (no Xcode app build, no simulator), which is a much faster feedback loop. The Xcode app will add the package as a local dependency in Phase 1.

## Data model

There are **two parallel models** with the same field names but different roles:

1. **Engine value types** (in `Engine/Sources/CarpetMaticEngine/Models.swift`) — plain Swift `struct`s. Already implemented. The packer consumes these.
2. **App `@Model` classes** (Phase 1 — not yet written) — SwiftData persistence types stored in CloudKit. The app converts `@Model` instances to engine `struct`s via an adapter before calling `PackingEngine.pack(_:)`.

The engine value types are:

```swift
public struct Project { id, name, rollWidthMetres, rooms }
public struct Room    { id, name, kind, pieces }
public struct Piece   { id, widthCM, lengthCM, pileDirection, isRotated }
public enum RoomKind  { case rectangle, stairs }
public enum PileDirection { case up, down, left, right }
```

The Phase 1 `@Model` classes will mirror this shape:

```swift
@Model
final class ProjectModel {
    var id: UUID
    var name: String
    var rollWidthMetres: Int       // one of 1, 2, 3, 4, 5
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var rooms: [RoomModel]
}

@Model
final class RoomModel {
    var id: UUID
    var name: String
    var kind: RoomKind             // shared enum from the engine package
    var project: ProjectModel?
    @Relationship(deleteRule: .cascade) var pieces: [PieceModel]
}

@Model
final class PieceModel {
    var id: UUID
    var widthCM: Int
    var lengthCM: Int
    var pileDirection: PileDirection
    var isRotated: Bool
    var room: RoomModel?
}
```

Notes:
- Dimensions stored as integer centimetres internally; converted to/from metres at the UI boundary. Avoids float drift across CloudKit sync and PDF export.
- `isRotated` is a stored flag, not a computed view. The packing engine sees pieces in their post-rotation orientation (`effectiveWidthCM` / `effectiveLengthCM` / `effectivePileDirection` swap on `isRotated`).
- `pileDirection` is a property of the cut piece. Rotating the piece rotates the arrow with it: e.g. a piece with `.up` pile rotated 90° clockwise has `.right` pile.
- Why two parallel models? The engine must be testable from `swift test` without SwiftData / CoreData / iOS framework deps. The `@Model` classes only exist inside the app target.

## Sync architecture

- One CloudKit container, private database.
- SwiftData → CloudKit auto-sync: enabled by passing `cloudKitDatabase: .private(...)` when constructing `ModelContainer`.
- Lightweight schema migrations via SwiftData. Push the schema to CloudKit dashboard's production environment before any non-development build.
- CloudKit limitations to respect: every model must be optional or have a default; relationships must be optional inverses. Already satisfied by the model above.

## Calculation engine

✅ **Implemented in `Engine/Sources/CarpetMaticEngine/PackingEngine.swift`** (2026-04-29). 21 unit tests passing. Run with `cd Engine && swift test`.

The engine packs all pieces from all rooms in a project onto a fixed-width roll, minimising total length.

**Algorithm: First-Fit-Decreasing shelf packing.**

1. Collect all pieces from all rooms in the project, applying each piece's `isRotated` flag to compute its effective `(width, length)`.
2. Reject any piece whose effective width > roll width (surface as an input validation error before reaching the engine).
3. Sort the pieces by effective length, descending.
4. Walk along the roll in **shelves**. A shelf is a band of roll length whose height equals the longest unplaced piece's length.
5. For each shelf, place pieces left-to-right that fit: their effective length ≤ shelf height AND the running width sum ≤ roll width.
6. When no more pieces fit in the current shelf, start a new shelf above. Repeat until all pieces are placed.
7. Total roll length consumed = sum of shelf heights.

**Properties:**
- Deterministic and fast (O(n log n)).
- Not optimal — there exist nests with less waste — but matches the user's stated tolerance ("good enough, I'll review").
- Easy to swap for a smarter packer (e.g. skyline / guillotine) later without changing the result struct.

**Result struct (as implemented):**

```swift
public struct PackingResult {
    public let totalLengthCM: Int            // integer cm, no float drift
    public let perRoom: [RoomBreakdown]
    public let placements: [PiecePlacement]  // flat list, includes positions
    public var totalLengthMetres: Double { ... }
}

public struct RoomBreakdown {
    public let roomID: UUID
    public let roomName: String
    public let kind: RoomKind
    public let pieces: [PiecePlacement]
}

public struct PiecePlacement {
    public let pieceID: UUID
    public let roomID: UUID
    public let widthCM: Int          // post-rotation
    public let lengthCM: Int         // post-rotation
    public let pileDirection: PileDirection   // post-rotation, for arrow display
    public let xCM: Int              // position on roll (left edge → right)
    public let yCM: Int              // position on roll (start → along the length)
}
```

The engine tracks each placed piece's position (`xCM`, `yCM`) on the roll, even though the MVP UI only renders the per-room breakdown. This means a future graphical layout view can consume `placements` without re-running the engine.

## UI architecture

Screen flow:

1. **ProjectListView** (root) — list of projects, "New project" button.
2. **ProjectDetailView** — project name (editable), roll-width picker, list of rooms, "Calculate" button.
3. **RoomDetailView** — room name, kind picker (Rectangle / Stairs), list of pieces.
4. **PieceEditorView** — width, length, pile-direction picker, rotate button.
5. **ResultView** — total linear metres at the top; per-room breakdown below; "Export PDF" button.

The same SwiftUI views run on iPhone (`NavigationStack`) and Mac (`NavigationSplitView`). SwiftUI's adaptive containers handle the layout per platform; no Catalyst, no separate Mac UI code.

## PDF export

- Build the PDF with PDFKit's `PDFDocument`, one section per room.
- Use SwiftUI's `ImageRenderer` to render the result content to a CGImage / PDF page where it's faster than imperative drawing.
- Save via `fileExporter`, which gives the user a save panel on Mac and a share sheet on iPhone.

## Phasing strategy

- **Phase 0 — Foundation.** Apple Developer enrolment; Xcode project; CloudKit container & entitlement; SwiftData schema; empty navigation skeleton; verified build/run on both devices.
- **Phase 1 — MVP.** Project/room/piece CRUD; calc engine v1 with unit tests; result view with pile arrows; PDF export; CloudKit sync verified end-to-end.
- **Phase 2 — Polish.** Rotate-button visual matched to user's reference screenshot; edge cases (empty rooms, oversize pieces, sync conflicts); accessibility; app icon.
- **Future.** See `REQUIREMENTS.md` § Future backlog.
