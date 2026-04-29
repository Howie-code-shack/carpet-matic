# Requirements — carpet-matic

Apple-platform (iPhone + Mac) app to calculate carpet requirements for a job by laying out user-supplied rectangular pieces onto a roll of fixed width and reporting the total linear metres required.

## Glossary

- **Project** — one job (e.g. a house).
- **Room** — a named group of pieces within a project.
- **Piece** — a rectangle to be cut from the roll, defined by width × length and pile direction.
- **Roll** — the carpet roll for the project, fixed width (1, 2, 3, 4, or 5 m), unlimited length.
- **Layout** — the arrangement of pieces on the roll computed by the calculator.
- **Linear metre** — a unit of roll length consumed.

## Functional requirements

### F1. Project management

- **F1.1** The user can create, rename, and delete projects.
- **F1.2** Each project has a name and a roll width chosen from {1, 2, 3, 4, 5} m.
- **F1.3** Projects persist across app launches.
- **F1.4** Projects sync between the user's iPhone and Mac via the user's iCloud account.
- **F1.5** The user can export a project's calculation result to PDF and share it.

### F2. Room and piece management

- **F2.1** A project contains zero or more rooms.
- **F2.2** Each room has a name and a kind: **Rectangle** or **Stairs**.
- **F2.3** A room contains one or more pieces.
- **F2.4** Each piece has: width (m), length (m), pile direction (one of four cardinal directions), and a per-piece rotated flag.
- **F2.5** A piece's width must be ≤ the project's roll width (validated at input).
- **F2.6** Dimensions are entered in metres to 1 cm precision. The software does not auto-pad measurements; the user pre-pads at input.
- **F2.7** The user can rotate a piece 90° via a per-piece rotate button. Rotating swaps width and length, and the pile direction rotates with the piece (pile is a property of the cut, not of the room).

### F3. Calculation

- **F3.1** The calculator packs all pieces from all rooms in a project onto a single roll of the project's chosen width.
- **F3.2** The calculator's goal is to minimise the total linear metres of roll consumed. An optimal packing is **not required** — the user reviews the result and corrects via the rotate button before committing.
- **F3.3** The calculator does **not** split or join pieces. Each input piece is placed as a single uncut rectangle. If the user wants a join, they enter two adjacent pieces themselves.
- **F3.4** The calculator does **not** auto-rotate pieces. It uses the orientation the user has set.
- **F3.5** The calculator returns: the total linear metres consumed, and a per-room breakdown listing the pieces in that room.

### F4. Output

- **F4.1** The result view shows the total linear metres required for the project.
- **F4.2** The result view shows a per-room breakdown: each room's name, kind (Rectangle or Stairs), and for each piece its width × length and pile direction (rendered as a small arrow icon next to the piece line).
- **F4.3** The result is recomputed automatically on any change to project, room, or piece data.
- **F4.4** The PDF export contains the same information as the on-screen result.

## Non-functional requirements

- **N1** Offline-first. All calculation runs locally; iCloud sync is non-blocking and degrades gracefully if offline.
- **N2** Clean, simple UI focused on speed and usability — no clutter, fast input.
- **N3** Native experience on iPhone and Mac via SwiftUI multiplatform.
- **N4** Targets iOS 17+ and macOS 14+.

## Out of scope (MVP)

- L-shaped rooms and other non-rectangular shapes (rectangle + stairs only).
- Software-managed joins / mid-strip seams (the user enters multiple pieces instead).
- Software-managed waste/safety percentage (the user pre-pads at input).
- Per-roll-length output view (only a per-room breakdown in MVP).
- Full graphical layout view of cut pieces on the roll. (Pile arrows live next to each piece line in the per-room breakdown.)
- Cost estimation (price per linear metre × total).
- Pages (`.pages`) export, RTF, or DOCX. PDF only.

## Open items

- The visual design of the per-piece **rotate button** is TBD pending a reference screenshot from the user's existing software.

## Future backlog

L-shape and other shapes; waste % field; joined-strip handling; full graphical layout view; per-roll-length output view; cost estimation; RTF/DOCX/Pages export; TestFlight distribution; a more sophisticated packing algorithm; a real stair calculator (steps × tread × riser).
