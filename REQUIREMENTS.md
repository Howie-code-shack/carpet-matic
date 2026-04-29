# Requirements — carpet-matic

Apple-platform (iPhone + Mac) app for carpet fitters. The user enters **room dimensions**; the app computes the strips needed, packs them across the roll, and reports the total linear metres required.

## Glossary

- **Project** — one job (e.g. a house).
- **Room** — a named rectangle within a project, defined by width × length and a pile direction.
- **Strip** — a piece cut from the roll. Strips are computed by the engine from room dimensions; the user never enters strips directly.
- **Roll** — the carpet roll for the project, fixed width (1, 2, 3, 4, or 5 m), unlimited length.
- **Layout** — the arrangement of strips on the roll computed by the engine.
- **Linear metre** — a unit of roll length consumed.

## Functional requirements

### F1. Project management

- **F1.1** The user can create, rename, and delete projects.
- **F1.2** Each project has a name and a roll width chosen from {1, 2, 3, 4, 5} m.
- **F1.3** Projects persist across app launches.
- **F1.4** Projects sync between the user's iPhone and Mac via the user's iCloud account (CloudKit).
- **F1.5** The user can export a project's calculation result to PDF and share it.

### F2. Room management

- **F2.1** A project contains zero or more rooms.
- **F2.2** Each room has: a name, a kind (**Rectangle** or **Stairs**), width (m), length (m), and a pile direction (one of four cardinal directions).
- **F2.3** Dimensions are entered in metres to 1 cm precision. The software does not auto-pad measurements; the user pre-pads at input.
- **F2.4** When a room is created, the app suggests the pile direction that minimises linear metres for that room. The user can override.
- **F2.5** Rooms wider than the roll on the chosen strip axis are split automatically into multiple strips (first n−1 are roll-width wide; last is the remainder). The user does not split rooms manually.
- **F2.6** Stairs is treated as a rectangle: the user enters the stair carpet's width × total unrolled length. There is no dedicated steps/tread calculator in MVP.

### F3. Calculation

- **F3.1** The calculator generates strips for every room (pile up/down → strips along Length; pile left/right → strips along Width) and bin-packs them across the project onto a single roll of the project's chosen width.
- **F3.2** The calculator's goal is to minimise total linear metres of roll consumed. An optimal packing is **not required** — the user reviews and overrides pile direction per room as needed.
- **F3.3** The calculator does **not** auto-rotate or override the user's chosen pile direction. It uses the direction the user has set; the optimisation happens by suggesting a default at room creation.
- **F3.4** The calculator returns: the total linear metres consumed, and a per-room breakdown listing the strips needed for each room.

### F4. Output

- **F4.1** The result view shows the total linear metres required for the project.
- **F4.2** The result view shows a per-room breakdown: each room's name, kind, strip count, and for each strip its width × length and pile direction (rendered as a small arrow icon).
- **F4.3** The result is recomputed automatically on any change to project, room, or roll data.
- **F4.4** The PDF export contains the same information as the on-screen result.

## Non-functional requirements

- **N1** Offline-first. All calculation runs locally; iCloud sync is non-blocking and degrades gracefully if offline.
- **N2** Clean, simple UI focused on speed and usability — no clutter, fast input.
- **N3** Native experience on iPhone and Mac (SwiftUI iOS app, runs on Mac via "Designed for iPad" mode).
- **N4** Targets iOS 17+ and macOS 14+.

## Out of scope (MVP)

- L-shaped rooms and other non-rectangular shapes (rectangle + stairs only).
- Multi-rectangle rooms (a Room is a single rectangle in MVP).
- Software-managed waste / safety percentage (the user pre-pads at input).
- Per-roll-length output view (only a per-room breakdown in MVP).
- Full graphical layout view of cut strips on the roll. Pile arrows live next to each strip line in the per-room breakdown.
- Cost estimation (price per linear metre × total).
- Pages (`.pages`) export, RTF, or DOCX. PDF only.

## Open items

- The visual design of the **pile-direction picker / rotate UI** is TBD pending a reference screenshot from the user's existing software.

## Future backlog

L-shape and other shapes; multi-rectangle rooms; waste % field; full graphical layout view; per-roll-length output view; cost estimation; RTF/DOCX/Pages export; TestFlight distribution; a more sophisticated packing algorithm; a real stair calculator (steps × tread × riser).
