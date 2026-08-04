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

enum ChatRole { user, assistant }

final class ChatMessage {
  const ChatMessage({required this.role, required this.content});

  final ChatRole role;
  final String content;

  Map<String, String> toJson() => {'role': role.name, 'content': content};
}

final class ChatResult {
  const ChatResult({
    required this.title,
    required this.answer,
    required this.insights,
    required this.actions,
    required this.warnings,
    required this.disclaimer,
  });

  final String title;
  final String answer;
  final List<String> insights;
  final List<String> actions;
  final List<String> warnings;
  final String disclaimer;
}

final class ImageAnalysisResult {
  const ImageAnalysisResult({
    required this.summary,
    required this.importantInformation,
    required this.riskFlags,
    required this.transactionDrafts,
    required this.disclaimer,
  });

  final String summary;
  final List<String> importantInformation;
  final List<String> riskFlags;
  final List<Map<String, Object?>> transactionDrafts;
  final String disclaimer;
}
