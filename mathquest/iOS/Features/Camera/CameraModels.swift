import Foundation

// MARK: - Request Models

struct SolveRequest: Encodable {
    let imageBase64: String
    let mediaType: String

    enum CodingKeys: String, CodingKey {
        case imageBase64 = "image_base64"
        case mediaType = "media_type"
    }
}

struct TranslateSolutionRequest: Encodable {
    let problem: String
    let solution: String
    let steps: [String]
    let rawLatex: String
    let difficultyLevel: String
    let detectedLanguage: String
    let targetLanguage: String

    enum CodingKeys: String, CodingKey {
        case problem, solution, steps
        case rawLatex = "raw_latex"
        case difficultyLevel = "difficulty_level"
        case detectedLanguage = "detected_language"
        case targetLanguage = "target_language"
    }
}

// MARK: - Response Models

struct SolveResponse: Decodable {
    let id: Int
    let problem: String
    let solution: String
    let steps: [String]
    let rawLatex: String
    let difficultyLevel: String
    let detectedLanguage: String
    let usesRemainingToday: Int

    enum CodingKeys: String, CodingKey {
        case id, problem, solution, steps
        case rawLatex = "raw_latex"
        case difficultyLevel = "difficulty_level"
        case detectedLanguage = "detected_language"
        case usesRemainingToday = "uses_remaining_today"
    }

    init(
        id: Int,
        problem: String,
        solution: String,
        steps: [String],
        rawLatex: String,
        difficultyLevel: String,
        detectedLanguage: String,
        usesRemainingToday: Int
    ) {
        self.id = id
        self.problem = problem
        self.solution = solution
        self.steps = steps
        self.rawLatex = rawLatex
        self.difficultyLevel = difficultyLevel
        self.detectedLanguage = detectedLanguage
        self.usesRemainingToday = usesRemainingToday
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        problem = try container.decodeIfPresent(String.self, forKey: .problem) ?? ""
        solution = try container.decodeIfPresent(String.self, forKey: .solution) ?? ""
        steps = try container.decodeIfPresent([String].self, forKey: .steps) ?? []
        rawLatex = try container.decodeIfPresent(String.self, forKey: .rawLatex) ?? ""
        difficultyLevel = try container.decodeIfPresent(String.self, forKey: .difficultyLevel) ?? "unknown"
        detectedLanguage = try container.decodeIfPresent(String.self, forKey: .detectedLanguage) ?? "unknown"
        usesRemainingToday = try container.decodeIfPresent(Int.self, forKey: .usesRemainingToday) ?? 0
    }

    func replacingContent(with translated: TranslateSolutionResponse) -> SolveResponse {
        SolveResponse(
            id: id,
            problem: translated.problem,
            solution: translated.solution,
            steps: translated.steps,
            rawLatex: translated.rawLatex,
            difficultyLevel: translated.difficultyLevel,
            detectedLanguage: translated.detectedLanguage,
            usesRemainingToday: usesRemainingToday
        )
    }
}

struct TranslateSolutionResponse: Decodable {
    let problem: String
    let solution: String
    let steps: [String]
    let rawLatex: String
    let difficultyLevel: String
    let detectedLanguage: String

    enum CodingKeys: String, CodingKey {
        case problem, solution, steps
        case rawLatex = "raw_latex"
        case difficultyLevel = "difficulty_level"
        case detectedLanguage = "detected_language"
    }
}

struct HistoryResponse: Decodable {
    let history: [HistoryItem]
}

struct HistoryItem: Decodable, Identifiable {
    let id: Int
    let problem: String
    let solution: String
    let difficultyLevel: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, problem, solution
        case difficultyLevel = "difficulty_level"
        case createdAt = "created_at"
    }

    init(id: Int, problem: String, solution: String, difficultyLevel: String, createdAt: Date) {
        self.id = id
        self.problem = problem
        self.solution = solution
        self.difficultyLevel = difficultyLevel
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        problem = try container.decodeIfPresent(String.self, forKey: .problem) ?? ""
        solution = try container.decodeIfPresent(String.self, forKey: .solution) ?? ""
        difficultyLevel = try container.decodeIfPresent(String.self, forKey: .difficultyLevel) ?? "unknown"
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}

struct HistoryDetailResponse: Decodable, Identifiable {
    let id: Int
    let problem: String
    let solution: String
    let steps: [String]
    let rawLatex: String
    let difficultyLevel: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, problem, solution, steps
        case rawLatex = "raw_latex"
        case difficultyLevel = "difficulty_level"
        case createdAt = "created_at"
    }

    init(
        id: Int,
        problem: String,
        solution: String,
        steps: [String],
        rawLatex: String,
        difficultyLevel: String,
        createdAt: Date
    ) {
        self.id = id
        self.problem = problem
        self.solution = solution
        self.steps = steps
        self.rawLatex = rawLatex
        self.difficultyLevel = difficultyLevel
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        problem = try container.decodeIfPresent(String.self, forKey: .problem) ?? ""
        solution = try container.decodeIfPresent(String.self, forKey: .solution) ?? ""
        steps = try container.decodeIfPresent([String].self, forKey: .steps) ?? []
        rawLatex = try container.decodeIfPresent(String.self, forKey: .rawLatex) ?? ""
        difficultyLevel = try container.decodeIfPresent(String.self, forKey: .difficultyLevel) ?? "unknown"
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}

struct StatusResponse: Decodable {
    let dailyLimit: Int
    let usedToday: Int
    let remaining: Int

    enum CodingKeys: String, CodingKey {
        case dailyLimit = "daily_limit"
        case usedToday = "used_today"
        case remaining
    }

    init(dailyLimit: Int, usedToday: Int, remaining: Int) {
        self.dailyLimit = dailyLimit
        self.usedToday = usedToday
        self.remaining = remaining
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dailyLimit = try container.decodeIfPresent(Int.self, forKey: .dailyLimit) ?? 0
        usedToday = try container.decodeIfPresent(Int.self, forKey: .usedToday) ?? 0
        remaining = try container.decodeIfPresent(Int.self, forKey: .remaining) ?? 0
    }
}

// MARK: - Camera State

enum CameraState: Equatable {
    case idle
    case scanning
    case processing
    case success(SolveResponse)
    case error(String)

    static func == (lhs: CameraState, rhs: CameraState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.scanning, .scanning), (.processing, .processing):
            return true
        case (.success(let l), .success(let r)):
            return l.id == r.id
        case (.error(let l), .error(let r)):
            return l == r
        default:
            return false
        }
    }
}
