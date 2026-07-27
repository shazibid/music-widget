import XCTest

/// Polls `condition` until it's true or `timeout` elapses. `PlayerViewModel`
/// dispatches its polling work onto `Task.detached` and hops back to the
/// main actor, so tests need to wait for that round trip to settle instead
/// of asserting immediately after calling `refresh()`/etc.
@MainActor
func waitUntil(
    timeout: TimeInterval = 2,
    file: StaticString = #filePath,
    line: UInt = #line,
    _ condition: @MainActor () -> Bool
) async {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() {
        if Date() > deadline {
            XCTFail("Timed out waiting for condition", file: file, line: line)
            return
        }
        try? await Task.sleep(nanoseconds: 20_000_000)
    }
}
