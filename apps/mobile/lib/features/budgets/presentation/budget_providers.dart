import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ledger/core/database/database_providers.dart';
import 'package:smart_ledger/core/time/ledger_time.dart';
import 'package:smart_ledger/features/budgets/domain/ledger_budget.dart';
import 'package:smart_ledger/features/transactions/presentation/ledger_providers.dart';

final monthlyBudgetsProvider = StreamProvider<List<LedgerBudget>>((ref) {
  final filter = ref.watch(ledgerFilterProvider);
  return ref
      .watch(budgetRepositoryProvider)
      .watchMonth(LedgerMonth(filter.month.year, filter.month.month));
});

final budgetDetailProvider = FutureProvider.family<LedgerBudget?, String>(
  (ref, id) => ref.watch(budgetRepositoryProvider).getById(id),
);
