# Pre-prod checklist

Everything that stands between "works on my Mac" and "a stranger on GitHub can
install and use this." Grouped by front, roughly in priority order.

## 1. Spotify API access — blocking

- [x] **Extended Quota Mode ruled out.** Confirmed Spotify requires a
      registered business entity plus 25k+ MAU to even apply — not
      obtainable for a solo hobby app. `SpotifyAuthConfig.clientID` stays in
      Development Mode, which caps access to a handful of manually
      allowlisted users (see the comment in `LoopbackCallbackServer.swift:88`).
      Right now, any stranger who clicks "Connect Spotify Account" hits
      Spotify's own consent-page rejection, not a bug in this code.
- [ ] **Decided path: make the client ID user-supplied.** Document how a
      user registers their own free Spotify app on developer.spotify.com,
      and either sets an env var or pastes a client ID into the widget's
      menu, replacing the hardcoded `SpotifyAuthConfig.clientID`. More setup
      friction for people who want Spotify queue support, but removes the
      quota ceiling entirely. Not yet implemented.
- [ ] Update the README's Spotify-connect steps and the "Connect Spotify
      Account" menu flow to match once the above lands.

## 2. Code signing & Gatekeeper — decided, no longer blocking

- [x] **Decision: no Apple Developer Program.** The $99/yr Developer ID
      enrollment isn't happening. `dist/Miniplayer.app` stays ad-hoc signed
      (`Packaging/build-app.sh`) indefinitely, not just until launch — every
      fresh download will need a right-click-Open to get past Gatekeeper
      (see README step 5), permanently, not as a temporary gap.
- [ ] Keep the README's right-click-Open instructions accurate and easy to
      find, since every new user hits this every time.

## 3. Distribution / release pipeline

- [ ] No GitHub Actions or Release exists yet. Decide: manual zip-and-upload
      per version, or a workflow that builds+signs+notarizes+uploads on tag
      push.
- [ ] If automating: notarization needs an app-specific password / API key
      stored as a GitHub Actions secret, not committed anywhere.
- [ ] (Optional, later) auto-update mechanism (e.g. Sparkle) so users aren't
      manually re-downloading every release.

## 4. Legal

- [x] **No LICENSE file** — added `LICENSE` (MIT) and linked it from the
      README.
- [ ] Keep the existing "not affiliated with Apple or Spotify" disclaimer
      (already in `Packaging/Info.plist`) visible in the README too, since
      that's what most new users will actually read first.

## 5. Branding / assets

- [x] **App renamed to "Miniplayer"** (from "MusicWidget") — product name,
      bundle ID (`com.shazibid.Miniplayer`), target/folder names, docs, and
      the GitHub repo itself (now `shazibid/miniplayer`) all updated to
      match.
- [x] `Packaging/AppIcon.icns` **replaced** — was a placeholder traced
      directly from Apple's actual click-wheel iPod product design (a real
      trademark/trade-dress risk for an app icon specifically, since the
      icon is the app's public identity, unlike the in-app iPod skin which
      reads as an obvious nostalgia option among four). New icon is
      original vector artwork (an abstract iridescent CD disc), matching
      the in-app CD skin's aesthetic instead of tracing a real product.

## 6. Platform compatibility

- [x] **Confirmed `.macOS(.v26)` is already the correct minimum for v1.**
      Liquid Glass (`glassEffect`) shipped in macOS 26 — there's no Mac that
      supports Liquid Glass but falls below this app's current requirement,
      so there's nothing to loosen. `LSMinimumSystemVersion` in
      `Packaging/Info.plist` matches.
- [ ] **Future version: broaden support to pre-26 Macs.** Add a fallback
      rendering path (no `glassEffect`) for the Pill, CD, and Vinyl skins,
      which are the only three that currently use it (iPod doesn't). Explicit
      post-v1 roadmap item, not a v1 blocker.

## 7. Code quality

- [ ] Release build currently emits several Swift 6 concurrency warnings
      (non-`Sendable` static var in `PlayerViewModel.swift:23`, data-race-risk
      closures in `PlayerViewModel.swift:51,60,69,88`, `SpotifyAuthManager.swift:42`,
      `LoopbackCallbackServer.swift:126`). Harmless today, but worth cleaning
      up before wider use — some of these could become hard errors in a
      future Swift toolchain, and a couple point at real (if narrow) race
      conditions.
- [ ] Address the unhandled-resource build warning for
      `Sources/Miniplayer/Resources/ipod-body.png` (declare it explicitly in
      `Package.swift` rather than relying on implicit pickup).

## 8. Testing & CI

- [x] Added a CI workflow (`.github/workflows/ci.yml`) that runs
      `swift build` + unit tests on every push/PR (the actual merge gate),
      plus an advisory E2E job — see README's "Testing" section.
- [x] Added unit tests (`Tests/MiniplayerTests`) around the parts that
      don't need a live Spotify/Music.app session: AppleScript response
      parsing, PKCE verifier/challenge generation, queue-matching logic,
      `PlayerViewModel` source selection, skin/window persistence, and the
      OAuth loopback server's request parsing.
- [x] Added an E2E smoke suite (`MiniplayerUITests.xcodeproj`, real
      XCUITest) covering skin switching, playback controls, and the
      now-playing display, driven by a `#if DEBUG` fake-player harness so it
      doesn't need Spotify/Music installed.
- [x] Confirmed on PR #2: GitHub's hosted `macos-latest` runner has the
      Accessibility permission XCUITest needs pre-granted — `e2e-smoke`
      passed there, not just locally.
- [ ] That's one data point, not "reliably green." `unit-tests` is already
      a required branch-protection check on `main`; `e2e-smoke` is still
      `continue-on-error`. Leave it advisory for a few more PRs to see if
      it stays green before promoting it to required too.

## 9. Security

- [X] PKCE flow already does the right things (state-param CSRF check,
      code_verifier/challenge, refresh token in Keychain, loopback-only
      callback server) — no action needed, just noting it's already solid.
- [ ] Do a pass confirming no secrets belong in `SpotifyAuthConfig.swift`
      beyond the client ID (PKCE apps don't use a client secret, so this
      should already be true — just worth double-checking before more eyes
      are on the repo).

## 10. Repo / community readiness

- [ ] No CONTRIBUTING guide or issue templates — optional, but worth adding
      once outside users start filing issues against a public repo.
- [ ] No versioning/changelog convention yet (`CFBundleVersion` in
      `Packaging/Info.plist` is still `1.0.0`) — decide how version bumps map
      to git tags/releases once #3 exists.
