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
│   │   ├── Models.swift             # Project, Room, Piece (engine-internal), RoomKind, PileDirection
│   │   ├── PackingEngine.swift      # Strip generation + FFD shelf packer
│   │   └── PackingResult.swift      # PackingResult, RoomBreakdown, StripPlacement, PackingError
│   └── Tests/CarpetMaticEngineTests/
│       └── PackingEngineTests.swift
└── CarpetMatic/                     # (Phase 1) Xcode app, depends on Engine/ as a local package
    ├── CarpetMaticApp.swift         # @main, ModelContainer setup
    ├── Models/                      # SwiftData @Model classes (ProjectModel, RoomModel)
    ├── Adapters/                    # Convert @Model classes → Engine value types
    ├── UI/
    │   ├── ProjectListView.swift
    │   ├── ProjectDetailView.swift
    │   ├── RoomDetailView.swift     # name + dimensions + pile direction
    │   ├── ResultView.swift
    │   └── PileArrowView.swift
    └── Export/
        └── PDFExporter.swift
```

**Why split into a Swift Package?** The engine has no UI / SwiftData / CloudKit dependencies — it's pure logic. Keeping it in a separate package lets us test it in isolation with `swift test` (no Xcode app build, no simulator), which is a much faster feedback loop. The Xcode app will add the package as a local dependency in Phase 1.

## Data model

There are **two parallel models** with the same field names but different roles:

1. **Engine value types** (in `Engine/Sources/CarpetMaticEngine/Models.swift`) — plain Swift `struct`s. The packer consumes these.
2. **App `@Model` classes** — SwiftData persistence types stored locally (and in CloudKit once enabled). The app converts `@Model` instances to engine `struct`s via the `Adapters/` layer before calling `PackingEngine.pack(_:)`.

**Important:** the user inputs **room dimensions**, not pieces. The engine generates strips internally. There is no user-facing "piece" or "strip" data type to edit.

The engine value types:

```swift
public struct Project { id, name, rollWidthMetres, rooms }
public struct Room    { id, name, widthCM, lengthCM, kind, pileDirection }
public enum  RoomKind { case rectangle, stairs }
public enum  PileDirection { case up, down, left, right }
// Internal/output:
public struct Piece           { id, widthCM, lengthCM, pileDirection }   // a strip
public struct StripPlacement  { id, roomID, widthCM, lengthCM, pileDirection, xCM, yCM }
public struct RoomBreakdown   { roomID, roomName, kind, strips: [StripPlacement] }
public struct PackingResult   { totalLengthCM, perRoom, placements }
```

The app's `@Model` classes mirror the user-facing shape (no `Piece`):

```swift
@Model
final class ProjectModel {
    var id: UUID
    var name: String
    var rollWidthMetres: Int       // one of 1, 2, 3, 4, 5
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \RoomModel.project)
    var rooms: [RoomModel]?
}

@Model
final class RoomModel {
    var id: UUID
    var name: String
    var widthCM: Int
    var lengthCM: Int
    var kindRaw: String            // RoomKind raw value
    var pileDirectionRaw: String   // PileDirection raw value
    var project: ProjectModel?
}
```

Notes:
- Dimensions stored as integer centimetres internally; converted to/from metres at the UI boundary. Avoids float drift across CloudKit sync and PDF export.
- Pile direction maps to strip axis: `.up` / `.down` → strips along Length, `.left` / `.right` → strips along Width.
- Rooms wider than the roll are split into strips automatically by the engine.
- `Piece` exists in the engine purely as the rectangle the FFD packer consumes — never persisted, never user-facing.
- Why two parallel models? The engine must be testable from `swift test` without SwiftData / CloudKit / iOS framework deps.

## Sync architecture

- One CloudKit container, private database.
- SwiftData → CloudKit auto-sync: enabled by passing `cloudKitDatabase: .private(...)` when constructing `ModelContainer`.
- Lightweight schema migrations via SwiftData. Push the schema to CloudKit dashboard's production environment before any non-development build.
- CloudKit limitations to respect: every model must be optional or have a default; relationships must be optional inverses. Already satisfied by the model above.

## Calculation engine

✅ **Implemented in `Engine/Sources/CarpetMaticEngine/PackingEngine.swift`**. 21 unit tests passing. Run with `cd Engine && swift test`.

The engine takes a `Project` (rooms with dimensions, no pieces), generates strips internally, and packs them onto a fixed-width roll, minimising total length.

**Algorithm:**

1. **Strip generation per room.** Pile direction picks the strip axis: `.up` / `.down` → strips along Length, `.left` / `.right` → strips along Width. The room's "perpendicular" dimension is split into strips of width ≤ roll width: first n−1 strips are roll-width wide, the last is the remainder.
2. **Validation.** Roll width ∈ {1,2,3,4,5} m; rooms must have positive dimensions.
3. **First-Fit-Decreasing shelf packing.** Sort all strips by length descending; open shelves whose height = the longest unplaced strip; fill left-to-right with anything that fits (length ≤ shelf height AND remaining width sufficient). Total roll length = sum of shelf heights.

**Properties:**
- Deterministic, O(n log n).
- Not optimal — there exist nests with less waste — but matches the user's stated tolerance ("good enough, I'll review").
- Easy to swap for a smarter packer (e.g. skyline / guillotine) later without changing the result struct.

**Optimal pile direction helper.** `Room.optimalPileDirection(widthCM:lengthCM:rollWidthCM:)` returns the pile direction that minimises *per-room* linear metres (ignoring cross-room nesting). The app uses it to set a sensible default when the user creates a room.

**Result struct (as implemented):**

```swift
public struct PackingResult {
    public let totalLengthCM: Int                  // integer cm, no float drift
    public let perRoom: [RoomBreakdown]
    public let placements: [StripPlacement]
    public var totalLengthMetres: Double { ... }
}

public struct RoomBreakdown {
    public let roomID: UUID
    public let roomName: String
    public let kind: RoomKind
    public let strips: [StripPlacement]            // strips placed for this room
}

public struct StripPlacement {
    public let id: UUID
    public let roomID: UUID
    public let widthCM: Int
    public let lengthCM: Int
    public let pileDirection: PileDirection
    public let xCM: Int                            // left edge → right on the roll
    public let yCM: Int                            // start → along the roll length
}
```

The engine tracks each strip's `(xCM, yCM)` position on the roll even though the MVP UI only renders the per-room breakdown. A future graphical layout view can consume `placements` without re-running the engine.

## UI architecture

Screen flow:

1. **ProjectListView** (root) — list of projects, "New project" button.
2. **ProjectDetailView** — project name (editable), roll-width picker, list of rooms, "Calculate" button.
3. **RoomDetailView** — room name, kind picker (Rectangle / Stairs), width / length inputs, pile-direction picker, footer showing strip count + a tip if the user has chosen a suboptimal pile axis.
4. **ResultView** — total linear metres at the top; per-room breakdown showing each strip's dimensions and pile arrow; "Export PDF" button.

There is **no Piece editor** screen — the engine generates strips from room dimensions automatically. If a future request asks for one, it's almost certainly the wrong abstraction unless the user explicitly says so.

The same SwiftUI views run on iPhone (`NavigationStack`) and Mac (`NavigationSplitView`). SwiftUI's adaptive containers handle the layout per platform; no Catalyst, no separate Mac UI code.

## PDF export

- Build the PDF with PDFKit's `PDFDocument`, one section per room.
- Use SwiftUI's `ImageRenderer` to render the result content to a CGImage / PDF page where it's faster than imperative drawing.
- Save via `fileExporter`, which gives the user a save panel on Mac and a share sheet on iPhone.

## Phasing strategy

- **Phase 0 — Foundation.** Apple Developer enrolment; Xcode project; CloudKit container & entitlement; SwiftData schema; empty navigation skeleton; verified build/run on both devices.
- **Phase 1 — MVP.** Project/room CRUD with dimensions in; calc engine generates strips; result view with pile arrows; PDF export; CloudKit sync verified end-to-end.
- **Phase 2 — Polish.** Pile-direction picker visual matched to user's reference screenshot; edge cases (empty rooms, oversize rooms, sync conflicts); accessibility; app icon.
- **Future.** See `REQUIREMENTS.md` § Future backlog.
