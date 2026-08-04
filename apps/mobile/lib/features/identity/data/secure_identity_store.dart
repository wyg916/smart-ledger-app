import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smart_ledger/features/identity/domain/anonymous_identity.dart';

final class SecureIdentityStore implements IdentityStore {
  const SecureIdentityStore(this._storage);

  final FlutterSecureStorage _storage;
  static final Map<String, String> _unsupportedPlatformFallback = {};

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return _unsupportedPlatformFallback[key];
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      _unsupportedPlatformFallback[key] = value;
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {
      _unsupportedPlatformFallback.clear();
    }
  }
}
