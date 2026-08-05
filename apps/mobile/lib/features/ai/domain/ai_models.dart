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
  quotaExceeded,
  rateLimited,
  invalidResponse,
  disabled,
  unavailable,
}

final class AiFailure implements Exception {
  const AiFailure(this.kind, this.message, {this.quota});

  final AiFailureKind kind;
  final String message;
  final AiQuotaStatus? quota;
}

final class AiQuotaStatus {
  const AiQuotaStatus({
    required this.planCode,
    required this.dailyLimit,
    required this.dailyUsed,
    required this.dailyRemaining,
    required this.weeklyLimit,
    required this.weeklyUsed,
    required this.weeklyRemaining,
    required this.nextDailyResetAt,
    required this.nextWeeklyResetAt,
    required this.userTimeZone,
  });

  factory AiQuotaStatus.fromJson(Map<String, Object?> json) => AiQuotaStatus(
    planCode: json['plan_code']! as String,
    dailyLimit: json['daily_limit']! as int,
    dailyUsed: json['daily_used']! as int,
    dailyRemaining: json['daily_remaining']! as int,
    weeklyLimit: json['weekly_limit']! as int,
    weeklyUsed: json['weekly_used']! as int,
    weeklyRemaining: json['weekly_remaining']! as int,
    nextDailyResetAt: DateTime.parse(
      json['next_daily_reset_at']! as String,
    ).toUtc(),
    nextWeeklyResetAt: DateTime.parse(
      json['next_weekly_reset_at']! as String,
    ).toUtc(),
    userTimeZone: json['user_timezone']! as String,
  );

  final String planCode;
  final int dailyLimit;
  final int dailyUsed;
  final int dailyRemaining;
  final int weeklyLimit;
  final int weeklyUsed;
  final int weeklyRemaining;
  final DateTime nextDailyResetAt;
  final DateTime nextWeeklyResetAt;
  final String userTimeZone;

  bool get isExhausted => dailyRemaining == 0 || weeklyRemaining == 0;

  String get exhaustedMessage =>
      dailyRemaining == 0 ? '今日AI次数已用完，明日恢复。' : '本周AI次数已用完，下周一恢复。';
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
