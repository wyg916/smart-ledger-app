import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_ledger/app/ledger_visuals.dart';
import 'package:smart_ledger/core/money/money.dart';
import 'package:smart_ledger/core/time/ledger_time.dart';
import 'package:smart_ledger/features/home/presentation/home_providers.dart';
import 'package:smart_ledger/features/transactions/domain/ledger_transaction.dart';
import 'package:smart_ledger/features/transactions/presentation/details_providers.dart';
import 'package:smart_ledger/features/transactions/presentation/ledger_providers.dart';

class DetailsPage extends ConsumerWidget {
  const DetailsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(detailsFilterProvider);
    final transactions = ref.watch(detailsTransactionsProvider);
    final accounts = ref.watch(allAccountsProvider).valueOrNull ?? const [];
    final categories = ref.watch(allCategoriesProvider).valueOrNull ?? const [];
    final timeZone =
        ref.watch(homeLedgerTimeZoneProvider).valueOrNull ?? 'Asia/Shanghai';
    return Scaffold(
      appBar: AppBar(
        title: const Text('明细'),
        actions: [
          TextButton(
            key: const Key('details-today'),
            onPressed: () async {
              final now = await ref.read(ledgerLocalTodayProvider.future);
              ref.read(detailsFilterProvider.notifier).state = filter.copyWith(
                month: LedgerMonth(now.year, now.month),
              );
            },
            child: const Text('今天'),
          ),
        ],
      ),
      body: Column(
        children: [
          _MonthHeader(filter: filter),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterMenu(
                  label: '账户',
                  value: filter.accountId,
                  values: {for (final item in accounts) item.id: item.name},
                  onChanged: (value) =>
                      ref
                          .read(detailsFilterProvider.notifier)
                          .state = value == null
                      ? filter.copyWith(clearAccount: true)
                      : filter.copyWith(accountId: value),
                ),
                const SizedBox(width: 8),
                _FilterMenu(
                  label: '分类',
                  value: filter.categoryId,
                  values: {for (final item in categories) item.id: item.name},
                  onChanged: (value) =>
                      ref
                          .read(detailsFilterProvider.notifier)
                          .state = value == null
                      ? filter.copyWith(clearCategory: true)
                      : filter.copyWith(categoryId: value),
                ),
                const SizedBox(width: 8),
                DropdownButton<LedgerTransactionType?>(
                  key: const Key('details-type-filter'),
                  value: filter.type,
                  hint: const Text('全部类型'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('全部类型')),
                    DropdownMenuItem(
                      value: LedgerTransactionType.expense,
                      child: Text('支出'),
                    ),
                    DropdownMenuItem(
                      value: LedgerTransactionType.income,
                      child: Text('收入'),
                    ),
                  ],
                  onChanged: (value) =>
                      ref
                          .read(detailsFilterProvider.notifier)
                          .state = value == null
                      ? filter.copyWith(clearType: true)
                      : filter.copyWith(type: value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: transactions.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('明细加载失败：$error')),
              data: (items) => items.isEmpty
                  ? const Center(
                      key: Key('empty-details'),
                      child: Text('这个月还没有账单'),
                    )
                  : _GroupedTransactions(items: items, timeZoneId: timeZone),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthHeader extends ConsumerWidget {
  const _MonthHeader({required this.filter});
  final DetailsFilterState filter;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(
    children: [
      IconButton(
        key: const Key('details-previous-month'),
        onPressed: () => ref.read(detailsFilterProvider.notifier).state = filter
            .copyWith(month: filter.month.previous),
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
        key: const Key('details-next-month'),
        onPressed: () => ref.read(detailsFilterProvider.notifier).state = filter
            .copyWith(month: filter.month.next),
        icon: const Icon(Icons.chevron_right),
      ),
    ],
  );
}

class _FilterMenu extends StatelessWidget {
  const _FilterMenu({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });
  final String label;
  final String? value;
  final Map<String, String> values;
  final ValueChanged<String?> onChanged;
  @override
  Widget build(BuildContext context) => DropdownButton<String?>(
    value: value,
    hint: Text('全部$label'),
    items: [
      DropdownMenuItem(value: null, child: Text('全部$label')),
      ...values.entries.map(
        (entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value)),
      ),
    ],
    onChanged: onChanged,
  );
}

class _GroupedTransactions extends StatelessWidget {
  const _GroupedTransactions({required this.items, required this.timeZoneId});
  final List<LedgerTransaction> items;
  final String timeZoneId;
  @override
  Widget build(BuildContext context) {
    final groups = <String, List<LedgerTransaction>>{};
    for (final item in items) {
      groups
          .putIfAbsent(localDayForUtc(item.occurredAtUtc, timeZoneId), () => [])
          .add(item);
    }
    return ListView(
      key: const Key('details-grouped-list'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        for (final entry in groups.entries)
          _DayGroup(date: entry.key, items: entry.value),
      ],
    );
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({required this.date, required this.items});
  final String date;
  final List<LedgerTransaction> items;
  @override
  Widget build(BuildContext context) {
    final summary = summarizeTransactions(items);
    final parsed = DateTime.parse(date);
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return Card(
      key: Key('details-day-$date'),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${parsed.month}月${parsed.day}日 · 星期${weekdays[parsed.weekday - 1]}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '收 ${Money.fromMinor(summary.incomeMinor).format()}  '
                  '支 ${Money.fromMinor(summary.expenseMinor).format()}',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final item in items)
            ListTile(
              key: Key('details-transaction-${item.id}'),
              leading: CircleAvatar(
                backgroundColor: categoryTint(item.categoryName ?? '转账'),
                child: Icon(categoryIcon(item.categoryName ?? '转账')),
              ),
              title: Text(item.categoryName ?? '转账'),
              subtitle: Text(item.note ?? item.accountName),
              trailing: Text(
                '${item.type == LedgerTransactionType.income
                    ? '+'
                    : item.type == LedgerTransactionType.expense
                    ? '-'
                    : ''}'
                '${Money.fromMinor(item.amountMinor).format()}',
              ),
              onTap: () => context.push('/transactions/${item.id}'),
            ),
        ],
      ),
    );
  }
}
