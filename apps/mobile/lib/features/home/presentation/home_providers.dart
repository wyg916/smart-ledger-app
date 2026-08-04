import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ledger/core/database/database_providers.dart';
import 'package:smart_ledger/core/database/local_ledger_bootstrapper.dart';
import 'package:smart_ledger/core/time/ledger_time.dart';
import 'package:smart_ledger/features/budgets/domain/ledger_budget.dart';
import 'package:smart_ledger/features/categories/domain/ledger_category.dart';
import 'package:smart_ledger/features/transactions/domain/ledger_transaction.dart';

enum HomePeriod { today, month }

final homePeriodProvider = StateProvider<HomePeriod>((ref) => HomePeriod.today);

final homeLedgerTimeZoneProvider = FutureProvider<String>((ref) async {
  final database = ref.watch(appDatabaseProvider);
  final ledger =
      await (database.select(database.ledgers)..where(
            (row) => row.id.equals(defaultLedgerId) & row.deletedAtMs.isNull(),
          ))
          .getSingle();
  return ledger.timeZoneId;
});

final todayTransactionsProvider = StreamProvider<List<LedgerTransaction>>((
  ref,
) async* {
  final timeZoneId = await ref.watch(homeLedgerTimeZoneProvider.future);
  final now = ref.watch(ledgerClockProvider).nowUtc();
  final localDate = localDateForUtc(now, timeZoneId);
  final range = dayRangeInTimeZone(localDate, timeZoneId);
  yield* ref
      .watch(transactionRepositoryProvider)
      .watch(
        TransactionFilter(
          startUtc: range.start,
          endUtcExclusive: range.endExclusive,
        ),
      );
});

final homeMonthTransactionsProvider = StreamProvider<List<LedgerTransaction>>((
  ref,
) async* {
  final timeZoneId = await ref.watch(homeLedgerTimeZoneProvider.future);
  final now = ref.watch(ledgerClockProvider).nowUtc();
  final localDate = localDateForUtc(now, timeZoneId);
  final range = monthRangeInTimeZone(
    LedgerMonth(localDate.year, localDate.month),
    timeZoneId,
  );
  yield* ref
      .watch(transactionRepositoryProvider)
      .watch(
        TransactionFilter(
          startUtc: range.start,
          endUtcExclusive: range.endExclusive,
        ),
      );
});

final quickCategoriesProvider =
    StreamProvider.family<List<LedgerCategory>, CategoryType>((
      ref,
      type,
    ) async* {
      final timeZoneId = await ref.watch(homeLedgerTimeZoneProvider.future);
      final today = localDateForUtc(
        ref.watch(ledgerClockProvider).nowUtc(),
        timeZoneId,
      );
      final windowStart = dayRangeInTimeZone(
        today.subtract(const Duration(days: 89)),
        timeZoneId,
      ).start;
      yield* ref
          .watch(categoryRepositoryProvider)
          .watchQuick(type: type, windowStartUtc: windowStart);
    });

final homeBudgetsProvider = StreamProvider<List<LedgerBudget>>((ref) async* {
  final timeZoneId = await ref.watch(homeLedgerTimeZoneProvider.future);
  final local = localDateForUtc(
    ref.watch(ledgerClockProvider).nowUtc(),
    timeZoneId,
  );
  yield* ref
      .watch(budgetRepositoryProvider)
      .watchMonth(LedgerMonth(local.year, local.month));
});
