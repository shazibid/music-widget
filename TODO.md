# Pre-prod checklist

Everything that stands between "works on my Mac" and "a stranger on GitHub can
install and use this." Grouped by front, roughly in priority order.

## 0. UI Changes

- [ ] Full screen mode for pill, cd, and vinyl views
- [ ] iPod stickers
- [ ] iPod stickers app to add and modify iPod
- [ ] View for older mac versions not compatibile with liquid glass
- [ ] "Open Spotify" button
- [ ] explore volume adjustments in the UI

## 1. Spotify API access — blocking

- [ ] **Get out of Development Mode.** `SpotifyAuthConfig.clientID` points at
      an app on developer.spotify.com that's still in Development Mode, which
      Spotify caps at a handful of manually allowlisted users (see the
      comment in `LoopbackCallbackServer.swift:88`). Right now, any stranger
      who clones this repo and clicks "Connect Spotify Account" will hit
      Spotify's own consent-page rejection, not a bug in this code.
      Two paths:
      - Apply for **Extended Quota Mode** on the Spotify dashboard. Note
        Spotify has been rejecting a lot of these for small/hobby apps since
        their 2024 policy tightening — don't assume approval.
      - If denied (or as the fallback), make the client ID **user-supplied**
        instead of hardcoded: document how a user registers their own free
        Spotify app and either sets an env var or pastes a client ID into the
        widget's menu. More setup friction, but it removes the quota
        ceiling entirely.
- [ ] Decide which path before writing GitHub-facing install docs — it
      changes what "Connect Spotify Account" looks like for a new user.

## 2. Code signing & Gatekeeper

- [ ] `dist/MusicWidget.app` is **ad-hoc signed only** (`Packaging/build-app.sh`).
      Every fresh download needs a right-click-Open to get past Gatekeeper —
      fine for you, friction/scary-looking for a random GitHub visitor.
- [ ] Enroll in the **Apple Developer Program** ($99/yr) if you want that
      friction gone.
- [ ] Update `build-app.sh` to sign with a Developer ID Application cert +
      hardened runtime (`--options runtime`), then `xcrun notarytool submit`
      and `xcrun stapler staple` the app before it ships.
- [ ] Hardened runtime may require adding entitlements for the AppleScript
      automation calls — verify Spotify/Music.app control still works after
      turning it on.

## 3. Distribution / release pipeline

- [ ] No GitHub Actions or Release exists yet. Decide: manual zip-and-upload
      per version, or a workflow that builds+signs+notarizes+uploads on tag
      push.
- [ ] If automating: notarization needs an app-specific password / API key
      stored as a GitHub Actions secret, not committed anywhere.
- [ ] (Optional, later) auto-update mechanism (e.g. Sparkle) so users aren't
      manually re-downloading every release.

## 4. Legal

- [ ] **No LICENSE file** in the repo. It's public on GitHub right now with
      no stated terms — add one (MIT/Apache-2.0/etc.) so people know what
      they're allowed to do with the code.
- [ ] Keep the existing "not affiliated with Apple or Spotify" disclaimer
      (already in `Packaging/Info.plist`) visible in the README too, since
      that's what most new users will actually read first.

## 5. Branding / assets

- [ ] `Packaging/AppIcon.icns` is a **placeholder** generated from the iPod
      skin artwork (already flagged in the README's Known Limitations) —
      replace with real icon art before pointing strangers at this.

## 6. Platform compatibility

- [ ] `Package.swift` hard-requires `.macOS(.v26)` for the Liquid Glass API.
      macOS 26 is very new, so this alone excludes most Mac users right now.
      Decide whether that's an accepted launch constraint or whether the
      Glass Pill skin needs a fallback rendering path on older macOS so the
      other three skins (CD, iPod, Vinyl) can reach a wider audience.

## 7. Code quality

- [ ] Release build currently emits several Swift 6 concurrency warnings
      (non-`Sendable` static var in `PlayerViewModel.swift:23`, data-race-risk
      closures in `PlayerViewModel.swift:51,60,69,88`, `SpotifyAuthManager.swift:42`,
      `LoopbackCallbackServer.swift:126`). Harmless today, but worth cleaning
      up before wider use — some of these could become hard errors in a
      future Swift toolchain, and a couple point at real (if narrow) race
      conditions.
- [ ] Address the unhandled-resource build warning for
      `Sources/MusicWidget/Resources/ipod-body.png` (declare it explicitly in
      `Package.swift` rather than relying on implicit pickup).

## 8. Testing & CI

- [x] Added a CI workflow (`.github/workflows/ci.yml`) that runs
      `swift build` + unit tests on every push/PR (the actual merge gate),
      plus an advisory E2E job — see README's "Testing" section.
- [x] Added unit tests (`Tests/MusicWidgetTests`) around the parts that
      don't need a live Spotify/Music.app session: AppleScript response
      parsing, PKCE verifier/challenge generation, queue-matching logic,
      `PlayerViewModel` source selection, skin/window persistence, and the
      OAuth loopback server's request parsing.
- [x] Added an E2E smoke suite (`MusicWidgetUITests.xcodeproj`, real
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
