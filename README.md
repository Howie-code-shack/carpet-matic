# carpet-matic

iOS app (runs on iPhone and on Apple Silicon Mac as "Designed for iPad") for carpet fitters. Enter a project's roll width and each room's dimensions; the app computes the strips needed, packs them across the roll to minimise total linear metres, and gives you a per-room cut list with pile-direction arrows. Persistence is SwiftData (local; CloudKit sync is wired into the data model but not yet enabled in entitlements).

For the design rationale see `REQUIREMENTS.md`, `PLAN.md`, `TODO.md`, and `CLAUDE.md`.

## Prerequisites

- A Mac running a recent macOS (Apple Silicon recommended).
- **Xcode 15.3+** from the Mac App Store. Developed and tested against Xcode 26.
- **Git**.

That's it — no Homebrew packages, CocoaPods, or fastlane setup. The only package dependency (`CarpetMaticEngine`) lives inside this repo at `Engine/` and is wired up as a local Swift Package, so Xcode resolves it on its own.

## Get the code

```bash
git clone https://github.com/Howie-code-shack/carpet-matic.git
cd carpet-matic
```

## Run the engine tests (optional, no Xcode needed)

The calculation engine is a standalone Swift Package — 21 unit tests, runs in a couple of seconds:

```bash
cd Engine
swift test
```

You should see something like `Executed 21 tests, with 0 failures`.

## Open in Xcode

```bash
open CarpetMatic/CarpetMatic.xcodeproj
```

First open: Xcode will resolve `CarpetMaticEngine` (the local package) — takes ~10 seconds. Wait until "Resolve Package Graph" finishes in the activity bar.

If a dialog says **"The file 'ContentView.swift' couldn't be opened"** — dismiss it. That's a stale editor-tab reference left over from the early scaffolding; the file was deleted intentionally. The build is unaffected.

## Configure signing

You need to do this once even for Simulator-only runs, because Xcode's defaults reference my team.

1. In the project navigator, click the top **CarpetMatic** item.
2. Select the **CarpetMatic** *target* (not the project).
3. Open the **Signing & Capabilities** tab.
4. **Team** — set this to one of:
   - **None** if you only want the iOS Simulator. Simplest.
   - Your Apple ID's **Personal Team** if you want to install on a real iPhone via free side-load (the app re-signs every 7 days; up to 3 such apps per device).
   - A paid **Apple Developer Program** team if you want CloudKit, push notifications, or TestFlight.
5. **Bundle Identifier** — change `howie.one.CarpetMatic` to something unique to you, e.g. `com.<your-name>.CarpetMatic`. Apple won't let two teams share a bundle ID.

## Pick a destination and run

In the Xcode toolbar, click the destination chooser (next to the play button) and pick one of:

- **An iOS Simulator** (e.g. *iPhone 17*) — easiest. No signing, no device.
- **My Mac (Designed for iPad)** — runs on Apple Silicon Macs as an iPad-style app. No setup needed.
- **A connected iPhone** — plug in via USB, tap "Trust this computer" on the phone the first time, then select it. Requires a Team set in step 4.

Hit **⌘R** to build and run.

## Deployment target gotcha

The project currently has `IPHONEOS_DEPLOYMENT_TARGET = 26.4` (the Xcode 26 default). If your iPhone or chosen Simulator is on an older iOS, change it:

CarpetMatic target → **General** tab → **Minimum Deployments** → **iOS** → set to **17.0** (the floor — SwiftData requires iOS 17+).

The Engine package is already iOS 17 / macOS 14 minimum, so the package side won't object.

## CloudKit (cross-device sync) — not enabled yet

The SwiftData models are CloudKit-friendly (optional or default-valued properties, optional inverses), but the iCloud entitlement and CloudKit container aren't configured. To turn it on:

1. Get a paid Apple Developer Program membership ($99/yr).
2. In **Signing & Capabilities** → **+ Capability** → **iCloud**. Tick **CloudKit**, create a container called e.g. `iCloud.com.<your-name>.CarpetMatic`.
3. Add **Background Modes** capability and tick **Remote notifications**.
4. Build & run. SwiftData will auto-detect the iCloud entitlement and start syncing.

See `TODO.md` Phase 0 for the full checklist.

## Project layout

```
carpet-matic/
├── Engine/                          # Swift Package: bin-packing calc engine + tests
│   ├── Package.swift
│   ├── Sources/CarpetMaticEngine/   # Models, PackingEngine, PackingResult
│   └── Tests/CarpetMaticEngineTests/
├── CarpetMatic/                     # Xcode iOS app
│   ├── CarpetMatic.xcodeproj/
│   └── CarpetMatic/                 # SwiftUI views, SwiftData @Models, PDF export
├── REQUIREMENTS.md                  # F1–F4 functional requirements
├── PLAN.md                          # architecture, data model, calc engine details
├── TODO.md                          # phased build checklist
├── CLAUDE.md                        # guidance for Claude Code agents
└── README.md                        # you are here
```

## Common tasks

```bash
# Engine tests (fast, no Xcode)
cd Engine && swift test

# Run a single engine test by name
cd Engine && swift test --filter PackingEngineTests/testCrossRoomNestingShareShelves

# Build the app for the iOS Simulator from the command line
cd CarpetMatic && xcodebuild -scheme CarpetMatic \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath /tmp/cm-derived build

# Or just hit ⌘R in Xcode — that's the everyday loop.
```

## Troubleshooting

- **SourceKit error: "No such module 'CarpetMaticEngine'"** — appears in the editor before the first successful build. Resolves itself after one ⌘B.
- **"ContentView.swift couldn't be opened"** — see above; dismiss the dialog.
- **`hapticpatternlibrary.plist` errors in the console when typing in text fields** — Simulator-only noise from CoreHaptics. Won't appear on a real device. Filter the Xcode console with the search box (type `CarpetMatic`) to hide it.
- **Bundle ID conflict** — change the bundle ID in Signing & Capabilities to something unique to your team.
- **App on Simulator has stale data after a schema change** — long-press the app icon in the Simulator → Remove App → run again.
