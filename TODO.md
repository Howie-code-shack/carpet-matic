# TODO — carpet-matic

Phased build checklist. See `REQUIREMENTS.md` for what we're building and `PLAN.md` for the architecture.

## Done

The engine + Xcode app skeleton are in place; the input model is **room dimensions in, strips out**.

- [x] `Engine/` Swift Package (`CarpetMaticEngine`).
- [x] Domain value types: `Project`, `Room` (with widthCM/lengthCM/pileDirection), `RoomKind`, `PileDirection`. `Piece` exists internally as the rectangle the packer consumes.
- [x] `PackingEngine`: strip generation per room + First-Fit-Decreasing shelf packer.
- [x] `Room.optimalPileDirection(...)` helper used by the UI to suggest a sensible default.
- [x] Result types: `PackingResult`, `RoomBreakdown` (with `strips`), `StripPlacement`, `PackingError`.
- [x] Unit tests (21 cases): empty project, single rooms (narrow / exact / oversize / very-wide), pile axis selection, cross-room nesting, the 5.3 m user scenario, stairs propagation, room-order preservation, optimal-pile-direction helper, errors.
- [x] Xcode iOS app project linked to the Engine package; SwiftData `@Model` classes (`ProjectModel`, `RoomModel`); local-only persistence.
- [x] SwiftUI screens: `ProjectListView`, `ProjectDetailView`, `RoomDetailView` (single form: name + dimensions + pile), `ResultView` with strip breakdown, `PileArrowView`, `PDFExporter`.
- [x] Release-blocker fixes (2026-07-19): PDF export paginates across A4 pages (was single-page, silently truncating); export failures surfaced via alert; `PackingEngine.stripRects` is the single public source of the strip-split rule (UI previews consume it instead of re-deriving); placement-geometry engine tests (no overlaps, strips within roll); `RoomDetailView` reseeds its dimension fields if the bound room changes.

## Phase 0 — Foundation

Goal: a buildable, signed, syncing skeleton on both devices.

- [ ] Enrol in the Apple Developer Program ($99/yr).
- [ ] Create the Xcode project: SwiftUI multiplatform App template; iOS 17+ / macOS 14+ deployment targets.
- [ ] Set bundle identifier; configure signing for iOS and Mac destinations.
- [ ] Create a CloudKit container in the Apple Developer portal.
- [ ] Add the iCloud entitlement; enable CloudKit; select the container.
- [x] Add SwiftData `@Model` types: `ProjectModel`, `RoomModel`; enums `RoomKind`, `PileDirection`.
- [ ] Configure `ModelContainer` with `.private(.automatic)` CloudKit database in `CarpetMaticApp.swift`.
- [ ] Verify the schema deploys to the CloudKit dashboard (development environment).
- [ ] Stub a placeholder `NavigationStack` (iPhone) / `NavigationSplitView` (Mac) skeleton.
- [ ] Smoke-test: build and run on the user's iPhone (USB) and Mac.

## Phase 1 — MVP

Goal: every functional requirement in `REQUIREMENTS.md` works end-to-end.

### CRUD

- [ ] `ProjectListView`: list, create, rename, delete projects; navigate into detail.
- [ ] `ProjectDetailView`: edit name; roll-width picker (1/2/3/4/5 m); list of rooms; "Calculate" / Result navigation.
- [x] `RoomDetailView`: edit name, kind, width × length (1 cm precision), pile direction; live strip-count footer with optimal-axis hint.
- [ ] Input validation: oversize-width error message, blank name handling, sensible defaults.

### Calc engine

(Built early in `Engine/` — see "Done early" section above. Phase 1 just needs to wire it in.)

- [ ] Add `Engine/` as a local Swift Package dependency in the Xcode app.
- [x] Write the `Adapters/` layer: convert `@Model` classes (`ProjectModel`, `RoomModel`) to engine `Project` / `Room` value types.
- [x] Wire the result view to call `PackingEngine.pack(_:)` on the converted project.

### Output

- [x] `PileArrowView`: small reusable arrow icon, takes a `PileDirection`.
- [x] `ResultView`: total linear metres at the top; per-room breakdown with each strip's dimensions and pile arrow.
- [x] Result recomputes automatically on data change (`ResultView` recalculates via a fingerprint of roll width + room data).
- [x] `PDFExporter`: render the result to PDF (one room per section, strips listed with pile direction).
- [x] `fileExporter` integration for share/save.

### Sync verification

- [ ] Create a project on iPhone; confirm it appears on Mac within a minute.
- [ ] Edit on Mac; confirm changes flow back to iPhone.
- [ ] Test offline behaviour: airplane-mode iPhone, edit, reconnect, sync resolves.

### Manual QA

- [ ] Run through a real-world job (multiple rooms, mix of rectangles and a stairs section, the 5.3 m wide example) on both devices.

## Phase 2 — Polish

- [ ] Receive the rotate-button reference screenshot from the user; match the visual design.
- [ ] Empty/edge-case states: empty project, empty room, single-piece project, oversize piece warning, near-zero dimensions.
- [ ] Accessibility: VoiceOver labels on every interactive element; Dynamic Type support; keyboard navigation on Mac.
- [x] App icon (carpet-roll motif; light/dark/tinted 1024px variants in `AppIcon.appiconset`). Launch screen still the auto-generated blank one.
- [x] Delete confirmations for projects and rooms (confirmation dialog before cascade delete).
- [ ] Per-piece rotation undo.

## Future backlog (not MVP)

See `REQUIREMENTS.md` § Future backlog. Notable items:

- L-shaped and other non-rectangular rooms.
- Configurable waste % field at the project level.
- Software-managed joins / mid-strip seams.
- Full graphical layout view of pieces on the roll (engine already stores positions).
- Per-roll-length output view alongside per-room.
- Cost estimation (price per linear metre × total).
- RTF / DOCX / Pages export.
- TestFlight distribution for sharing with others.
- Smarter packing (skyline or guillotine) when waste matters.
- Real stair calculator (steps × tread × riser → unrolled length).
