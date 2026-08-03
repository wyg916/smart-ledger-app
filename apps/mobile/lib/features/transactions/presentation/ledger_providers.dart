import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ledger/core/database/database_providers.dart';
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
) {
  final filter = ref.watch(ledgerFilterProvider);
  final startLocal = DateTime(filter.month.year, filter.month.month);
  final endLocal = DateTime(filter.month.year, filter.month.month + 1);
  return ref
      .watch(transactionRepositoryProvider)
      .watch(
        TransactionFilter(
          startUtc: startLocal.toUtc(),
          endUtcExclusive: endLocal.toUtc(),
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
