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

    init(baseURL: URL = APIConfig.baseURL) {
        self.baseURL = baseURL
    }

    func setToken(_ token: String?) {
        self.token = token
    }

    func request<T: Decodable>(_ path: String, method: String = "GET", body: Data? = nil) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.timeoutInterval = 15
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if path.contains("camera"), let username = UserDefaults.standard.string(forKey: "profile_username"), !username.isEmpty {
            request.setValue(username, forHTTPHeaderField: "X-Username")
        }
        request.setValue(SubscriptionTier.current.rawValue, forHTTPHeaderField: "X-Subscription-Tier")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(http.statusCode) else {
            let responseBody = String(data: data, encoding: .utf8) ?? ""
            throw APIError.httpStatus(code: http.statusCode, body: responseBody)
        }

        do {
            return try Self.decoder.decode(T.self, from: data)
        } catch {
            let responseBody = String(data: data, encoding: .utf8) ?? "<non-utf8-payload>"
            throw APIError.decodingFailed(underlying: error, body: responseBody)
        }
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
