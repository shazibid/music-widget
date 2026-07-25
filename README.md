# MusicWidget

A tiny always-on-top desktop widget for macOS that shows what's currently
playing in **Spotify** or **Apple Music** and lets you control playback
without switching apps. No dock icon, no menu bar clutter — just a small,
draggable, floating widget that sits on top of your other windows.

Pick from four skins: a Liquid Glass pill, a spinning CD, a classic
click-wheel iPod, or a spinning vinyl record.

## Features

- **Live now-playing display** — track title, artist, and artwork, polled
  once per second.
- **Playback controls** — play/pause, next, previous.
- **Auto source switching** — watches both Spotify and Apple Music; shows
  whichever one is actively playing, and falls back to whichever is open if
  neither is.
- **Four skins**, switchable from a right-click context menu:
  - **Glass Pill** — a compact horizontal bar with a Liquid Glass background.
  - **Rotating CD** — an album-art disc that spins while playing.
  - **iPod** — a faithful click-wheel iPod, complete with a working wheel
    (menu / prev / next / play-pause) and an "Up Next" queue screen.
  - **Vinyl Record** — a spinning record with the artwork as the label.
- **Queue view** (iPod skin only) — press the wheel's "Menu" button to see
  upcoming tracks. Available for Apple Music; Spotify's scripting interface
  doesn't expose a queue, so that case is shown explicitly rather than
  silently empty.
- **Floating, borderless, movable window** — always on top, draggable from
  anywhere on its background, remembers nothing between launches except your
  chosen skin (position resets to the top-right corner of the main screen
  each launch).

## Requirements

- **macOS 26 (Tahoe) or later** — the app targets `.macOS(.v26)` and uses the
  Liquid Glass `glassEffect` API, which doesn't exist on earlier macOS
  versions.
- **Xcode 26 / Swift 6.2 toolchain or later** (to build).
- **Spotify** and/or **Apple Music (Music.app)** — the widget has nothing to
  show if neither is running.

## Getting started

### 1. Build and run

From the command line, with the Swift toolchain on your `PATH`:

```bash
swift run
```

This builds the `MusicWidget` executable target and launches it. Use
`swift build -c release` for an optimized build (the binary will be at
`.build/release/MusicWidget`).

Alternatively, open the folder in **Xcode** (File → Open… on `Package.swift`)
or in **VS Code** with the Swift extension — a debug/release launch
configuration is already set up in `.vscode/launch.json`.

The app has no windowed dock icon or menu bar item (it runs as an
`.accessory` app) — after launching, look for the widget in the top-right
corner of your main screen.

### 2. Grant Automation permission

MusicWidget talks to Spotify and Music.app via AppleScript, so the first time
it tries to read a track or send a command, macOS will prompt you to allow
MusicWidget to control Spotify and/or Music. Click **OK** on each prompt.

If you miss the prompt or deny it by mistake, re-enable it manually:

**System Settings → Privacy & Security → Automation → MusicWidget** →
check **Spotify** and **Music**.

Without this permission the widget will show "Nothing Playing" even while
music is actively playing.

## Usage

- **Move the widget** — click and drag anywhere on its background.
- **Switch skins / quit** — right-click anywhere on the widget to open the
  context menu, then pick a skin or **Quit**.
- **Playback controls** — click the play/pause, next, and previous buttons
  (on the iPod skin, these live on the click wheel: top = menu/queue,
  left/right = previous/next, bottom = play/pause, center = play/pause).
- **Queue (iPod only)** — press the top of the click wheel to flip the
  screen to "Up Next". Press again to go back to now-playing.

## How it works

- `PlayerViewModel` polls every second on a background task, asking each
  registered `MediaAppController` (`SpotifyController`, `AppleMusicController`)
  whether its app is running and, if so, its current track/state/position.
  Whichever app is actively playing wins; if both are just open and paused,
  the first one in registration order is shown.
- Each controller talks to its app entirely through `NSAppleScript` —
  there's no official Spotify or Music SDK involved, just the same scripting
  dictionaries Script Editor / Shortcuts can use.
- Artwork differs by source: Spotify hands back a URL that's fetched over
  HTTP, while Music.app only exposes raw artwork bytes through AppleScript.
- The window is a borderless, floating, always-on-top `NSWindow` hosting a
  SwiftUI view. Skin changes animate the window's frame and the SwiftUI
  content together so the resize reads as one motion.

## Project structure

```
Sources/MusicWidget/
├── main.swift                 # App entry point, NSWindow/NSApplication setup
├── PlayerViewModel.swift      # Polling loop, active-source selection, playback actions
├── MediaAppController.swift   # Shared protocol + Track/QueueTrack/PlayerState models
├── SpotifyController.swift    # Spotify AppleScript bridge
├── AppleMusicController.swift # Music.app AppleScript bridge
├── WidgetSkin.swift           # Skin enum + persisted skin selection (SkinStore)
├── RootView.swift             # Skin switcher + right-click context menu
├── PillView.swift             # Glass Pill skin
├── RotatingCDView.swift       # Rotating CD skin
├── VinylView.swift            # Vinyl Record skin
├── IPodView.swift             # Click-wheel iPod skin (now-playing + queue screens)
├── MarqueeText.swift          # Auto-scrolling text for long titles
└── Resources/
    └── ipod-body.png          # Device artwork used by the iPod skin
```

## Known limitations

- **macOS only**, and specifically macOS 26+ (Liquid Glass dependency).
- **Spotify has no queue** — its AppleScript dictionary only exposes the
  current track, so the iPod skin's "Up Next" screen shows an explanatory
  message instead of a list when Spotify is the active source.
- Position is not persisted between launches — only the selected skin is
  (via `UserDefaults`).
- No Apple Music API / Spotify Web API integration — everything is local
  scripting, so it only reflects apps actually running on your Mac.
