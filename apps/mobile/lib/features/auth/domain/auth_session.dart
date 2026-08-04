enum AuthPhase { initializing, unauthenticated, bindingRequired, authenticated }

final class AuthSession {
  const AuthSession({
    required this.userId,
    required this.sessionId,
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
    required this.refreshExpiresAt,
    required this.lastVerifiedAt,
    required this.providers,
  });

  final String userId;
  final String sessionId;
  final String accessToken;
  final String refreshToken;
  final DateTime accessExpiresAt;
  final DateTime refreshExpiresAt;
  final DateTime lastVerifiedAt;
  final List<String> providers;

  bool get canUseOffline =>
      DateTime.now().toUtc().isBefore(
        lastVerifiedAt.toUtc().add(const Duration(days: 7)),
      ) &&
      DateTime.now().toUtc().isBefore(refreshExpiresAt.toUtc());

  AuthSession copyWith({DateTime? lastVerifiedAt, List<String>? providers}) =>
      AuthSession(
        userId: userId,
        sessionId: sessionId,
        accessToken: accessToken,
        refreshToken: refreshToken,
        accessExpiresAt: accessExpiresAt,
        refreshExpiresAt: refreshExpiresAt,
        lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
        providers: providers ?? this.providers,
      );

  Map<String, Object> toJson() => {
    'user_id': userId,
    'session_id': sessionId,
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'access_expires_at': accessExpiresAt.toUtc().toIso8601String(),
    'refresh_expires_at': refreshExpiresAt.toUtc().toIso8601String(),
    'last_verified_at': lastVerifiedAt.toUtc().toIso8601String(),
    'providers': providers,
  };

  factory AuthSession.fromJson(Map<String, Object?> json) => AuthSession(
    userId: json['user_id']! as String,
    sessionId: json['session_id']! as String,
    accessToken: json['access_token']! as String,
    refreshToken: json['refresh_token']! as String,
    accessExpiresAt: DateTime.parse(
      json['access_expires_at']! as String,
    ).toUtc(),
    refreshExpiresAt: DateTime.parse(
      json['refresh_expires_at']! as String,
    ).toUtc(),
    lastVerifiedAt: DateTime.parse(json['last_verified_at']! as String).toUtc(),
    providers: (json['providers']! as List).cast<String>(),
  );

  static AuthSession syntheticTest() {
    final now = DateTime.now().toUtc();
    return AuthSession(
      userId: '00000000-0000-4000-8000-000000000901',
      sessionId: '00000000-0000-4000-8000-000000000902',
      accessToken: 'synthetic-test-access',
      refreshToken: 'synthetic-test-refresh',
      accessExpiresAt: now.add(const Duration(days: 1)),
      refreshExpiresAt: now.add(const Duration(days: 30)),
      lastVerifiedAt: now,
      providers: const ['phone_one_click'],
    );
  }
}

final class AuthState {
  const AuthState({
    required this.phase,
    this.session,
    this.isBusy = false,
    this.isOffline = false,
    this.errorMessage,
  });

  const AuthState.initializing() : this(phase: AuthPhase.initializing);
  const AuthState.unauthenticated({String? errorMessage})
    : this(phase: AuthPhase.unauthenticated, errorMessage: errorMessage);

  final AuthPhase phase;
  final AuthSession? session;
  final bool isBusy;
  final bool isOffline;
  final String? errorMessage;

  bool get isAuthenticated =>
      phase == AuthPhase.authenticated || phase == AuthPhase.bindingRequired;

  AuthState copyWith({
    AuthPhase? phase,
    AuthSession? session,
    bool? isBusy,
    bool? isOffline,
    String? errorMessage,
    bool clearError = false,
  }) => AuthState(
    phase: phase ?? this.phase,
    session: session ?? this.session,
    isBusy: isBusy ?? this.isBusy,
    isOffline: isOffline ?? this.isOffline,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}
