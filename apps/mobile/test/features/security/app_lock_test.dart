import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/features/security/domain/app_lock_service.dart';

void main() {
  test(
    'enabled app lock becomes opaque on background and needs authentication',
    () async {
      final service = _FakeAppLockService(enabled: true);
      final controller = AppLockController(service);

      await controller.initialize();
      expect(controller.state.locked, isTrue);
      service.authenticated = true;
      expect(await controller.unlock(), isTrue);
      expect(controller.state.locked, isFalse);

      controller.lockForBackground();
      expect(controller.state.locked, isTrue);
    },
  );

  test('failed authentication never enables app lock', () async {
    final service = _FakeAppLockService(enabled: false);
    final controller = AppLockController(service);
    await controller.initialize();

    expect(await controller.setEnabled(true), isFalse);
    expect(controller.state.enabled, isFalse);
  });
}

final class _FakeAppLockService implements AppLockService {
  _FakeAppLockService({required this.enabled});

  bool enabled;
  bool authenticated = false;

  @override
  Future<bool> authenticate() async => authenticated;

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<void> setEnabled(bool value) async => enabled = value;
}
