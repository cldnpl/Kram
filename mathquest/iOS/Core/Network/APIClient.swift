import Foundation

actor APIClient {
    private let baseURL: URL
    private var token: String?
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            let withFractionalSeconds = ISO8601DateFormatter()
            withFractionalSeconds.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            let withoutFractionalSeconds = ISO8601DateFormatter()
            withoutFractionalSeconds.formatOptions = [.withInternetDateTime]

            if let date = withFractionalSeconds.date(from: value) ??
                withoutFractionalSeconds.date(from: value) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO-8601 date: \(value)"
            )
        }

        return decoder
    }()
    private let maxRetries = 3

    init(baseURL: URL = APIConfig.baseURL) {
        self.baseURL = baseURL
    }

    private func makeURL(for path: String) throws -> URL {
        if let absoluteURL = URL(string: path), absoluteURL.scheme != nil {
            return absoluteURL
        }

        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return baseURL
        }

        let parts = trimmed.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
        let rawPath = String(parts[0])
        let normalizedPath = rawPath.hasPrefix("/") ? String(rawPath.dropFirst()) : rawPath
        let query = parts.count > 1 ? String(parts[1]) : nil

        var url = baseURL
        if !normalizedPath.isEmpty {
            url = baseURL.appendingPathComponent(normalizedPath)
        }

        guard let query, !query.isEmpty else {
            return url
        }

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        components.percentEncodedQuery = query
        guard let resolvedURL = components.url else {
            throw URLError(.badURL)
        }
        return resolvedURL
    }

    func setToken(_ token: String?) {
        self.token = token
    }

    func request<T: Decodable>(_ path: String, method: String = "GET", body: Data? = nil) async throws -> T {
        let url = try makeURL(for: path)
        let base = baseURL.absoluteString.hasSuffix("/") ? baseURL : URL(string: baseURL.absoluteString + "/")!
        guard let url = URL(string: path, relativeTo: base) else {
            throw URLError(.badURL)
        }

        var lastError: Error?
        for attempt in 1...maxRetries {
            var request = URLRequest(url: url)
            request.httpMethod = method
            request.timeoutInterval = 30
            #if DEBUG
            print("[APIClient] \(method) \(url.absoluteString) [attempt \(attempt)/\(maxRetries)]")
            #endif
            if let token = token {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            if path.contains("camera"), let username = UserDefaults.standard.string(forKey: "profile_username"), !username.isEmpty {
                request.setValue(username, forHTTPHeaderField: "X-Username")
            }
            request.setValue(SubscriptionTier.current.rawValue, forHTTPHeaderField: "X-Subscription-Tier")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }

                if (200...299).contains(http.statusCode) {
                    do {
                        return try Self.decoder.decode(T.self, from: data)
                    } catch {
                        let responseBody = String(data: data, encoding: .utf8) ?? "<non-utf8-payload>"
                        throw APIError.decodingFailed(underlying: error, body: responseBody)
                    }
                }

                let responseBody = String(data: data, encoding: .utf8) ?? ""
                let httpError = APIError.httpStatus(code: http.statusCode, body: responseBody)
                if shouldRetry(statusCode: http.statusCode, method: method), attempt < maxRetries {
                    try await Task.sleep(nanoseconds: UInt64(attempt) * 500_000_000) // 0.5s, 1s, 1.5s
                    continue
                }
                throw httpError
            } catch {
                lastError = error
                if shouldRetry(error: error, method: method), attempt < maxRetries {
                    try await Task.sleep(nanoseconds: UInt64(attempt) * 500_000_000)
                    continue
                }
                throw error
            }
        }

        throw lastError ?? URLError(.unknown)
    }

    private func shouldRetry(statusCode: Int, method: String) -> Bool {
        guard method.uppercased() == "GET" else { return false }
        return statusCode == 502 || statusCode == 503 || statusCode == 504
    }

    private func shouldRetry(error: Error, method: String) -> Bool {
        guard method.uppercased() == "GET" else { return false }
        let nsError = error as NSError
        if nsError.domain != NSURLErrorDomain {
            return false
        }
        return nsError.code == URLError.networkConnectionLost.rawValue ||
            nsError.code == URLError.timedOut.rawValue ||
            nsError.code == URLError.cannotConnectToHost.rawValue ||
            nsError.code == URLError.cannotFindHost.rawValue
    }

    enum APIError: LocalizedError {
        case httpStatus(code: Int, body: String)
        case decodingFailed(underlying: Error, body: String)

        var errorDescription: String? {
            switch self {
            case .httpStatus(let code, let body):
                if body.isEmpty {
                    return "Request failed with status code \(code)"
                }
                return "Request failed with status code \(code): \(body)"
            case .decodingFailed(let underlying, let body):
                if body.isEmpty {
                    return "Failed to decode response: \(underlying.localizedDescription)"
                }
                return "Failed to decode response: \(underlying.localizedDescription). Response body: \(body)"
            }
        }
    }
}
