import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:smart_ledger/features/identity/domain/anonymous_identity.dart';
import 'package:smart_ledger/features/telemetry/domain/telemetry_event.dart';

abstract interface class TelemetryApiClient {
  Future<String> registerInstallation(AnonymousIdentity identity);
  Future<void> startSession(AnonymousIdentity identity, String token);
  Future<void> endSession(AnonymousIdentity identity, String token);
  Future<void> uploadBatch(List<QueuedTelemetryEvent> events, String token);
}

final class HttpTelemetryApiClient implements TelemetryApiClient {
  const HttpTelemetryApiClient(this._client, this._baseUrl);

  final http.Client _client;
  final String _baseUrl;

  @override
  Future<String> registerInstallation(AnonymousIdentity identity) async {
    final response = await _post('/api/v1/telemetry/installations', {
      'installation_id': identity.installationId,
      'anonymous_actor_id': identity.actorId,
      'platform': Platform.isAndroid ? 'android' : 'ios',
      'app_version': '0.1.0',
    });
    return (jsonDecode(response.body)
            as Map<String, Object?>)['installation_token']!
        as String;
  }

  @override
  Future<void> startSession(AnonymousIdentity identity, String token) =>
      _post('/api/v1/telemetry/sessions/start', {
        'session_id': identity.sessionId,
        'started_at': DateTime.now().toUtc().toIso8601String(),
      }, token: token);

  @override
  Future<void> endSession(AnonymousIdentity identity, String token) =>
      _post('/api/v1/telemetry/sessions/end', {
        'session_id': identity.sessionId,
        'ended_at': DateTime.now().toUtc().toIso8601String(),
      }, token: token);

  @override
  Future<void> uploadBatch(List<QueuedTelemetryEvent> events, String token) =>
      _post('/api/v1/telemetry/events/batch', {
        'events': events.map((event) => event.toJson()).toList(),
      }, token: token);

  Future<http.Response> _post(
    String path,
    Map<String, Object> body, {
    String? token,
  }) async {
    if (_baseUrl.isEmpty) throw const SocketException('API not configured');
    final response = await _client
        .post(
          Uri.parse('$_baseUrl$path'),
          headers: {
            'content-type': 'application/json',
            if (token != null) 'authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Telemetry request failed');
    }
    return response;
  }
}
