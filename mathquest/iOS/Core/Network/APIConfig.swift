import Foundation

enum APIConfig {
    /// Optional Info.plist key. Set this to your Mac LAN URL for real-device runs,
    /// e.g. `http://192.168.1.149:8080/api`.
    private static let infoPlistBaseURLKey = "APIBaseURL"

    static var baseURLString: String {
        #if targetEnvironment(simulator)
        // Simulator: always use localhost (backend on same Mac).
        return "http://10.20.54.26:8080/api"
        #else
        if let configuredValue = Bundle.main.object(forInfoDictionaryKey: infoPlistBaseURLKey) as? String {
            let trimmedValue = configuredValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedValue.isEmpty {
                return trimmedValue
            }
        }
        return "http://10.20.54.26:8080/api"
        #endif
    }
    
    static var baseURL: URL {
        URL(string: baseURLString)!
    }

    /// Base URL del server senza /api (per risorse pubbliche come i diagrammi SVG, che non richiedono auth).
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
