import Foundation

// MARK: - Graph Data

struct CriticalPoint: Decodable {
    let x: String
    let y: String
    let type: String // "maximum", "minimum", "inflection", "discontinuity"

    init(x: String, y: String, type: String) {
        self.x = x
        self.y = y
        self.type = type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        x = try container.decodeIfPresent(String.self, forKey: .x) ?? "0"
        y = try container.decodeIfPresent(String.self, forKey: .y) ?? "0"
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? "unknown"
    }

    enum CodingKeys: String, CodingKey {
        case x, y, type
    }
}

struct GraphData: Decodable {
    let isFunction: Bool
    let expression: String
    let variable: String
    let domain: String
    let range: String
    let intercepts: [String: [String]]
    let asymptotes: [String: [String]]
    let criticalPoints: [CriticalPoint]
    let behavior: [String: String]

    enum CodingKeys: String, CodingKey {
        case isFunction = "is_function"
        case expression, variable, domain, range, intercepts, asymptotes
        case criticalPoints = "critical_points"
        case behavior
    }

    init(
        isFunction: Bool, expression: String, variable: String,
        domain: String, range: String,
        intercepts: [String: [String]], asymptotes: [String: [String]],
        criticalPoints: [CriticalPoint], behavior: [String: String]
    ) {
        self.isFunction = isFunction
        self.expression = expression
        self.variable = variable
        self.domain = domain
        self.range = range
        self.intercepts = intercepts
        self.asymptotes = asymptotes
        self.criticalPoints = criticalPoints
        self.behavior = behavior
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isFunction = try container.decodeIfPresent(Bool.self, forKey: .isFunction) ?? false
        expression = try container.decodeIfPresent(String.self, forKey: .expression) ?? ""
        variable = try container.decodeIfPresent(String.self, forKey: .variable) ?? "x"
        domain = try container.decodeIfPresent(String.self, forKey: .domain) ?? ""
        range = try container.decodeIfPresent(String.self, forKey: .range) ?? ""
        intercepts = try container.decodeIfPresent([String: [String]].self, forKey: .intercepts) ?? [:]
        asymptotes = try container.decodeIfPresent([String: [String]].self, forKey: .asymptotes) ?? [:]
        criticalPoints = try container.decodeIfPresent([CriticalPoint].self, forKey: .criticalPoints) ?? []
        behavior = try container.decodeIfPresent([String: String].self, forKey: .behavior) ?? [:]
    }
}

// MARK: - Request Models

struct SolveRequest: Encodable {
    let imageBase64: String
    let mediaType: String
    let preferredLanguage: String

    enum CodingKeys: String, CodingKey {
        case imageBase64 = "image_base64"
        case mediaType = "media_type"
        case preferredLanguage = "preferred_language"
    }
}

struct TranslateSolutionRequest: Encodable {
    let problem: String
    let solution: String
    let steps: [String]
    let stepsDetail: [String]
    let rawLatex: String
    let difficultyLevel: String
    let detectedLanguage: String
    let shouldSaveToHistory: Bool
    let targetLanguage: String

    enum CodingKeys: String, CodingKey {
        case problem, solution, steps
        case stepsDetail = "steps_detail"
        case rawLatex = "raw_latex"
        case difficultyLevel = "difficulty_level"
        case detectedLanguage = "detected_language"
        case shouldSaveToHistory = "should_save_to_history"
        case targetLanguage = "target_language"
    }
}

// MARK: - Response Models

struct SolveResponse: Decodable {
    let id: Int
    let problem: String
    let solution: String
    let steps: [String]
    let stepsDetail: [String]
    let rawLatex: String
    let difficultyLevel: String
    let detectedLanguage: String
    let shouldSaveToHistory: Bool
    let usesRemainingToday: Int
    let graphData: GraphData?

    enum CodingKeys: String, CodingKey {
        case id, problem, solution, steps
        case stepsDetail = "steps_detail"
        case rawLatex = "raw_latex"
        case difficultyLevel = "difficulty_level"
        case detectedLanguage = "detected_language"
        case shouldSaveToHistory = "should_save_to_history"
        case usesRemainingToday = "uses_remaining_today"
        case graphData = "graph_data"
    }

    init(
        id: Int,
        problem: String,
        solution: String,
        steps: [String],
        stepsDetail: [String] = [],
        rawLatex: String,
        difficultyLevel: String,
        detectedLanguage: String,
        shouldSaveToHistory: Bool,
        usesRemainingToday: Int,
        graphData: GraphData? = nil
    ) {
        self.id = id
        self.problem = problem
        self.solution = solution
        self.steps = steps
        self.stepsDetail = stepsDetail
        self.rawLatex = rawLatex
        self.difficultyLevel = difficultyLevel
        self.detectedLanguage = detectedLanguage
        self.shouldSaveToHistory = shouldSaveToHistory
        self.usesRemainingToday = usesRemainingToday
        self.graphData = graphData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        problem = try container.decodeIfPresent(String.self, forKey: .problem) ?? ""
        solution = try container.decodeIfPresent(String.self, forKey: .solution) ?? ""
        steps = try container.decodeIfPresent([String].self, forKey: .steps) ?? []
        stepsDetail = try container.decodeIfPresent([String].self, forKey: .stepsDetail) ?? []
        rawLatex = try container.decodeIfPresent(String.self, forKey: .rawLatex) ?? ""
        difficultyLevel = try container.decodeIfPresent(String.self, forKey: .difficultyLevel) ?? "unknown"
        detectedLanguage = try container.decodeIfPresent(String.self, forKey: .detectedLanguage) ?? "unknown"
        shouldSaveToHistory = try container.decodeIfPresent(Bool.self, forKey: .shouldSaveToHistory)
            ?? Self.defaultShouldSaveToHistory(problem: problem, solution: solution, steps: steps)
        usesRemainingToday = try container.decodeIfPresent(Int.self, forKey: .usesRemainingToday) ?? 0
        graphData = try container.decodeIfPresent(GraphData.self, forKey: .graphData)
    }

    func replacingContent(with translated: TranslateSolutionResponse) -> SolveResponse {
        SolveResponse(
            id: id,
            problem: translated.problem,
            solution: translated.solution,
            steps: translated.steps,
            stepsDetail: translated.stepsDetail,
            rawLatex: translated.rawLatex,
            difficultyLevel: translated.difficultyLevel,
            detectedLanguage: translated.detectedLanguage,
            shouldSaveToHistory: translated.shouldSaveToHistory,
            usesRemainingToday: usesRemainingToday,
            graphData: graphData
        )
    }

    static func defaultShouldSaveToHistory(problem: String, solution: String, steps: [String]) -> Bool {
        let combined = ([problem, solution] + steps)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if combined.isEmpty {
            return false
        }

        let blockedPhrases = [
            "unable to parse problem from image",
            "could not parse model response",
            "could not parse structured response",
            "please retake the photo",
            "problem text could not be read clearly from image",
            "could not determine a final answer from the image",
            "image is unclear",
            "image is incomplete",
            "problem is unclear",
            "problem is incomplete",
            "unreadable"
        ]

        return !blockedPhrases.contains { combined.contains($0) }
    }
}

struct TranslateSolutionResponse: Decodable {
    let problem: String
    let solution: String
    let steps: [String]
    let stepsDetail: [String]
    let rawLatex: String
    let difficultyLevel: String
    let detectedLanguage: String
    let shouldSaveToHistory: Bool

    enum CodingKeys: String, CodingKey {
        case problem, solution, steps
        case stepsDetail = "steps_detail"
        case rawLatex = "raw_latex"
        case difficultyLevel = "difficulty_level"
        case detectedLanguage = "detected_language"
        case shouldSaveToHistory = "should_save_to_history"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        problem = try container.decodeIfPresent(String.self, forKey: .problem) ?? ""
        solution = try container.decodeIfPresent(String.self, forKey: .solution) ?? ""
        steps = try container.decodeIfPresent([String].self, forKey: .steps) ?? []
        stepsDetail = try container.decodeIfPresent([String].self, forKey: .stepsDetail) ?? []
        rawLatex = try container.decodeIfPresent(String.self, forKey: .rawLatex) ?? ""
        difficultyLevel = try container.decodeIfPresent(String.self, forKey: .difficultyLevel) ?? "unknown"
        detectedLanguage = try container.decodeIfPresent(String.self, forKey: .detectedLanguage) ?? "unknown"
        shouldSaveToHistory = try container.decodeIfPresent(Bool.self, forKey: .shouldSaveToHistory)
            ?? SolveResponse.defaultShouldSaveToHistory(problem: problem, solution: solution, steps: steps)
    }
}

struct HistoryResponse: Decodable {
    let history: [HistoryItem]
}

struct DeleteHistoryResponse: Decodable {
    let deleted: Bool
}

struct ShareHistoryResponse: Decodable {
    let token: String
    let id: Int?
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

struct SharedSolutionResponse: Decodable, Identifiable {
    let token: String
    let problem: String
    let solution: String
    let steps: [String]
    let rawLatex: String
    let difficultyLevel: String
    let createdAt: Date

    var id: String { token }

    enum CodingKeys: String, CodingKey {
        case token, problem, solution, steps
        case rawLatex = "raw_latex"
        case difficultyLevel = "difficulty_level"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        token = try container.decodeIfPresent(String.self, forKey: .token) ?? ""
        problem = try container.decodeIfPresent(String.self, forKey: .problem) ?? ""
        solution = try container.decodeIfPresent(String.self, forKey: .solution) ?? ""
        steps = try container.decodeIfPresent([String].self, forKey: .steps) ?? []
        rawLatex = try container.decodeIfPresent(String.self, forKey: .rawLatex) ?? ""
        difficultyLevel = try container.decodeIfPresent(String.self, forKey: .difficultyLevel) ?? "unknown"
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}

struct ShareCreateRequest: Encodable {
    let problem: String
    let solution: String
    let steps: [String]
    let rawLatex: String
    let difficultyLevel: String

    enum CodingKeys: String, CodingKey {
        case problem, solution, steps
        case rawLatex = "raw_latex"
        case difficultyLevel = "difficulty_level"
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
