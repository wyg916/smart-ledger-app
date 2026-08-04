import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ledger/core/database/database_providers.dart';
import 'package:smart_ledger/core/time/ledger_time.dart';
import 'package:smart_ledger/features/home/presentation/home_providers.dart';
import 'package:smart_ledger/features/transactions/domain/ledger_transaction.dart';

final detailsFilterProvider = StateProvider<DetailsFilterState>((ref) {
  final now = ref.watch(ledgerClockProvider).nowUtc().toLocal();
  return DetailsFilterState(month: LedgerMonth(now.year, now.month));
});

final detailsTransactionsProvider = StreamProvider<List<LedgerTransaction>>((
  ref,
) async* {
  final filter = ref.watch(detailsFilterProvider);
  final timeZoneId = await ref.watch(homeLedgerTimeZoneProvider.future);
  final range = monthRangeInTimeZone(filter.month, timeZoneId);
  yield* ref
      .watch(transactionRepositoryProvider)
      .watch(
        TransactionFilter(
          startUtc: range.start,
          endUtcExclusive: range.endExclusive,
          accountId: filter.accountId,
          categoryId: filter.categoryId,
          type: filter.type,
        ),
      );
});

final ledgerLocalTodayProvider = FutureProvider<DateTime>((ref) async {
  final timeZoneId = await ref.watch(homeLedgerTimeZoneProvider.future);
  return localDateForUtc(ref.watch(ledgerClockProvider).nowUtc(), timeZoneId);
});

final selectedAnalyticsDayProvider = StateProvider<DateTime?>((ref) => null);

final dailyAnalyticsTransactionsProvider =
    StreamProvider<List<LedgerTransaction>>((ref) async* {
      final DateTime selected =
          ref.watch(selectedAnalyticsDayProvider) ??
          await ref.watch(ledgerLocalTodayProvider.future);
      final timeZoneId = await ref.watch(homeLedgerTimeZoneProvider.future);
      final range = dayRangeInTimeZone(selected, timeZoneId);
      yield* ref
          .watch(transactionRepositoryProvider)
          .watch(
            TransactionFilter(
              startUtc: range.start,
              endUtcExclusive: range.endExclusive,
            ),
          );
    });

final class DetailsFilterState {
  const DetailsFilterState({
    required this.month,
    this.accountId,
    this.categoryId,
    this.type,
  });

  final LedgerMonth month;
  final String? accountId;
  final String? categoryId;
  final LedgerTransactionType? type;

  DetailsFilterState copyWith({
    LedgerMonth? month,
    String? accountId,
    String? categoryId,
    LedgerTransactionType? type,
    bool clearAccount = false,
    bool clearCategory = false,
    bool clearType = false,
  }) => DetailsFilterState(
    month: month ?? this.month,
    accountId: clearAccount ? null : accountId ?? this.accountId,
    categoryId: clearCategory ? null : categoryId ?? this.categoryId,
    type: clearType ? null : type ?? this.type,
  );
}
