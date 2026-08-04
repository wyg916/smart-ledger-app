import 'package:smart_ledger/core/database/entity_id.dart';

final class AnonymousIdentity {
  const AnonymousIdentity({
    required this.installationId,
    required this.actorId,
    required this.sessionId,
    this.installationToken,
  });

  final String installationId;
  final String actorId;
  final String sessionId;
  final String? installationToken;

  AnonymousIdentity copyWith({String? installationToken}) => AnonymousIdentity(
    installationId: installationId,
    actorId: actorId,
    sessionId: sessionId,
    installationToken: installationToken ?? this.installationToken,
  );
}

abstract interface class IdentityStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> deleteAll();
}

final class InMemoryIdentityStore implements IdentityStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> deleteAll() async => _values.clear();
}

final class AnonymousIdentityService {
  const AnonymousIdentityService(this._store, this._ids);

  static const installationKey = 'installation_id';
  static const actorKey = 'anonymous_actor_id';
  static const tokenKey = 'installation_token';

  final IdentityStore _store;
  final EntityIdGenerator _ids;

  Future<AnonymousIdentity> startSession() async {
    final installationId = await _readOrCreate(installationKey);
    final actorId = await _readOrCreate(actorKey);
    return AnonymousIdentity(
      installationId: installationId,
      actorId: actorId,
      sessionId: _ids.next(),
      installationToken: await _store.read(tokenKey),
    );
  }

  Future<void> saveInstallationToken(String token) =>
      _store.write(tokenKey, token);

  Future<void> deleteAnonymousIdentity() => _store.deleteAll();

  Future<String> _readOrCreate(String key) async {
    final existing = await _store.read(key);
    if (existing != null && existing.isNotEmpty) return existing;
    final created = _ids.next();
    await _store.write(key, created);
    return created;
  }
}
