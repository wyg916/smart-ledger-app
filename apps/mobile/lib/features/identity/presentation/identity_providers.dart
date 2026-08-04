import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smart_ledger/core/database/database_providers.dart';
import 'package:smart_ledger/features/identity/data/secure_identity_store.dart';
import 'package:smart_ledger/features/identity/domain/anonymous_identity.dart';

final identityStoreProvider = Provider<IdentityStore>(
  (ref) => Platform.environment['FLUTTER_TEST'] == 'true'
      ? InMemoryIdentityStore()
      : const SecureIdentityStore(FlutterSecureStorage()),
);

final anonymousIdentityServiceProvider = Provider<AnonymousIdentityService>(
  (ref) => AnonymousIdentityService(
    ref.watch(identityStoreProvider),
    ref.watch(entityIdGeneratorProvider),
  ),
);

final anonymousIdentityProvider = FutureProvider<AnonymousIdentity>(
  (ref) => ref.watch(anonymousIdentityServiceProvider).startSession(),
);
