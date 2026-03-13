import Foundation

enum APIConfig {
    private static let productionBaseURLString = "https://kram.islamov.online/api"
    private static let localSimulatorBaseURLString = "http://127.0.0.1:8080/api"

    /// Usato da tutte le richieste API (lessons, coins, ecc.).
    static var baseURLString: String {
#if DEBUG
        if let override = Bundle.main.object(forInfoDictionaryKey: "KRAM_API_BASE_URL") as? String,
           !override.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return override
        }
        if let override = ProcessInfo.processInfo.environment["KRAM_API_BASE_URL"],
           !override.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return override
        }
#if targetEnvironment(simulator)
        return localSimulatorBaseURLString
#else
        return productionBaseURLString
#endif
#else
        return productionBaseURLString
#endif
    }
    
    static var baseURL: URL {
        URL(string: baseURLString)!
    }

    /// Base URL del server senza /api (per risorse pubbliche come immagini/diagrammi, che non richiedono auth).
    static var serverBaseURLString: String {
        let api = baseURLString
        if api.hasSuffix("/api") {
            return String(api.dropLast(4))
        }
        if let idx = api.lastIndex(of: "/"), api[idx...] == "/api" {
            return String(api[..<idx])
        }
        return api
    }
}

enum AppLinkRoute: Equatable {
    case sharedSolution(token: String)
}

enum AppLinks {
    static let customScheme = "kram"
    private static let webPathPrefix = "/s/"

    static func webSharedSolutionURL(token: String) -> URL? {
        guard !token.isEmpty else { return nil }
        return URL(string: "\(APIConfig.serverBaseURLString)\(webPathPrefix)\(token)")
    }

    static func appSharedSolutionURL(token: String) -> URL? {
        guard !token.isEmpty else { return nil }
        return URL(string: "\(customScheme)://solution/\(token)")
    }

    static func route(from url: URL) -> AppLinkRoute? {
        let token: String?
        if url.scheme?.lowercased() == customScheme {
            if url.host?.lowercased() == "solution" {
                token = pathToken(from: url.path)
            } else {
                token = nil
            }
        } else if url.scheme?.lowercased() == "https" || url.scheme?.lowercased() == "http" {
            let allowedHost = URL(string: APIConfig.serverBaseURLString)?.host?.lowercased()
            let incomingHost = url.host?.lowercased()
            if allowedHost != nil, allowedHost != incomingHost {
                token = nil
            } else {
                token = tokenFromWebPath(url.path)
            }
        } else {
            token = nil
        }

        guard let token, isValid(token: token) else {
            return nil
        }
        return .sharedSolution(token: token)
    }

    private static func tokenFromWebPath(_ path: String) -> String? {
        guard path.hasPrefix(webPathPrefix) else {
            return nil
        }
        let token = String(path.dropFirst(webPathPrefix.count))
        return token.isEmpty ? nil : token
    }

    private static func pathToken(from path: String) -> String? {
        let normalized = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return normalized.isEmpty ? nil : normalized
    }

    private static func isValid(token: String) -> Bool {
        guard (10...64).contains(token.count) else {
            return false
        }
        return token.allSatisfy { ch in
            ch.isLetter || ch.isNumber || ch == "-" || ch == "_"
        }
    }
}

extension Notification.Name {
    static let appDidReceiveExternalURL = Notification.Name("appDidReceiveExternalURL")
}
