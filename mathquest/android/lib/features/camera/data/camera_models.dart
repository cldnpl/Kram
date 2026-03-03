// Manual models without code generation

class SolveRequest {
  final String imageBase64;
  final String mediaType;

  const SolveRequest({
    required this.imageBase64,
    required this.mediaType,
  });

  Map<String, dynamic> toJson() => {
        'image_base64': imageBase64,
        'media_type': mediaType,
      };
}

class SolveResponse {
  final int id;
  final String problem;
  final String solution;
  final List<String> steps;
  final String rawLatex;
  final String difficultyLevel;
  final int usesRemainingToday;

  const SolveResponse({
    required this.id,
    required this.problem,
    required this.solution,
    required this.steps,
    required this.rawLatex,
    required this.difficultyLevel,
    required this.usesRemainingToday,
  });

  factory SolveResponse.fromJson(Map<String, dynamic> json) {
    return SolveResponse(
      id: json['id'] as int,
      problem: json['problem'] as String,
      solution: json['solution'] as String,
      steps: (json['steps'] as List<dynamic>).map((e) => e as String).toList(),
      rawLatex: json['raw_latex'] as String? ?? '',
      difficultyLevel: json['difficulty_level'] as String? ?? 'unknown',
      usesRemainingToday: json['uses_remaining_today'] as int,
    );
  }
}

class HistoryResponse {
  final List<HistoryItem> history;

  const HistoryResponse({required this.history});

  factory HistoryResponse.fromJson(Map<String, dynamic> json) {
    return HistoryResponse(
      history: (json['history'] as List<dynamic>)
          .map((e) => HistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class HistoryItem {
  final int id;
  final String problem;
  final String solution;
  final String difficultyLevel;
  final DateTime createdAt;

  const HistoryItem({
    required this.id,
    required this.problem,
    required this.solution,
    required this.difficultyLevel,
    required this.createdAt,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] as int,
      problem: json['problem'] as String,
      solution: json['solution'] as String,
      difficultyLevel: json['difficulty_level'] as String? ?? 'unknown',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class HistoryDetailResponse {
  final int id;
  final String problem;
  final String solution;
  final List<String> steps;
  final String rawLatex;
  final String difficultyLevel;
  final DateTime createdAt;

  const HistoryDetailResponse({
    required this.id,
    required this.problem,
    required this.solution,
    required this.steps,
    required this.rawLatex,
    required this.difficultyLevel,
    required this.createdAt,
  });

  factory HistoryDetailResponse.fromJson(Map<String, dynamic> json) {
    return HistoryDetailResponse(
      id: json['id'] as int,
      problem: json['problem'] as String,
      solution: json['solution'] as String,
      steps: (json['steps'] as List<dynamic>).map((e) => e as String).toList(),
      rawLatex: json['raw_latex'] as String? ?? '',
      difficultyLevel: json['difficulty_level'] as String? ?? 'unknown',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class StatusResponse {
  final int dailyLimit;
  final int usedToday;
  final int remaining;

  const StatusResponse({
    required this.dailyLimit,
    required this.usedToday,
    required this.remaining,
  });

  factory StatusResponse.fromJson(Map<String, dynamic> json) {
    return StatusResponse(
      dailyLimit: json['daily_limit'] as int,
      usedToday: json['used_today'] as int,
      remaining: json['remaining'] as int,
    );
  }
}

enum CameraState {
  idle,
  scanning,
  processing,
  success,
  error,
}
