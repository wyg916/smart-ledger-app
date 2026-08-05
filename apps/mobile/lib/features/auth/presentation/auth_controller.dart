import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ledger/features/auth/data/auth_api_client.dart';
import 'package:smart_ledger/features/auth/data/auth_platform_gateway.dart';
import 'package:smart_ledger/features/auth/data/auth_session_store.dart';
import 'package:smart_ledger/features/auth/data/local_data_isolation_service.dart';
import 'package:smart_ledger/features/auth/domain/auth_session.dart';
import 'package:smart_ledger/features/identity/domain/anonymous_identity.dart';
import 'package:smart_ledger/core/time/ledger_time.dart';
import 'package:uuid/uuid.dart';

final class AuthController extends StateNotifier<AuthState> {
  AuthController(
    this._store,
    this._api,
    this._platform,
    this._identityService,
    this._isolation, {
    LedgerTimeZone? timeZone,
    this.skipRemoteRestore = false,
    this.skipBindingCheck = false,
  }) : _timeZone = timeZone ?? const DeviceLedgerTimeZone(),
       super(const AuthState.initializing());

  final AuthSessionStore _store;
  final AuthApiClient _api;
  final AuthPlatformGateway _platform;
  final AnonymousIdentityService _identityService;
  final LocalDataIsolationService _isolation;
  final LedgerTimeZone _timeZone;
  final bool skipRemoteRestore;
  final bool skipBindingCheck;

  Future<void> initialize() async {
    final saved = await _store.read();
    if (saved == null ||
        DateTime.now().toUtc().isAfter(saved.refreshExpiresAt.toUtc())) {
      await _store.clear();
      state = const AuthState.unauthenticated();
      return;
    }
    if (skipRemoteRestore) {
      await _accept(saved);
      return;
    }
    try {
      if (DateTime.now().toUtc().isBefore(saved.accessExpiresAt.toUtc())) {
        final providers = await _api.me(saved.accessToken);
        await _accept(
          saved.copyWith(
            providers: providers,
            lastVerifiedAt: DateTime.now().toUtc(),
          ),
        );
        return;
      }
      await _accept(await _api.refresh(saved.refreshToken));
    } on AuthApiException catch (error) {
      if (error.isNetwork && saved.canUseOffline) {
        await _accept(saved, offline: true);
        return;
      }
      if (error.statusCode == 401 &&
          DateTime.now().toUtc().isBefore(saved.refreshExpiresAt.toUtc())) {
        try {
          await _accept(await _api.refresh(saved.refreshToken));
          return;
        } on AuthApiException catch (refreshError) {
          if (refreshError.isNetwork && saved.canUseOffline) {
            await _accept(saved, offline: true);
            return;
          }
        }
      }
      await _store.clear();
      state = const AuthState.unauthenticated(errorMessage: '登录状态已失效，请重新登录');
    }
  }

  Future<bool> loginWithPhone({required bool agreementsAccepted}) async {
    if (!agreementsAccepted) {
      state = const AuthState.unauthenticated(errorMessage: '请先阅读并同意隐私政策和用户协议');
      return false;
    }
    return _performLogin(() async {
      final authorization = await _platform.authorizePhone();
      final installation = await _identityService.startSession();
      final timezone = await _timeZone.currentIanaId();
      return _api.phoneLogin(
        token: authorization.token,
        carrier: authorization.carrier,
        installationId: installation.installationId,
        timezone: timezone,
      );
    });
  }

  Future<bool> loginWithWechat({required bool agreementsAccepted}) async {
    if (!agreementsAccepted) {
      state = const AuthState.unauthenticated(errorMessage: '请先阅读并同意隐私政策和用户协议');
      return false;
    }
    return _performLogin(() async {
      if (!await _platform.isWechatInstalled()) {
        throw const AuthPlatformException('wechat_not_installed');
      }
      final installation = await _identityService.startSession();
      final timezone = await _timeZone.currentIanaId();
      final serverState = await _api.createWechatState(
        installation.installationId,
      );
      final authorization = await _platform.authorizeWechat(serverState);
      if (authorization.state != serverState) {
        throw const AuthPlatformException('wechat_state_mismatch');
      }
      return _api.wechatLogin(
        code: authorization.code,
        state: authorization.state,
        installationId: installation.installationId,
        timezone: timezone,
      );
    });
  }

  Future<bool> loginForReview(String username, String password) =>
      _performLogin(() async {
        final installation = await _identityService.startSession();
        final timezone = await _timeZone.currentIanaId();
        return _api.reviewLogin(
          username: username,
          password: password,
          installationId: installation.installationId,
          timezone: timezone,
        );
      });

  Future<void> bindLegacyData() async {
    final session = state.session;
    if (session == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _isolation.bindLegacy(session.userId);
      state = AuthState(phase: AuthPhase.authenticated, session: session);
    } on FileSystemException {
      state = state.copyWith(isBusy: false, errorMessage: '本地账本绑定失败，请保留现场后重试');
    }
  }

  Future<void> startFreshLedger() async {
    final session = state.session;
    if (session == null) return;
    await _isolation.startFresh(session.userId);
    state = AuthState(phase: AuthPhase.authenticated, session: session);
  }

  Future<void> logout() async {
    final session = state.session;
    state = state.copyWith(isBusy: true, clearError: true);
    if (session != null) {
      try {
        await _api.logout(session.accessToken, session.refreshToken);
      } on AuthApiException {
        // Local logout must still close the database and remove local tokens.
      }
    }
    await _store.clear();
    state = const AuthState.unauthenticated();
  }

  Future<bool> deleteAccount({required bool deleteLocalData}) async {
    final session = state.session;
    if (session == null) return false;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final requestId = await _api.requestDeletion(
        accessToken: session.accessToken,
        idempotencyKey: const Uuid().v4(),
        localDataAction: deleteLocalData ? 'delete_local' : 'keep_isolated',
      );
      await _api.confirmDeletion(
        accessToken: session.accessToken,
        requestId: requestId,
      );
      await _store.clear();
      state = const AuthState.unauthenticated();
      if (deleteLocalData) {
        // Auth state invalidation disposes the per-user Drift database first.
        await Future<void>.delayed(Duration.zero);
        await _isolation.deleteUserData(session.userId);
      }
      return true;
    } on AuthApiException catch (error) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: _messageForApi(error),
      );
      return false;
    }
  }

  Future<bool> _performLogin(Future<AuthSession> Function() operation) async {
    state = const AuthState(phase: AuthPhase.unauthenticated, isBusy: true);
    try {
      await _accept(await operation());
      return true;
    } on AuthPlatformException catch (error) {
      state = AuthState.unauthenticated(
        errorMessage: _messageForPlatform(error.code),
      );
      return false;
    } on AuthApiException catch (error) {
      state = AuthState.unauthenticated(errorMessage: _messageForApi(error));
      return false;
    }
  }

  Future<void> _accept(AuthSession session, {bool offline = false}) async {
    await _store.write(session);
    final bindingRequired =
        !skipBindingCheck &&
        await _isolation.requiresBindingDecision(session.userId);
    state = AuthState(
      phase: bindingRequired
          ? AuthPhase.bindingRequired
          : AuthPhase.authenticated,
      session: session,
      isOffline: offline,
    );
  }

  String _messageForApi(AuthApiException error) {
    if (error.isNetwork) return '网络不可用，请联网后重试';
    return switch (error.code) {
      'AUTH_RATE_LIMITED' => '尝试次数过多，请稍后再试',
      'PHONE_PROVIDER_NOT_CONFIGURED' => '本机号码登录尚未完成运营商配置',
      'WECHAT_PROVIDER_NOT_CONFIGURED' => '微信登录尚未完成开放平台配置',
      'REVIEW_LOGIN_DISABLED' => '审核账号当前未启用',
      _ => '登录失败，请重试',
    };
  }

  String _messageForPlatform(String code) => switch (code) {
    'phone_cancelled' || 'wechat_cancelled' => '已取消登录',
    'phone_not_configured' => '本机号码 SDK 尚未配置',
    'wechat_not_configured' => '微信 AppID 尚未配置',
    'wechat_not_installed' => '未安装微信，请使用本机号码登录',
    'wechat_state_mismatch' => '微信登录校验失败，请重试',
    _ => '授权失败，请重试',
  };
}
