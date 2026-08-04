import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_ledger/core/money/money.dart';
import 'package:smart_ledger/features/budgets/domain/ledger_budget.dart';
import 'package:smart_ledger/features/budgets/presentation/budget_providers.dart';
import 'package:smart_ledger/features/telemetry/presentation/telemetry_providers.dart';
import 'package:smart_ledger/features/transactions/presentation/ledger_providers.dart';

class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(telemetryPageEventProvider('budget_viewed'));
    final result = ref.watch(monthlyBudgetsProvider);
    final filter = ref.watch(ledgerFilterProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('预算')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-budget'),
        onPressed: () => context.push('/budgets/new'),
        icon: const Icon(Icons.add),
        label: const Text('新建预算'),
      ),
      body: Column(
        children: [
          _MonthSwitcher(filter: filter, ref: ref),
          Expanded(
            child: result.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                key: const Key('budget-error'),
                child: Text('预算加载失败：$error'),
              ),
              data: (items) => items.isEmpty
                  ? const Center(
                      key: Key('empty-budgets'),
                      child: Text('本月还没有预算'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: items.length,
                      itemBuilder: (context, index) => _BudgetCard(
                        budget: items[index],
                        onTap: () =>
                            context.push('/budgets/${items[index].id}'),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({required this.filter, required this.ref});

  final LedgerFilterState filter;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        key: const Key('budget-previous-month'),
        onPressed: () =>
            ref.read(ledgerFilterProvider.notifier).state = filter.copyWith(
              month: DateTime(filter.month.year, filter.month.month - 1),
            ),
        icon: const Icon(Icons.chevron_left),
      ),
      Expanded(
        child: Text(
          '${filter.month.year}年${filter.month.month}月',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      IconButton(
        key: const Key('budget-next-month'),
        onPressed: () =>
            ref.read(ledgerFilterProvider.notifier).state = filter.copyWith(
              month: DateTime(filter.month.year, filter.month.month + 1),
            ),
        icon: const Icon(Icons.chevron_right),
      ),
    ],
  );
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.budget, required this.onTap});

  final LedgerBudget budget;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = !budget.isActive
        ? '已停用'
        : budget.isOverrun
        ? '已超支 ${Money.fromMinor(budget.overrunMinor).format()}'
        : budget.isNearLimit
        ? '接近用尽'
        : '正常';
    return Card(
      child: InkWell(
        key: Key('budget-${budget.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(budget.name)),
                  Text(status, key: Key('budget-status-${budget.id}')),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: budget.displayUsageRate),
              const SizedBox(height: 8),
              Text(
                '已用 ${Money.fromMinor(budget.usedMinor).format()} / '
                '${Money.fromMinor(budget.amountMinor).format()} · '
                '剩余 ${Money.fromMinor(budget.remainingMinor).format()}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
