import CryptoKit
import XCTest
@testable import MusicWidget

final class SpotifyAuthManagerTests: XCTestCase {
    // MARK: - randomURLSafeString

    func testRandomURLSafeStringHasNoBase64PaddingOrUnsafeChars() {
        let value = SpotifyAuthManager.randomURLSafeString(length: 64)
        XCTAssertFalse(value.contains("+"))
        XCTAssertFalse(value.contains("/"))
        XCTAssertFalse(value.contains("="))
    }

    func testRandomURLSafeStringIsNotTriviallyPredictable() {
        let first = SpotifyAuthManager.randomURLSafeString(length: 32)
        let second = SpotifyAuthManager.randomURLSafeString(length: 32)
        XCTAssertNotEqual(first, second)
    }

    func testRandomURLSafeStringLengthGrowsWithByteCount() {
        let short = SpotifyAuthManager.randomURLSafeString(length: 8)
        let long = SpotifyAuthManager.randomURLSafeString(length: 64)
        XCTAssertLessThan(short.count, long.count)
    }

    // MARK: - codeChallenge

    func testCodeChallengeMatchesManuallyComputedSHA256() {
        let verifier = "test-verifier-value"
        let expectedDigest = SHA256.hash(data: Data(verifier.utf8))
        let expected = Data(expectedDigest)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        XCTAssertEqual(SpotifyAuthManager.codeChallenge(for: verifier), expected)
    }

    func testCodeChallengeIsDeterministic() {
        let verifier = "same-verifier-every-time"
        XCTAssertEqual(
            SpotifyAuthManager.codeChallenge(for: verifier),
            SpotifyAuthManager.codeChallenge(for: verifier)
        )
    }

    // MARK: - formEncode

    func testFormEncodeJoinsWithAmpersand() {
        let body = SpotifyAuthManager.formEncode(["grant_type": "refresh_token"])
        XCTAssertEqual(String(data: body, encoding: .utf8), "grant_type=refresh_token")
    }

    func testFormEncodePercentEscapesReservedCharacters() {
        let body = SpotifyAuthManager.formEncode(["redirect_uri": "http://127.0.0.1:8888/callback"])
        let encoded = String(data: body, encoding: .utf8) ?? ""
        XCTAssertFalse(encoded.contains("://"))
        XCTAssertTrue(encoded.hasPrefix("redirect_uri="))
    }
}
