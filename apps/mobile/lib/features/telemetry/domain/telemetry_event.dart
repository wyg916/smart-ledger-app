const telemetryEventNames = <String>{
  'app_open',
  'session_start',
  'session_end',
  'home_viewed',
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
};

const telemetryPropertyNames = <String>{
  'entry_method',
  'result',
  'failure_kind',
  'view_mode',
  'message_count',
  'has_image',
};

final class QueuedTelemetryEvent {
  const QueuedTelemetryEvent({
    required this.eventId,
    required this.name,
    required this.sessionId,
    required this.occurredAtUtc,
    required this.properties,
    required this.attemptCount,
  });

  final String eventId;
  final String name;
  final String sessionId;
  final DateTime occurredAtUtc;
  final Map<String, Object> properties;
  final int attemptCount;

  Map<String, Object> toJson() => {
    'event_id': eventId,
    'event_name': name,
    'session_id': sessionId,
    'occurred_at': occurredAtUtc.toIso8601String(),
    'schema_version': 1,
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
