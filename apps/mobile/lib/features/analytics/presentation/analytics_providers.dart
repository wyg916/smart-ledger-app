import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ledger/core/database/database_providers.dart';
import 'package:smart_ledger/core/time/ledger_time.dart';
import 'package:smart_ledger/features/analytics/domain/ledger_analytics.dart';
import 'package:smart_ledger/features/transactions/presentation/ledger_providers.dart';

final analyticsProvider = StreamProvider<AnalyticsSnapshot>((ref) {
  final filter = ref.watch(ledgerFilterProvider);
  return ref
      .watch(analyticsRepositoryProvider)
      .watch(
        AnalyticsFilter(
          month: LedgerMonth(filter.month.year, filter.month.month),
          accountId: filter.accountId,
          categoryId: filter.categoryId,
        ),
      );
});
