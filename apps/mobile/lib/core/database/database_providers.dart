import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ledger/core/database/app_database.dart';
import 'package:smart_ledger/core/database/entity_id.dart';
import 'package:smart_ledger/core/database/local_ledger_bootstrapper.dart';
import 'package:smart_ledger/core/time/ledger_time.dart';
import 'package:smart_ledger/features/accounts/data/drift_account_repository.dart';
import 'package:smart_ledger/features/accounts/domain/account_use_cases.dart';
import 'package:smart_ledger/features/accounts/domain/ledger_account.dart';
import 'package:smart_ledger/features/categories/data/drift_category_repository.dart';
import 'package:smart_ledger/features/categories/domain/category_use_cases.dart';
import 'package:smart_ledger/features/categories/domain/ledger_category.dart';
import 'package:smart_ledger/features/transactions/data/drift_transaction_repository.dart';
import 'package:smart_ledger/features/transactions/domain/ledger_transaction.dart';
import 'package:smart_ledger/features/transactions/domain/transaction_use_cases.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase.defaults();
  ref.onDispose(database.close);
  return database;
});

final ledgerClockProvider = Provider<LedgerClock>(
  (ref) => const SystemLedgerClock(),
);
final ledgerTimeZoneProvider = Provider<LedgerTimeZone>(
  (ref) => const DeviceLedgerTimeZone(),
);
final entityIdGeneratorProvider = Provider<EntityIdGenerator>(
  (ref) => const UuidEntityIdGenerator(),
);

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return DriftAccountRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(ledgerClockProvider),
    ref.watch(entityIdGeneratorProvider),
  );
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return DriftCategoryRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(ledgerClockProvider),
    ref.watch(entityIdGeneratorProvider),
  );
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return DriftTransactionRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(ledgerClockProvider),
    ref.watch(entityIdGeneratorProvider),
  );
});

final saveAccountUseCaseProvider = Provider<SaveAccountUseCase>(
  (ref) => SaveAccountUseCase(ref.watch(accountRepositoryProvider)),
);
final saveCategoryUseCaseProvider = Provider<SaveCategoryUseCase>(
  (ref) => SaveCategoryUseCase(ref.watch(categoryRepositoryProvider)),
);
final saveTransactionUseCaseProvider = Provider<SaveTransactionUseCase>(
  (ref) => SaveTransactionUseCase(ref.watch(transactionRepositoryProvider)),
);

final localLedgerBootstrapProvider = FutureProvider<void>((ref) async {
  final bootstrapper = LocalLedgerBootstrapper(
    ref.watch(appDatabaseProvider),
    ref.watch(ledgerClockProvider),
    ref.watch(ledgerTimeZoneProvider),
  );
  await bootstrapper.initialize();
});
