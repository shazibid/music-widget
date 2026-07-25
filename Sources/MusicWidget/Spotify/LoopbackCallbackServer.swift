import Foundation
import Network

/// Catches exactly one OAuth redirect on the loopback interface, then tears
/// itself down — a full HTTP server would be overkill for a single
/// interactive login, and Spotify's redirect URI is registered as this exact
/// `http://127.0.0.1:<port>` address rather than a custom URL scheme, since
/// this app isn't packaged as a bundle LaunchServices could route one to.
enum LoopbackCallbackServer {
    enum ServerError: Error {
        case invalidPort
        case listenerFailed(Error)
        case invalidRequest
    }

    static func waitForCallback(port: UInt16) async throws -> URLComponents {
        guard let nwPort = NWEndpoint.Port(rawValue: port) else { throw ServerError.invalidPort }
        let listener = try NWListener(using: .tcp, on: nwPort)

        return try await withCheckedThrowingContinuation { continuation in
            let resume = ResumeOnce(continuation: continuation)

            listener.newConnectionHandler = { connection in
                connection.start(queue: .main)
                receive(on: connection) { result in
                    resume.callback(with: result)
                    listener.cancel()
                }
            }
            listener.stateUpdateHandler = { state in
                if case .failed(let error) = state {
                    resume.callback(with: .failure(ServerError.listenerFailed(error)))
                }
            }
            listener.start(queue: .main)
        }
    }

    private static func receive(on connection: NWConnection, completion: @escaping (Result<URLComponents, Error>) -> Void) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { data, _, _, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let data, let requestString = String(data: data, encoding: .utf8),
                  let requestLine = requestString.split(separator: "\r\n").first,
                  let path = requestLine.split(separator: " ").dropFirst().first,
                  let components = URLComponents(string: "http://127.0.0.1\(path)") else {
                completion(.failure(ServerError.invalidRequest))
                connection.cancel()
                return
            }

            let body = "<html><body>Spotify connected \u{2014} you can close this tab.</body></html>"
            let response = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: \(body.utf8.count)\r\nConnection: close\r\n\r\n\(body)"
            connection.send(content: Data(response.utf8), completion: .contentProcessed { _ in
                connection.cancel()
            })
            completion(.success(components))
        }
    }
}

/// `NWListener`'s handlers can fire from more than one queue in edge cases
/// (a failed state update racing a successful connection); this just makes
/// sure the continuation is resumed exactly once.
private final class ResumeOnce: @unchecked Sendable {
    private let lock = NSLock()
    private var didResume = false
    private let continuation: CheckedContinuation<URLComponents, Error>

    init(continuation: CheckedContinuation<URLComponents, Error>) {
        self.continuation = continuation
    }

    func callback(with result: Result<URLComponents, Error>) {
        lock.lock()
        defer { lock.unlock() }
        guard !didResume else { return }
        didResume = true
        continuation.resume(with: result)
    }
}
