import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:smart_ledger/core/database/app_database.dart';
import 'package:smart_ledger/core/database/entity_id.dart';
import 'package:smart_ledger/core/database/local_ledger_bootstrapper.dart';
import 'package:smart_ledger/core/time/ledger_time.dart';
import 'package:smart_ledger/features/accounts/data/drift_account_repository.dart';
import 'package:smart_ledger/features/analytics/data/drift_analytics_repository.dart';
import 'package:smart_ledger/features/budgets/data/drift_budget_repository.dart';
import 'package:smart_ledger/features/categories/data/drift_category_repository.dart';
import 'package:smart_ledger/features/transactions/data/drift_transaction_repository.dart';

final class MutableTestClock implements LedgerClock {
  MutableTestClock(this.value);

  DateTime value;

  @override
  DateTime nowUtc() => value.toUtc();
}

final class CountingUuidGenerator implements EntityIdGenerator {
  int _counter = 1;

  @override
  String next() {
    final suffix = (_counter++).toString().padLeft(12, '0');
    return '10000000-0000-4000-8000-$suffix';
  }
}

final class LedgerTestHarness {
  LedgerTestHarness._({
    required this.database,
    required this.clock,
    required this.ids,
    required this.accounts,
    required this.analytics,
    required this.budgets,
    required this.categories,
    required this.transactions,
  });

  final AppDatabase database;
  final MutableTestClock clock;
  final CountingUuidGenerator ids;
  final DriftAccountRepository accounts;
  final DriftAnalyticsRepository analytics;
  final DriftBudgetRepository budgets;
  final DriftCategoryRepository categories;
  final DriftTransactionRepository transactions;

  static Future<LedgerTestHarness> create() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final database = AppDatabase(NativeDatabase.memory());
    final clock = MutableTestClock(DateTime.utc(2026, 8, 3, 8));
    final ids = CountingUuidGenerator();
    await LocalLedgerBootstrapper(
      database,
      clock,
      const FixedLedgerTimeZone('Asia/Shanghai'),
    ).initialize();
    return LedgerTestHarness._(
      database: database,
      clock: clock,
      ids: ids,
      accounts: DriftAccountRepository(database, clock, ids),
      analytics: DriftAnalyticsRepository(database),
      budgets: DriftBudgetRepository(database, clock, ids),
      categories: DriftCategoryRepository(database, clock, ids),
      transactions: DriftTransactionRepository(database, clock, ids),
    );
  }

  Future<void> close() => database.close();
}
