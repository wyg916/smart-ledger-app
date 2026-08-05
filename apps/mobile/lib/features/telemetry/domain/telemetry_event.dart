const telemetryEventNames = <String>{
  'app_open',
  'session_start',
  'session_end',
  'home_viewed',
  'login_page_viewed',
  'phone_login_started',
  'phone_login_cancelled',
  'phone_login_failed',
  'phone_login_succeeded',
  'wechat_login_started',
  'wechat_login_cancelled',
  'wechat_login_failed',
  'wechat_login_succeeded',
  'review_login_succeeded',
  'logout_completed',
  'account_deletion_started',
  'account_deletion_completed',
  'transaction_created',
  'transaction_edited',
  'transaction_deleted',
  'quick_category_used',
  'natural_language_entry_submitted',
  'natural_language_entry_confirmed',
  'natural_language_entry_cancelled',
  'analytics_viewed',
  'budget_viewed',
  'ai_chat_submitted',
  'ai_chat_success',
  'ai_chat_failed',
  'image_analysis_submitted',
  'image_analysis_success',
  'image_analysis_failed',
  'monthly_summary_submitted',
  'monthly_summary_success',
  'monthly_summary_failed',
  'budget_review_submitted',
  'budget_review_success',
  'budget_review_failed',
  'financial_plan_submitted',
  'financial_plan_success',
  'financial_plan_failed',
  'ai_parse_transaction_submitted',
  'ai_parse_transaction_success',
  'ai_parse_transaction_failed',
};

const telemetryPropertyNames = <String>{
  'entry_method',
  'result',
  'failure_kind',
  'view_mode',
  'message_count',
  'has_image',
  'feature',
  'network_type',
};

final class QueuedTelemetryEvent {
  const QueuedTelemetryEvent({
    required this.eventId,
    required this.name,
    required this.sessionId,
    required this.occurredAtUtc,
    required this.properties,
    required this.attemptCount,
    required this.schemaVersion,
    required this.userId,
    required this.identityScope,
  });

  final String eventId;
  final String name;
  final String sessionId;
  final DateTime occurredAtUtc;
  final Map<String, Object> properties;
  final int attemptCount;
  final int schemaVersion;
  final String? userId;
  final String identityScope;

  Map<String, Object> toJson() => {
    'event_id': eventId,
    'event_name': name,
    'session_id': sessionId,
    'occurred_at': occurredAtUtc.toIso8601String(),
    'schema_version': schemaVersion,
    'user_id': ?userId,
    'identity_scope': identityScope,
    'properties': properties,
  };
}

void validateTelemetryEvent(String name, Map<String, Object> properties) {
  if (!telemetryEventNames.contains(name)) {
    throw ArgumentError.value(name, 'name', 'Event is not whitelisted');
  }
  if (properties.keys.any((key) => !telemetryPropertyNames.contains(key))) {
    throw ArgumentError('Telemetry properties contain a forbidden key');
  }
  for (final value in properties.values) {
    if (value is! String && value is! bool && value is! int) {
      throw ArgumentError('Telemetry properties must be scalar');
    }
    if (value is String && value.length > 40) {
      throw ArgumentError('Telemetry property value is too long');
    }
  }
}
