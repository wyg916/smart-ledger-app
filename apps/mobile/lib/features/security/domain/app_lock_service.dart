import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

abstract interface class AppLockService {
  Future<bool> isEnabled();
  Future<void> setEnabled(bool enabled);
  Future<bool> authenticate();
}

final class DisabledAppLockService implements AppLockService {
  const DisabledAppLockService();

  @override
  Future<bool> isEnabled() async => false;

  @override
  Future<void> setEnabled(bool enabled) async {}

  @override
  Future<bool> authenticate() async => true;
}

final class DeviceAppLockService implements AppLockService {
  const DeviceAppLockService(this._storage, this._auth);

  static const _key = 'app_lock_enabled';
  final FlutterSecureStorage _storage;
  final LocalAuthentication _auth;

  @override
  Future<bool> isEnabled() async {
    try {
      return await _storage.read(key: _key) == 'true';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    try {
      await _storage.write(key: _key, value: enabled.toString());
    } catch (_) {
      if (enabled) rethrow;
    }
  }

  @override
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: '验证设备身份后进入智能记账',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}

final class AppLockState {
  const AppLockState({
    required this.initialized,
    required this.enabled,
    required this.locked,
  });

  const AppLockState.loading()
    : initialized = false,
      enabled = false,
      locked = false;

  final bool initialized;
  final bool enabled;
  final bool locked;
}

final class AppLockController {
  AppLockController(this._service);

  final AppLockService _service;
  AppLockState state = const AppLockState.loading();
  void Function(AppLockState state)? onChanged;

  Future<void> initialize() async {
    final enabled = await _service.isEnabled();
    _set(AppLockState(initialized: true, enabled: enabled, locked: enabled));
  }

  Future<bool> unlock() async {
    if (!state.enabled) {
      _set(
        const AppLockState(initialized: true, enabled: false, locked: false),
      );
      return true;
    }
    final authenticated = await _service.authenticate();
    if (authenticated) {
      _set(const AppLockState(initialized: true, enabled: true, locked: false));
    }
    return authenticated;
  }

  Future<bool> setEnabled(bool enabled) async {
    if (enabled && !await _service.authenticate()) return false;
    await _service.setEnabled(enabled);
    _set(AppLockState(initialized: true, enabled: enabled, locked: false));
    return true;
  }

  void lockForBackground() {
    if (state.enabled && state.initialized) {
      _set(const AppLockState(initialized: true, enabled: true, locked: true));
    }
  }

  void _set(AppLockState value) {
    state = value;
    onChanged?.call(value);
  }
}
