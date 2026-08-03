enum AiInsightType { positive, warning, neutral }

final class AiInsight {
  const AiInsight({
    required this.type,
    required this.title,
    required this.detail,
    required this.evidence,
  });

  final AiInsightType type;
  final String title;
  final String detail;
  final String evidence;
}

final class AiAction {
  const AiAction({
    required this.priority,
    required this.title,
    required this.detail,
  });

  final int priority;
  final String title;
  final String detail;
}

final class AiResult {
  const AiResult({
    required this.title,
    required this.summary,
    required this.insights,
    required this.actions,
    required this.riskTips,
    required this.disclaimer,
  });

  final String title;
  final String summary;
  final List<AiInsight> insights;
  final List<AiAction> actions;
  final List<String> riskTips;
  final String disclaimer;
}

enum AiFailureKind {
  offline,
  timeout,
  rateLimited,
  invalidResponse,
  disabled,
  unavailable,
}

final class AiFailure implements Exception {
  const AiFailure(this.kind, this.message);

  final AiFailureKind kind;
  final String message;
}
