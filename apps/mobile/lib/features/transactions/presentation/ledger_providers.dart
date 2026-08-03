import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ledger/core/database/database_providers.dart';
import 'package:smart_ledger/core/database/local_ledger_bootstrapper.dart';
import 'package:smart_ledger/core/time/ledger_time.dart';
import 'package:smart_ledger/features/accounts/domain/ledger_account.dart';
import 'package:smart_ledger/features/categories/domain/ledger_category.dart';
import 'package:smart_ledger/features/transactions/domain/ledger_transaction.dart';

final allAccountsProvider = StreamProvider<List<LedgerAccount>>(
  (ref) => ref.watch(accountRepositoryProvider).watchAll(),
);

final enabledAccountsProvider = StreamProvider<List<LedgerAccount>>(
  (ref) => ref.watch(accountRepositoryProvider).watchAll(enabledOnly: true),
);

final allCategoriesProvider = StreamProvider<List<LedgerCategory>>(
  (ref) => ref.watch(categoryRepositoryProvider).watchAll(),
);

final enabledCategoriesProvider =
    StreamProvider.family<List<LedgerCategory>, CategoryType>(
      (ref, type) => ref
          .watch(categoryRepositoryProvider)
          .watchAll(type: type, enabledOnly: true),
    );

final ledgerFilterProvider = StateProvider<LedgerFilterState>((ref) {
  final local = ref.watch(ledgerClockProvider).nowUtc().toLocal();
  return LedgerFilterState(month: DateTime(local.year, local.month));
});

final ledgerTransactionsProvider = StreamProvider<List<LedgerTransaction>>((
  ref,
) async* {
  final filter = ref.watch(ledgerFilterProvider);
  final database = ref.watch(appDatabaseProvider);
  final ledger =
      await (database.select(database.ledgers)..where(
            (row) => row.id.equals(defaultLedgerId) & row.deletedAtMs.isNull(),
          ))
          .getSingle();
  final range = monthRangeInTimeZone(
    LedgerMonth(filter.month.year, filter.month.month),
    ledger.timeZoneId,
  );
  yield* ref
      .watch(transactionRepositoryProvider)
      .watch(
        TransactionFilter(
          startUtc: range.start,
          endUtcExclusive: range.endExclusive,
          accountId: filter.accountId,
          categoryId: filter.categoryId,
        ),
      );
});

final transactionDetailProvider =
    FutureProvider.family<LedgerTransaction?, String>(
      (ref, id) => ref.watch(transactionRepositoryProvider).getById(id),
    );

final class LedgerFilterState {
  const LedgerFilterState({
    required this.month,
    this.accountId,
    this.categoryId,
  });

  final DateTime month;
  final String? accountId;
  final String? categoryId;

  LedgerFilterState copyWith({
    DateTime? month,
    String? accountId,
    String? categoryId,
    bool clearAccount = false,
    bool clearCategory = false,
  }) {
    return LedgerFilterState(
      month: month ?? this.month,
      accountId: clearAccount ? null : accountId ?? this.accountId,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
    );
  }
}
