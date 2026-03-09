import Foundation

// Deployed server.
enum APIConfig {
    /// Usato da tutte le richieste API (lessons, coins, ecc.).
    static var baseURLString: String {
        "https://kram.islamov.online/api"
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
