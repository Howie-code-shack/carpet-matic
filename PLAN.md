# Implementation plan — carpet-matic

Architecture and approach. The actionable build checklist is in `TODO.md`. The "what we're building" is in `REQUIREMENTS.md`.

## Tech stack

- **App:** Single SwiftUI multiplatform target (iOS 17+, macOS 14+).
- **Persistence:** SwiftData (`@Model` classes).
- **Sync:** CloudKit private database, auto-synced via SwiftData's `ModelContainer(... cloudKitDatabase: .private(...))`.
- **PDF export:** SwiftUI's `ImageRenderer` for the page content, written to a PDF context via PDFKit.
- **Distribution:** Apple Developer Program ($99/yr) — required for CloudKit and future TestFlight.

## Project structure (proposed)

```
CarpetMatic/
├── CarpetMaticApp.swift          # @main, ModelContainer setup
├── Models/
│   ├── Project.swift
│   ├── Room.swift
│   ├── Piece.swift
│   └── Enums.swift               # RoomKind, PileDirection
├── Calc/
│   ├── PackingEngine.swift       # bin-pack pieces onto a roll
│   └── PackingResult.swift       # structs returned to the UI
├── UI/
│   ├── ProjectListView.swift
│   ├── ProjectDetailView.swift
│   ├── RoomDetailView.swift
│   ├── PieceEditorView.swift
│   ├── ResultView.swift
│   └── PileArrowView.swift       # small reusable arrow icon
├── Export/
│   └── PDFExporter.swift
└── Tests/
    └── PackingEngineTests.swift
```

## Data model

```swift
@Model
final class Project {
    var id: UUID
    var name: String
    var rollWidthMetres: Int       // one of 1, 2, 3, 4, 5
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var rooms: [Room]
}

@Model
final class Room {
    var id: UUID
    var name: String
    var kind: RoomKind             // .rectangle or .stairs
    var project: Project?
    @Relationship(deleteRule: .cascade) var pieces: [Piece]
}

@Model
final class Piece {
    var id: UUID
    var widthCM: Int               // store integer cm to avoid float drift
    var lengthCM: Int
    var pileDirection: PileDirection
    var isRotated: Bool            // user toggle; pile rotates with the piece
    var room: Room?
}

enum RoomKind: String, Codable { case rectangle, stairs }
enum PileDirection: String, Codable { case up, down, left, right }
```

Notes:
- Dimensions stored as integer centimetres internally; converted to/from metres at the UI boundary. Avoids float drift across CloudKit sync and PDF export.
- `isRotated` is a stored flag, not a computed view. The packing engine sees pieces in their post-rotation orientation (effective width = original length when rotated, etc.).
- `pileDirection` is a property of the cut piece. Rotating the piece rotates the arrow with it: e.g. a piece with `.up` pile rotated 90° clockwise has `.right` pile.

## Sync architecture

- One CloudKit container, private database.
- SwiftData → CloudKit auto-sync: enabled by passing `cloudKitDatabase: .private(...)` when constructing `ModelContainer`.
- Lightweight schema migrations via SwiftData. Push the schema to CloudKit dashboard's production environment before any non-development build.
- CloudKit limitations to respect: every model must be optional or have a default; relationships must be optional inverses. Already satisfied by the model above.

## Calculation engine

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

**Result struct:**

```swift
struct PackingResult {
    let totalMetres: Double
    let perRoom: [RoomBreakdown]
}

struct RoomBreakdown {
    let roomID: UUID
    let roomName: String
    let kind: RoomKind
    let pieces: [PiecePlacement]
}

struct PiecePlacement {
    let pieceID: UUID
    let widthMetres: Double
    let lengthMetres: Double
    let pileDirection: PileDirection   // post-rotation, for arrow display
    // future: position on the roll, for a graphical layout view
}
```

The engine internally tracks each placed piece's position on the roll, even though MVP doesn't render it. This means a future graphical layout view can be added without re-running the engine.

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
