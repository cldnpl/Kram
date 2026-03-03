import Foundation

enum APIConfig {
    /// Optional Info.plist key. Set this to your Mac LAN URL for real-device runs,
    /// e.g. `http://192.168.1.149:8080/api`.
    private static let infoPlistBaseURLKey = "APIBaseURL"

    static var baseURLString: String {
        if let configuredValue = Bundle.main.object(forInfoDictionaryKey: infoPlistBaseURLKey) as? String {
            let trimmedValue = configuredValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedValue.isEmpty {
                return trimmedValue
            }
        }

        #if targetEnvironment(simulator)
        return "http://127.0.0.1:8080/api"
        #else
        // Default for this machine's current LAN IP. Update if your IP changes.
        return "http://192.168.1.149:8080/api"
        #endif
    }
    
    static var baseURL: URL {
        URL(string: baseURLString)!
    }
}
