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
  upcoming tracks. Works natively for Apple Music. Spotify's AppleScript
  dictionary has no queue concept at all, so queue support there requires
  connecting your Spotify account (see below) to pull the queue from
  Spotify's Web API instead.
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

The steps below assume you've never used Terminal, Git, or Xcode before, so
everything is spelled out in full. If any of this is already familiar, skip
ahead — experienced folks can just `git clone`, `swift run`, done.

### 1. Install Xcode

Xcode is Apple's free app-building tool. Installing it gives you the Swift
compiler and everything else needed to build this project — nothing else to
install separately.

1. Open the **App Store** app (click its icon in the Dock, or press
   `Cmd + Space`, type `App Store`, press Return).
2. Search for **Xcode** and click **Get** / the download button. It's a big
   download (several gigabytes), so this may take a while.
3. Once installed, open **Xcode** from your Applications folder at least
   once. It will ask to install some "additional components" — click
   **Install**, enter your Mac password if prompted, and wait for it to
   finish. You can then quit Xcode; you won't need to open it again unless
   you want to.

### 2. Get the project's code onto your Mac

This project's code lives on **GitHub** at
https://github.com/shazibid/music-widget. "Cloning" just means downloading a
copy of it. Pick whichever of these two ways feels easier:

**Option A — Download as a ZIP file (simplest, no extra tools)**

1. Go to https://github.com/shazibid/music-widget in your web browser.
2. Click the green **Code** button, then click **Download ZIP**.
3. Open your **Downloads** folder and double-click the downloaded file to
   unzip it. You'll end up with a folder named `music-widget-main`.

**Option B — Use `git clone` (a bit more setup, easier to update later)**

1. Open the **Terminal** app: press `Cmd + Space`, type `Terminal`, press
   Return. Terminal lets you type commands to your Mac instead of clicking —
   for this guide you'll only need to copy/paste a couple of lines.
2. Type the following and press Return to move into your Documents folder
   (`cd` means "change directory"):
   ```bash
   cd ~/Documents
   ```
3. Type or paste the following and press Return:
   ```bash
   git clone https://github.com/shazibid/music-widget.git
   ```
   This downloads the code into a new folder named `music-widget` inside
   Documents. The first time you use `git`, macOS may ask to install
   "Command Line Developer Tools" — click **Install** and wait for it to
   finish, then run the command above again.

### 3. Open Terminal inside the project folder

Everything from here on happens in Terminal, run from inside the project
folder.

1. Open **Terminal** if it isn't already open (`Cmd + Space`, type
   `Terminal`, press Return).
2. Type `cd ` — that's "c", "d", then a single space — but **don't press
   Return yet**.
3. Switch to **Finder**, find the project folder from step 2
   (`music-widget-main` or `music-widget`), and drag that folder from Finder
   directly onto the Terminal window. This types out its full location for
   you.
4. Click back in Terminal and press Return. Your prompt now represents
   "inside" the project folder — every command below should be run here.

### 4. Build and run

In that same Terminal window, type:

```bash
swift run
```

and press Return. The first run downloads dependencies and compiles the app,
so it can take a minute or two and a lot of text will scroll by — that's
normal, just let it finish. Once it's done, the widget appears in the
top-right corner of your screen.

To use the app again later, repeat steps 3–4: open Terminal, `cd` into the
project folder (Terminal usually remembers recent folders if you press the
Up arrow to cycle through previous commands), then `swift run`.

A few notes for later, once you're comfortable with the basics:

- `swift build -c release` produces a faster, optimized build (the binary
  ends up at `.build/release/MusicWidget`).
- You can also open the project in **Xcode** (double-click `Package.swift`
  inside the project folder) or in **VS Code** with the Swift extension — a
  debug/release launch configuration is already set up in
  `.vscode/launch.json`.

The app has no windowed dock icon or menu bar item (it runs as an
`.accessory` app) — after launching, look for the widget in the top-right
corner of your main screen.

### 5. Connect your Spotify account (optional, for Spotify queue support)

Spotify's AppleScript dictionary can't report a queue, so the iPod skin's
"Up Next" screen shows Spotify tracks only after you connect your account
via the Spotify Web API:

- Right-click the widget (on a trackpad: click with two fingers, or hold
  `Control` and click) → **Connect Spotify Account…**. This opens your
  browser to Spotify's login/consent page (Authorization Code + PKCE, so no
  client secret is involved) and starts a short-lived local server on
  `127.0.0.1:8888` to catch the redirect.
- Approve access, and the widget stores a refresh token in the macOS
  Keychain (see `SpotifyKeychainStore`) so you don't have to log in again.
- **Disconnect Spotify Account** (same menu) revokes the local session and
  clears the stored token.

The queue is only shown when Spotify's Web API agrees that this Mac is the
actively-playing device — if playback was last controlled from another
device (phone, speaker, etc.), the queue is suppressed rather than shown for
the wrong session.

You can also fetch the queue from the command line without launching the
widget's window:

```bash
swift run MusicWidget --print-queue
```

This requires Spotify to be running and already connected via the menu
above; it prints the queue as JSON and exits.

### 6. Grant Automation permission

MusicWidget talks to Spotify and Music.app via AppleScript, so the first time
it tries to read a track or send a command, macOS will pop up a dialog
asking to let MusicWidget control Spotify and/or Music. Click **OK** on each
one.

If you miss a prompt or click **Don't Allow** by mistake, you can turn it
back on by hand:

1. Open **System Settings** (click the Apple logo in the top-left corner of
   your screen → **System Settings…**).
2. Click **Privacy & Security** in the sidebar.
3. Click **Automation**.
4. Find **MusicWidget** in the list and turn on the switches next to
   **Spotify** and **Music**.

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
- **Spotify queue** is the one thing AppleScript can't provide, so it's
  fetched separately via the Spotify Web API instead. `SpotifyAuthManager`
  runs an Authorization Code + PKCE login (browser consent + a short-lived
  loopback HTTP server to catch the redirect), storing only a refresh token
  in the Keychain via `SpotifyKeychainStore`. `SpotifyWebAPI` exchanges that
  for an access token on demand and hits the `/me/player/queue` endpoint,
  discarding the result if the API's notion of "currently playing" doesn't
  match what this Mac's local Spotify client is reporting (i.e. some other
  device is actually driving playback).

## Project structure

```
Sources/MusicWidget/
├── main.swift                 # App entry point, NSWindow/NSApplication setup, --print-queue CLI
├── PlayerViewModel.swift      # Polling loop, active-source selection, playback actions
├── MediaAppController.swift   # Shared protocol + Track/QueueTrack/PlayerState/QueueFetchResult models
├── SpotifyController.swift    # Spotify AppleScript bridge
├── AppleMusicController.swift # Music.app AppleScript bridge
├── WidgetSkin.swift           # Skin enum + persisted skin selection (SkinStore)
├── RootView.swift             # Skin switcher + right-click context menu (incl. Spotify connect/disconnect)
├── PillView.swift             # Glass Pill skin
├── RotatingCDView.swift       # Rotating CD skin
├── VinylView.swift            # Vinyl Record skin
├── IPodView.swift             # Click-wheel iPod skin (now-playing + queue screens)
├── MarqueeText.swift          # Auto-scrolling text for long titles
├── Spotify/
│   ├── SpotifyAuthConfig.swift        # Client ID, redirect URI/port, OAuth scopes
│   ├── SpotifyAuthManager.swift       # PKCE login/refresh, in-memory access token
│   ├── SpotifyKeychainStore.swift     # Refresh token persistence (Keychain)
│   ├── LoopbackCallbackServer.swift   # Local HTTP server that catches the OAuth redirect
│   └── SpotifyWebAPI.swift            # `/me/player/queue` fetch + active-device matching
└── Resources/
    └── ipod-body.png          # Device artwork used by the iPod skin
```

## Known limitations

- **macOS only**, and specifically macOS 26+ (Liquid Glass dependency).
- **Spotify has no queue via AppleScript** — its scripting dictionary only
  exposes the current track, so the iPod skin's "Up Next" screen falls back
  to the Spotify Web API (see above), which requires connecting your account
  once. Without connecting, Spotify's queue screen shows an explanatory
  message instead of a list.
- **Spotify queue reflects the active Spotify Connect device**, not
  necessarily this Mac — if another device last touched playback, the queue
  is suppressed rather than shown for the wrong session.
- Position is not persisted between launches — only the selected skin is
  (via `UserDefaults`).
- No Apple Music API integration — Apple Music support is local AppleScript
  only, so it only reflects the Music.app instance actually running on your
  Mac.
