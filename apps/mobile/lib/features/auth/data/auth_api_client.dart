import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:smart_ledger/features/auth/domain/auth_session.dart';

final class AuthApiException implements Exception {
  const AuthApiException(this.code, {this.statusCode, this.isNetwork = false});

  final String code;
  final int? statusCode;
  final bool isNetwork;
}

abstract interface class AuthApiClient {
  Future<AuthSession> phoneLogin({
    required String token,
    required String installationId,
    required String timezone,
    String? carrier,
  });
  Future<String> createWechatState(String installationId);
  Future<AuthSession> wechatLogin({
    required String code,
    required String state,
    required String installationId,
    required String timezone,
  });
  Future<AuthSession> reviewLogin({
    required String username,
    required String password,
    required String installationId,
    required String timezone,
  });
  Future<AuthSession> refresh(String refreshToken);
  Future<List<String>> me(String accessToken);
  Future<void> logout(String accessToken, String refreshToken);
  Future<String> requestDeletion({
    required String accessToken,
    required String idempotencyKey,
    required String localDataAction,
  });
  Future<void> confirmDeletion({
    required String accessToken,
    required String requestId,
  });
}

final class HttpAuthApiClient implements AuthApiClient {
  const HttpAuthApiClient(this._client, this._baseUrl);

  final http.Client _client;
  final String _baseUrl;

  @override
  Future<AuthSession> phoneLogin({
    required String token,
    required String installationId,
    required String timezone,
    String? carrier,
  }) async => _session(
    await _post('/api/v1/auth/phone/one-click', {
      'token': token,
      'installation_id': installationId,
      'timezone': timezone,
      'carrier': ?carrier,
    }),
  );

  @override
  Future<String> createWechatState(String installationId) async {
    final body = await _post('/api/v1/auth/wechat/state', {
      'installation_id': installationId,
    });
    return body['state']! as String;
  }

  @override
  Future<AuthSession> wechatLogin({
    required String code,
    required String state,
    required String installationId,
    required String timezone,
  }) async => _session(
    await _post('/api/v1/auth/wechat', {
      'code': code,
      'state': state,
      'installation_id': installationId,
      'timezone': timezone,
    }),
  );

  @override
  Future<AuthSession> reviewLogin({
    required String username,
    required String password,
    required String installationId,
    required String timezone,
  }) async => _session(
    await _post('/api/v1/auth/review-login', {
      'username': username,
      'password': password,
      'installation_id': installationId,
      'timezone': timezone,
    }),
  );

  @override
  Future<AuthSession> refresh(String refreshToken) async => _session(
    await _post('/api/v1/auth/refresh', {'refresh_token': refreshToken}),
  );

  @override
  Future<List<String>> me(String accessToken) async {
    final body = await _get('/api/v1/auth/me', accessToken);
    return (body['providers']! as List).cast<String>();
  }

  @override
  Future<void> logout(String accessToken, String refreshToken) async {
    await _post('/api/v1/auth/logout', {
      'refresh_token': refreshToken,
    }, accessToken: accessToken);
  }

  @override
  Future<String> requestDeletion({
    required String accessToken,
    required String idempotencyKey,
    required String localDataAction,
  }) async {
    final body = await _post('/api/v1/account/deletion-request', {
      'idempotency_key': idempotencyKey,
      'local_data_action': localDataAction,
    }, accessToken: accessToken);
    return body['request_id']! as String;
  }

  @override
  Future<void> confirmDeletion({
    required String accessToken,
    required String requestId,
  }) async {
    await _post('/api/v1/account/deletion-confirm', {
      'request_id': requestId,
      'confirmation': 'DELETE',
    }, accessToken: accessToken);
  }

  Future<Map<String, Object?>> _get(String path, String accessToken) =>
      _send('GET', path, accessToken: accessToken);

  Future<Map<String, Object?>> _post(
    String path,
    Map<String, Object?> body, {
    String? accessToken,
  }) => _send('POST', path, body: body, accessToken: accessToken);

  Future<Map<String, Object?>> _send(
    String method,
    String path, {
    Map<String, Object?>? body,
    String? accessToken,
  }) async {
    if (_baseUrl.isEmpty) {
      throw const AuthApiException('AUTH_API_NOT_CONFIGURED', isNetwork: true);
    }
    try {
      final request = http.Request(method, Uri.parse('$_baseUrl$path'))
        ..headers['content-type'] = 'application/json';
      if (accessToken != null) {
        request.headers['authorization'] = 'Bearer $accessToken';
      }
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 12));
      final response = await http.Response.fromStream(streamed);
      final decoded = response.body.isEmpty
          ? <String, Object?>{}
          : (jsonDecode(response.body) as Map).cast<String, Object?>();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }
      final error = decoded['error'] as Map<String, Object?>?;
      throw AuthApiException(
        error?['code'] as String? ?? 'AUTH_REQUEST_FAILED',
        statusCode: response.statusCode,
      );
    } on TimeoutException {
      throw const AuthApiException('AUTH_NETWORK_TIMEOUT', isNetwork: true);
    } on SocketException {
      throw const AuthApiException('AUTH_NETWORK_OFFLINE', isNetwork: true);
    } on http.ClientException {
      throw const AuthApiException('AUTH_NETWORK_UNAVAILABLE', isNetwork: true);
    } on FormatException {
      throw const AuthApiException('AUTH_RESPONSE_INVALID');
    }
  }

  AuthSession _session(Map<String, Object?> body) {
    final user = (body['user']! as Map).cast<String, Object?>();
    final tokens = (body['tokens']! as Map).cast<String, Object?>();
    return AuthSession(
      userId: user['user_id']! as String,
      sessionId: body['session_id']! as String,
      accessToken: tokens['access_token']! as String,
      refreshToken: tokens['refresh_token']! as String,
      accessExpiresAt: DateTime.parse(
        tokens['access_expires_at']! as String,
      ).toUtc(),
      refreshExpiresAt: DateTime.parse(
        tokens['refresh_expires_at']! as String,
      ).toUtc(),
      lastVerifiedAt: DateTime.now().toUtc(),
      providers: (user['providers']! as List).cast<String>(),
    );
  }
}
