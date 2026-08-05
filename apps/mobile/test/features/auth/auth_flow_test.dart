import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/app/router.dart';
import 'package:smart_ledger/core/database/entity_id.dart';
import 'package:smart_ledger/core/time/ledger_time.dart';
import 'package:smart_ledger/features/auth/data/auth_api_client.dart';
import 'package:smart_ledger/features/auth/data/auth_platform_gateway.dart';
import 'package:smart_ledger/features/auth/data/auth_session_store.dart';
import 'package:smart_ledger/features/auth/data/local_data_isolation_service.dart';
import 'package:smart_ledger/features/auth/domain/auth_session.dart';
import 'package:smart_ledger/features/auth/presentation/auth_controller.dart';
import 'package:smart_ledger/features/identity/domain/anonymous_identity.dart';

void main() {
  group('mandatory authentication controller', () {
    late Directory directory;
    late InMemoryAuthSessionStore store;
    late _FakeAuthApi api;
    late _MutablePlatform platform;
    late AuthController controller;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('smart-ledger-auth-');
      store = InMemoryAuthSessionStore();
      api = _FakeAuthApi();
      platform = _MutablePlatform();
      controller = _controller(directory, store, api, platform);
    });

    tearDown(() async {
      controller.dispose();
      await directory.delete(recursive: true);
    });

    test('first offline launch without a session cannot enter', () async {
      await controller.initialize();
      expect(controller.state.phase, AuthPhase.unauthenticated);
    });

    test('restores a valid session', () async {
      store = InMemoryAuthSessionStore(_session());
      controller.dispose();
      controller = _controller(directory, store, api, platform);
      await controller.initialize();
      expect(controller.state.phase, AuthPhase.authenticated);
      expect(api.meCalls, 1);
    });

    test('refreshes an expired access token', () async {
      store = InMemoryAuthSessionStore(
        _session(
          accessExpiresAt: DateTime.now().toUtc().subtract(
            const Duration(minutes: 1),
          ),
        ),
      );
      controller.dispose();
      controller = _controller(directory, store, api, platform);
      await controller.initialize();
      expect(controller.state.session?.accessToken, 'refreshed-access');
      expect(api.refreshCalls, 1);
    });

    test('failed refresh returns to login', () async {
      store = InMemoryAuthSessionStore(
        _session(
          accessExpiresAt: DateTime.now().toUtc().subtract(
            const Duration(minutes: 1),
          ),
        ),
      );
      api.refreshError = const AuthApiException(
        'AUTH_INVALID',
        statusCode: 401,
      );
      controller.dispose();
      controller = _controller(directory, store, api, platform);
      await controller.initialize();
      expect(controller.state.phase, AuthPhase.unauthenticated);
      expect(await store.read(), isNull);
    });

    test('recent verified session supports short offline use', () async {
      store = InMemoryAuthSessionStore(_session());
      api.meError = const AuthApiException('OFFLINE', isNetwork: true);
      controller.dispose();
      controller = _controller(directory, store, api, platform);
      await controller.initialize();
      expect(controller.state.phase, AuthPhase.authenticated);
      expect(controller.state.isOffline, isTrue);
    });

    test('phone Fake provider succeeds only after agreement', () async {
      expect(
        await controller.loginWithPhone(agreementsAccepted: false),
        isFalse,
      );
      expect(api.phoneCalls, 0);
      expect(await controller.loginWithPhone(agreementsAccepted: true), isTrue);
      expect(controller.state.phase, AuthPhase.authenticated);
      expect(api.phoneCalls, 1);
      expect(api.lastTimezone, 'Asia/Shanghai');
    });

    test('phone cancellation and provider failure stay logged out', () async {
      platform.phoneFailure = 'phone_cancelled';
      expect(
        await controller.loginWithPhone(agreementsAccepted: true),
        isFalse,
      );
      expect(controller.state.errorMessage, '已取消登录');
      platform.phoneFailure = null;
      api.phoneError = const AuthApiException('PHONE_PROVIDER_NOT_CONFIGURED');
      expect(
        await controller.loginWithPhone(agreementsAccepted: true),
        isFalse,
      );
      expect(controller.state.phase, AuthPhase.unauthenticated);
    });

    test('Wechat Fake provider succeeds and validates state', () async {
      expect(
        await controller.loginWithWechat(agreementsAccepted: true),
        isTrue,
      );
      expect(api.wechatCalls, 1);
      expect(controller.state.phase, AuthPhase.authenticated);
    });

    test(
      'Wechat not installed, cancelled, and state mismatch stay logged out',
      () async {
        platform.wechatInstalled = false;
        expect(
          await controller.loginWithWechat(agreementsAccepted: true),
          isFalse,
        );
        expect(controller.state.errorMessage, contains('未安装微信'));
        platform.wechatInstalled = true;
        platform.wechatFailure = 'wechat_cancelled';
        expect(
          await controller.loginWithWechat(agreementsAccepted: true),
          isFalse,
        );
        expect(controller.state.errorMessage, '已取消登录');
        platform.wechatFailure = null;
        platform.returnWrongState = true;
        expect(
          await controller.loginWithWechat(agreementsAccepted: true),
          isFalse,
        );
        expect(controller.state.errorMessage, contains('校验失败'));
      },
    );

    test('review account login is an authenticated session', () async {
      expect(await controller.loginForReview('reviewer', 'secret'), isTrue);
      expect(api.reviewCalls, 1);
      expect(controller.state.session?.providers, contains('play_review'));
    });

    test(
      'logout revokes remotely, clears local token, and closes auth gate',
      () async {
        await controller.loginWithPhone(agreementsAccepted: true);
        await controller.logout();
        expect(api.logoutCalls, 1);
        expect(await store.read(), isNull);
        expect(controller.state.phase, AuthPhase.unauthenticated);
      },
    );

    test('account deletion supports local deletion selection', () async {
      await controller.loginWithPhone(agreementsAccepted: true);
      final database = await LocalDataIsolationService(
        () async => directory,
      ).userDatabase(controller.state.session!.userId);
      await database.writeAsBytes([1, 2, 3]);
      expect(await controller.deleteAccount(deleteLocalData: true), isTrue);
      expect(database.existsSync(), isFalse);
      expect(api.deletionRequests, 1);
      expect(api.deletionConfirms, 1);
    });
  });

  test(
    'login gate blocks deep links and LoginPage blocks back navigation',
    () async {
      const unauthenticated = AuthState.unauthenticated();
      expect(authRedirect(unauthenticated, '/'), '/login');
      expect(authRedirect(unauthenticated, '/ai'), '/login');
      expect(
        authRedirect(unauthenticated, '/transactions/record-id'),
        '/login',
      );
      expect(authRedirect(unauthenticated, '/login'), isNull);

      final loginSource = await File(
        'lib/features/auth/presentation/login_page.dart',
      ).readAsString();
      expect(loginSource, contains('PopScope('));
      expect(loginSource, contains('canPop: false'));
      expect(loginSource, isNot(contains('游客')));
    },
  );

  test(
    'Flutter source does not contain provider secrets or a guest route',
    () async {
      final files = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));
      final source = (await Future.wait(
        files.map((file) => file.readAsString()),
      )).join('\n');
      expect(source, isNot(contains('WECHAT_APP_SECRET')));
      expect(source, isNot(contains('PHONE_PROVIDER_SECRET')));
      expect(source, isNot(contains('/guest-security')));
    },
  );
}

AuthController _controller(
  Directory directory,
  InMemoryAuthSessionStore store,
  _FakeAuthApi api,
  _MutablePlatform platform,
) => AuthController(
  store,
  api,
  platform,
  _identityService(),
  LocalDataIsolationService(() async => directory),
  timeZone: const FixedLedgerTimeZone('Asia/Shanghai'),
  skipBindingCheck: true,
);

AnonymousIdentityService _identityService() =>
    AnonymousIdentityService(InMemoryIdentityStore(), _IncrementingIds());

AuthSession _session({
  DateTime? accessExpiresAt,
  List<String> providers = const ['phone_one_click'],
}) {
  final now = DateTime.now().toUtc();
  return AuthSession(
    userId: '00000000-0000-4000-8000-000000000101',
    sessionId: '00000000-0000-4000-8000-000000000102',
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    accessExpiresAt: accessExpiresAt ?? now.add(const Duration(hours: 1)),
    refreshExpiresAt: now.add(const Duration(days: 30)),
    lastVerifiedAt: now,
    providers: providers,
  );
}

final class _IncrementingIds implements EntityIdGenerator {
  int _value = 0;

  @override
  String next() => 'test-id-${_value++}';
}

final class _MutablePlatform implements AuthPlatformGateway {
  String? phoneFailure;
  String? wechatFailure;
  bool wechatInstalled = true;
  bool returnWrongState = false;

  @override
  Future<PhoneAuthorization> authorizePhone() async {
    if (phoneFailure case final failure?) throw AuthPlatformException(failure);
    return const PhoneAuthorization(token: 'phone-token', carrier: 'mobile');
  }

  @override
  Future<bool> isWechatInstalled() async => wechatInstalled;

  @override
  Future<WechatAuthorization> authorizeWechat(String state) async {
    if (wechatFailure case final failure?) throw AuthPlatformException(failure);
    return WechatAuthorization(
      code: 'wechat-code',
      state: returnWrongState ? 'wrong-state' : state,
    );
  }
}

final class _FakeAuthApi implements AuthApiClient {
  int phoneCalls = 0;
  int wechatCalls = 0;
  int reviewCalls = 0;
  int refreshCalls = 0;
  int meCalls = 0;
  int logoutCalls = 0;
  int deletionRequests = 0;
  int deletionConfirms = 0;
  AuthApiException? phoneError;
  AuthApiException? refreshError;
  AuthApiException? meError;
  String? lastTimezone;

  @override
  Future<AuthSession> phoneLogin({
    required String token,
    required String installationId,
    required String timezone,
    String? carrier,
  }) async {
    phoneCalls++;
    lastTimezone = timezone;
    if (phoneError case final error?) throw error;
    return _session();
  }

  @override
  Future<String> createWechatState(String installationId) async =>
      'server-state';

  @override
  Future<AuthSession> wechatLogin({
    required String code,
    required String state,
    required String installationId,
    required String timezone,
  }) async {
    wechatCalls++;
    lastTimezone = timezone;
    return _session(providers: const ['wechat']);
  }

  @override
  Future<AuthSession> reviewLogin({
    required String username,
    required String password,
    required String installationId,
    required String timezone,
  }) async {
    reviewCalls++;
    lastTimezone = timezone;
    return _session(providers: const ['play_review']);
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    refreshCalls++;
    if (refreshError case final error?) throw error;
    final now = DateTime.now().toUtc();
    return AuthSession(
      userId: _session().userId,
      sessionId: _session().sessionId,
      accessToken: 'refreshed-access',
      refreshToken: 'rotated-refresh',
      accessExpiresAt: now.add(const Duration(hours: 1)),
      refreshExpiresAt: now.add(const Duration(days: 30)),
      lastVerifiedAt: now,
      providers: const ['phone_one_click'],
    );
  }

  @override
  Future<List<String>> me(String accessToken) async {
    meCalls++;
    if (meError case final error?) throw error;
    return const ['phone_one_click'];
  }

  @override
  Future<void> logout(String accessToken, String refreshToken) async {
    logoutCalls++;
  }

  @override
  Future<String> requestDeletion({
    required String accessToken,
    required String idempotencyKey,
    required String localDataAction,
  }) async {
    deletionRequests++;
    return 'deletion-request';
  }

  @override
  Future<void> confirmDeletion({
    required String accessToken,
    required String requestId,
  }) async {
    deletionConfirms++;
  }
}
