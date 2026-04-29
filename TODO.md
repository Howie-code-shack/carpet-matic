# TODO — carpet-matic

Phased build checklist. See `REQUIREMENTS.md` for what we're building and `PLAN.md` for the architecture.

## Done early (out-of-phase)

The calc engine was built first as a standalone Swift Package because it needs no Apple Developer account and is the most novel piece — getting it right early de-risks the rest.

- [x] `Engine/` Swift Package created (`CarpetMaticEngine`).
- [x] Domain value types: `Project`, `Room`, `Piece`, `RoomKind`, `PileDirection`.
- [x] `PackingEngine`: First-Fit-Decreasing shelf packer.
- [x] Result types: `PackingResult`, `RoomBreakdown`, `PiecePlacement`, `PackingError`.
- [x] Unit tests (21 cases): empty project, single piece, side-by-side, separate shelves, rotation (dimensions + pile), cross-room nesting, the 5.3 m user scenario, stairs propagation, room-order preservation, oversize/zero/invalid errors.

## Phase 0 — Foundation

Goal: a buildable, signed, syncing skeleton on both devices.

- [ ] Enrol in the Apple Developer Program ($99/yr).
- [ ] Create the Xcode project: SwiftUI multiplatform App template; iOS 17+ / macOS 14+ deployment targets.
- [ ] Set bundle identifier; configure signing for iOS and Mac destinations.
- [ ] Create a CloudKit container in the Apple Developer portal.
- [ ] Add the iCloud entitlement; enable CloudKit; select the container.
- [ ] Add SwiftData `@Model` types: `Project`, `Room`, `Piece`; enums `RoomKind`, `PileDirection`.
- [ ] Configure `ModelContainer` with `.private(.automatic)` CloudKit database in `CarpetMaticApp.swift`.
- [ ] Verify the schema deploys to the CloudKit dashboard (development environment).
- [ ] Stub a placeholder `NavigationStack` (iPhone) / `NavigationSplitView` (Mac) skeleton.
- [ ] Smoke-test: build and run on the user's iPhone (USB) and Mac.

## Phase 1 — MVP

Goal: every functional requirement in `REQUIREMENTS.md` works end-to-end.

### CRUD

- [ ] `ProjectListView`: list, create, rename, delete projects; navigate into detail.
- [ ] `ProjectDetailView`: edit name; roll-width picker (1/2/3/4/5 m); list of rooms; "Calculate" / Result navigation.
- [ ] `RoomDetailView`: edit name; kind picker (Rectangle / Stairs); list of pieces.
- [ ] `PieceEditorView`: width and length input (metres, 1 cm precision, validated ≤ roll width); pile-direction picker; rotate button (placeholder visual — see Phase 2).
- [ ] Input validation: oversize-width error message, blank name handling, sensible defaults.

### Calc engine

(Built early in `Engine/` — see "Done early" section above. Phase 1 just needs to wire it in.)

- [ ] Add `Engine/` as a local Swift Package dependency in the Xcode app.
- [ ] Write the `Adapters/` layer: convert `@Model` classes (`ProjectModel` etc.) to engine `Project` / `Room` / `Piece` value types.
- [ ] Wire the result view to call `PackingEngine.pack(_:)` on the converted project.

### Output

- [ ] `PileArrowView`: small reusable arrow icon, takes a `PileDirection`.
- [ ] `ResultView`: total linear metres at the top; per-room breakdown with each piece's dimensions and pile arrow.
- [ ] Result recomputes automatically on data change.
- [ ] `PDFExporter`: render `ResultView` content to PDF via PDFKit + `ImageRenderer`.
- [ ] `fileExporter` integration for share/save.

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
- [ ] App icon and launch screen.
- [ ] Delete confirmations; per-piece rotation undo.

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
