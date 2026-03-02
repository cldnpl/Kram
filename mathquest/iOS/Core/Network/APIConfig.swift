import Foundation

enum APIConfig {
    /// Backend base URL (localhost when the server runs on your Mac).
    static let baseURLString = "http://localhost:8080/api"
    
    static var baseURL: URL {
        URL(string: baseURLString)!
    }
}
