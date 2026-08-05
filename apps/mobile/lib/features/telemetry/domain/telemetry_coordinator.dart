import 'dart:async';

import 'package:smart_ledger/features/identity/domain/anonymous_identity.dart';
import 'package:smart_ledger/features/telemetry/data/analytics_queue_repository.dart';
import 'package:smart_ledger/features/telemetry/data/telemetry_api_client.dart';

abstract interface class TelemetryRecorder {
  Future<void> record(String name, {Map<String, Object> properties = const {}});

  Future<void> start();
  Future<void> end();
  Future<void> flush();
}

final class TelemetryCoordinator implements TelemetryRecorder {
  TelemetryCoordinator(
    this._queue,
    this._client,
    this._identityService,
    this._identity,
    this._userAccessToken,
    this._userId,
  );

  final AnalyticsQueueRepository _queue;
  final TelemetryApiClient _client;
  final AnonymousIdentityService _identityService;
  AnonymousIdentity _identity;
  final String _userAccessToken;
  final String _userId;
  bool _flushing = false;
  bool _sessionStarted = false;
  bool _registeredForUser = false;

  @override
  Future<void> record(
    String name, {
    Map<String, Object> properties = const {},
  }) async {
    await _queue.enqueue(
      name: name,
      sessionId: _identity.sessionId,
      userId: _userId,
      identityScope: 'authenticated',
      schemaVersion: 2,
      properties: properties,
    );
    unawaited(flush());
  }

  @override
  Future<void> start() async {
    try {
      await _ensureSession();
    } catch (_) {
      // Offline-first: events remain local until a later flush can register.
    }
    await record('app_open');
    await record('session_start');
  }

  @override
  Future<void> end() async {
    await record('session_end');
    final token = _identity.installationToken;
    if (token != null && _sessionStarted) {
      try {
        await _client.endSession(_identity, token);
      } catch (_) {
        // The queued event still records the attempted session end.
      }
    }
    _sessionStarted = false;
  }

  @override
  Future<void> flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      final token = await _ensureSession();
      final events = await _queue.nextBatch();
      if (events.isEmpty) return;
      await _client.uploadBatch(events, token);
      await _queue.markUploaded(events.map((event) => event.eventId));
    } catch (_) {
      final events = await _queue.nextBatch();
      await _queue.markFailed(events);
    } finally {
      _flushing = false;
    }
  }

  Future<String> _ensureSession() async {
    var token = _identity.installationToken;
    if (!_registeredForUser) {
      token = await _client.registerInstallation(
        _identity,
        userAccessToken: _userAccessToken,
      );
      await _identityService.saveInstallationToken(token);
      _identity = _identity.copyWith(installationToken: token);
      _registeredForUser = true;
    }
    if (token == null) throw StateError('Telemetry installation token missing');
    if (!_sessionStarted) {
      await _client.startSession(_identity, token, userId: _userId);
      _sessionStarted = true;
    }
    return token;
  }
}
