import XCTest
@testable import Miniplayer

final class LoopbackCallbackServerTests: XCTestCase {
    private func rawRequest(_ requestLine: String) -> Data {
        Data("\(requestLine)\r\nHost: 127.0.0.1:8888\r\nUser-Agent: test\r\n\r\n".utf8)
    }

    func testParsesValidCallbackWithCodeAndState() {
        let data = rawRequest("GET /callback?code=abc123&state=xyz789 HTTP/1.1")
        let components = LoopbackCallbackServer.parseRequest(data)

        XCTAssertNotNil(components)
        let query = components?.queryItems ?? []
        XCTAssertEqual(query.first(where: { $0.name == "code" })?.value, "abc123")
        XCTAssertEqual(query.first(where: { $0.name == "state" })?.value, "xyz789")
    }

    func testParsesDenialResponseWithErrorParam() {
        let data = rawRequest("GET /callback?error=access_denied&state=xyz789 HTTP/1.1")
        let components = LoopbackCallbackServer.parseRequest(data)

        let query = components?.queryItems ?? []
        XCTAssertEqual(query.first(where: { $0.name == "error" })?.value, "access_denied")
    }

    func testReturnsNilForEmptyData() {
        XCTAssertNil(LoopbackCallbackServer.parseRequest(Data()))
    }

    func testReturnsNilForNonUTF8Data() {
        let invalid = Data([0xFF, 0xFE, 0xFD])
        XCTAssertNil(LoopbackCallbackServer.parseRequest(invalid))
    }

    func testReturnsNilForRequestLineMissingPath() {
        let data = Data("GET\r\n\r\n".utf8)
        XCTAssertNil(LoopbackCallbackServer.parseRequest(data))
    }

    func testParsesRootPathWithNoQuery() {
        let data = rawRequest("GET / HTTP/1.1")
        let components = LoopbackCallbackServer.parseRequest(data)
        XCTAssertEqual(components?.path, "/")
        XCTAssertNil(components?.queryItems)
    }
}
