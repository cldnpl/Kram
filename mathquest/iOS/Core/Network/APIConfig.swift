import Foundation

// Device e simulatore: stesso URL. Modifica macHost se il Mac ha un altro IP (es. 10.20.54.26).
enum APIConfig {
    private static let macHost = "10.20.54.26"
    private static let apiPath = "8080/api"

    /// Usato da tutte le richieste API (lessons, coins, ecc.). Nessun #if simulator/device.
    static var baseURLString: String {
        "http://\(macHost):\(apiPath)"
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
