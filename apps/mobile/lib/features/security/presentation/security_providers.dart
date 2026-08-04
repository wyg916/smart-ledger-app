import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:smart_ledger/features/security/domain/app_lock_service.dart';

final appLockServiceProvider = Provider<AppLockService>(
  (ref) => Platform.environment['FLUTTER_TEST'] == 'true'
      ? const DisabledAppLockService()
      : DeviceAppLockService(
          const FlutterSecureStorage(),
          LocalAuthentication(),
        ),
);

final appLockControllerProvider =
    StateNotifierProvider<AppLockStateNotifier, AppLockState>((ref) {
      final notifier = AppLockStateNotifier(
        AppLockController(ref.watch(appLockServiceProvider)),
      );
      notifier.initialize();
      return notifier;
    });

final class AppLockStateNotifier extends StateNotifier<AppLockState> {
  AppLockStateNotifier(this.controller) : super(const AppLockState.loading()) {
    controller.onChanged = (value) => state = value;
  }

  final AppLockController controller;

  Future<void> initialize() => controller.initialize();
  Future<bool> unlock() => controller.unlock();
  Future<bool> setEnabled(bool enabled) => controller.setEnabled(enabled);
  void lockForBackground() => controller.lockForBackground();
}
