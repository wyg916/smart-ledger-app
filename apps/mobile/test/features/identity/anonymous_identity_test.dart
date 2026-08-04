import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/core/database/entity_id.dart';
import 'package:smart_ledger/features/identity/domain/anonymous_identity.dart';

void main() {
  test('installation and actor persist while each session is new', () async {
    final store = InMemoryIdentityStore();
    final service = AnonymousIdentityService(
      store,
      SequenceEntityIdGenerator([
        '10000000-0000-4000-8000-000000000001',
        '10000000-0000-4000-8000-000000000002',
        '10000000-0000-4000-8000-000000000003',
        '10000000-0000-4000-8000-000000000004',
      ]),
    );

    final first = await service.startSession();
    await service.saveInstallationToken('opaque-token');
    final second = await service.startSession();

    expect(second.installationId, first.installationId);
    expect(second.actorId, first.actorId);
    expect(second.sessionId, isNot(first.sessionId));
    expect(second.installationToken, 'opaque-token');
  });
}
