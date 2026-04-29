# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repo state

**Pre-code.** As of 2026-04-29 there is no Xcode project, no source files, and no tests. The repo contains only three planning documents and Claude memory. The first implementation step is **Phase 0** in `TODO.md` (Apple Developer enrolment + Xcode project scaffold).

When commands like build / lint / run-tests are needed, they will come from the Xcode project created in Phase 0 (`xcodebuild`, `swift test` if a Swift package is added, etc.). Do not fabricate commands until the project exists.

## Authoritative sources

Read these in order before doing anything substantive:

1. **`REQUIREMENTS.md`** — what we're building, formal F1–F4 requirements, what's explicitly out of scope, future backlog.
2. **`PLAN.md`** — architecture: tech stack, data model, sync, calculation engine, UI flow, phasing.
3. **`TODO.md`** — phased build checklist (Phase 0 / 1 / 2 / future).

If those conflict with this file, the docs win. If a user instruction conflicts with the docs, the user wins — and update the docs.

## What this app is (one paragraph)

A SwiftUI multiplatform (iPhone + Mac, iOS 17+ / macOS 14+) carpet calculator. Users create a Project (per house/job) with a fixed roll width (1/2/3/4/5 m), add Rooms (Rectangle or Stairs), and add rectangular Pieces with width × length and pile direction. The calc engine **bin-packs every piece in the entire project onto a single fixed-width roll**, minimising total linear metres. Persistence is SwiftData with CloudKit sync. Output is a per-room breakdown with pile arrows; export is PDF.

## Non-obvious decisions you must respect

Things that took multiple rounds of user clarification — easy to get wrong if you only skim the docs:

- **Bin-packing is project-wide, not per-room.** Pieces from different rooms share roll length. The 5.3 m wide example: the user enters one 5 m × L piece and one 0.3 m × L piece (in the same logical room), and the engine fits the 0.3 m piece anywhere it can on the roll — possibly nested next to a different room's piece. Don't write a per-room calc.
- **No software-managed joins.** Each input rectangle = one uncut piece from the roll. If the user wants a join (e.g. a room wider than the roll), they enter multiple pieces themselves.
- **No software-managed waste percentage.** The user pre-pads at input (currently +10 cm). Don't add a waste % field.
- **No L-shape, T-shape, or polygon support.** Rectangles + Stairs only. Stairs is a `Room.kind`, not a separate `Piece` type — a Stairs room contains a single rectangle whose length is the user-supplied unrolled total.
- **Dimensions stored as integer centimetres** in SwiftData (`widthCM: Int`, `lengthCM: Int`). Convert to/from metres at the UI boundary. Avoids float drift across CloudKit sync and PDF export.
- **`isRotated` is a stored flag**, not a view-time computation. The packing engine sees pieces in their post-rotation orientation. Pile direction rotates *with* the piece (pile is a property of the cut, not of the room).
- **Per-piece rotate button.** Not per-room, not per-project. Don't move it.
- **No auto-rotation in the packer.** The engine uses the orientation the user has set; it never decides to rotate a piece itself.
- **Algorithm is First-Fit-Decreasing shelf packing.** Deterministic, fast, not optimal — and that's intentional. The user explicitly prioritises consistency and review-ability over perfect optimisation.
- **Result view is per-room only.** No graphical layout view in MVP; pile arrows render inline next to each piece in the breakdown. The packing engine internally tracks piece positions on the roll so a future graphical view can be added without re-running it.
- **PDF export only.** `.pages`, RTF, DOCX are explicitly out of scope for MVP.
- **CloudKit constraints.** Every SwiftData property must be optional or have a default; relationships need optional inverses. Required by SwiftData ↔ CloudKit interop.

## Open items (don't ship without resolving)

- The visual design of the **rotate button** is TBD pending a reference screenshot from the user's existing software. Phase 2 picks this up — don't lock the visual in Phase 1.

## Memory

Persistent project memory lives at `~/.claude/projects/-Users-howie-Development-repos-carpet-matic/memory/`. The key files:

- `decisions_made.md` — every confirmed scope/tech/domain decision (mirrors a subset of REQUIREMENTS + PLAN).
- `project_overview.md` — one-paragraph summary.

If a decision changes during a session, update `decisions_made.md` *and* the relevant doc (REQUIREMENTS / PLAN / TODO).
