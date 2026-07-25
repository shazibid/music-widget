import Foundation
import Network

/// The page shown in the browser tab after Spotify redirects back — self
/// contained (no external requests) since it's served straight off the
/// loopback socket.
private let callbackPageBody = """
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Music Widget</title>
<style>
  :root { color-scheme: dark; }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    background: radial-gradient(circle at 50% 0%, #1a2a1f 0%, #0d0f0d 60%);
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
    color: #f5f5f5;
  }
  .card { text-align: center; padding: 48px 40px; max-width: 360px; }
  .check {
    width: 64px;
    height: 64px;
    margin: 0 auto 24px;
    border-radius: 50%;
    background: #1DB954;
    display: flex;
    align-items: center;
    justify-content: center;
    animation: pop 0.4s ease-out;
  }
  .check svg { width: 32px; height: 32px; }
  h1 { font-size: 22px; margin: 0 0 8px; font-weight: 600; }
  p { font-size: 15px; color: #a7a7a7; margin: 0 0 4px; line-height: 1.5; }
  .countdown { font-size: 13px; color: #6a6a6a; }
  @keyframes pop {
    0% { transform: scale(0.6); opacity: 0; }
    100% { transform: scale(1); opacity: 1; }
  }
</style>
</head>
<body>
  <div class="card">
    <div class="check">
      <svg viewBox="0 0 24 24" fill="none" stroke="#0d0f0d" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
        <polyline points="4 12 9 18 20 6"></polyline>
      </svg>
    </div>
    <h1>You're connected</h1>
    <p>Music Widget is now linked to your Spotify account.</p>
    <p class="countdown" id="countdown">This tab will auto-close in 10s\u{2026}</p>
  </div>
  <script>
    var seconds = 10;
    var label = document.getElementById('countdown');
    var timer = setInterval(function () {
      seconds -= 1;
      if (seconds <= 0) {
        clearInterval(timer);
        window.close();
        label.textContent = 'You can close this tab now.';
        return;
      }
      label.textContent = 'This tab will auto-close in ' + seconds + 's…';
    }, 1000);
  </script>
</body>
</html>
"""

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

            let response = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: \(callbackPageBody.utf8.count)\r\nConnection: close\r\n\r\n\(callbackPageBody)"
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
