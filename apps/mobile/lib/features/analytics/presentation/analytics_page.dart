import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ledger/core/money/money.dart';
import 'package:smart_ledger/features/analytics/domain/ledger_analytics.dart';
import 'package:smart_ledger/features/analytics/presentation/analytics_providers.dart';
import 'package:smart_ledger/features/telemetry/presentation/telemetry_providers.dart';
import 'package:smart_ledger/features/transactions/domain/ledger_transaction.dart';
import 'package:smart_ledger/features/transactions/presentation/details_providers.dart';
import 'package:smart_ledger/features/transactions/presentation/ledger_providers.dart';

enum AnalyticsPeriod { day, month }

final analyticsPeriodProvider = StateProvider<AnalyticsPeriod>(
  (ref) => AnalyticsPeriod.month,
);

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(telemetryPageEventProvider('analytics_viewed'));
    final result = ref.watch(analyticsProvider);
    final filter = ref.watch(ledgerFilterProvider);
    final accounts = ref.watch(allAccountsProvider).valueOrNull ?? const [];
    final categories = ref.watch(allCategoriesProvider).valueOrNull ?? const [];
    final period = ref.watch(analyticsPeriodProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('统计分析')),
      body: result.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          key: const Key('analytics-error'),
          child: Text('统计加载失败：$error'),
        ),
        data: (snapshot) => period == AnalyticsPeriod.day
            ? const _DailyAnalyticsView()
            : ListView(
                key: const Key('analytics-list'),
                padding: const EdgeInsets.all(16),
                children: [
                  _PeriodSwitch(period: period),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        key: const Key('analytics-previous-month'),
                        onPressed: () =>
                            ref
                                .read(ledgerFilterProvider.notifier)
                                .state = filter.copyWith(
                              month: DateTime(
                                filter.month.year,
                                filter.month.month - 1,
                              ),
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
                        key: const Key('analytics-next-month'),
                        onPressed: () =>
                            ref
                                .read(ledgerFilterProvider.notifier)
                                .state = filter.copyWith(
                              month: DateTime(
                                filter.month.year,
                                filter.month.month + 1,
                              ),
                            ),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          key: const Key('analytics-account-filter'),
                          initialValue: filter.accountId,
                          decoration: const InputDecoration(labelText: '账户'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('全部账户'),
                            ),
                            ...accounts.map(
                              (item) => DropdownMenuItem(
                                value: item.id,
                                child: Text(item.name),
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              ref
                                  .read(ledgerFilterProvider.notifier)
                                  .state = value == null
                              ? filter.copyWith(clearAccount: true)
                              : filter.copyWith(accountId: value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          key: const Key('analytics-category-filter'),
                          initialValue: filter.categoryId,
                          decoration: const InputDecoration(labelText: '分类'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('全部分类'),
                            ),
                            ...categories.map(
                              (item) => DropdownMenuItem(
                                value: item.id,
                                child: Text(item.name),
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              ref
                                  .read(ledgerFilterProvider.notifier)
                                  .state = value == null
                              ? filter.copyWith(clearCategory: true)
                              : filter.copyWith(categoryId: value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          label: '收入',
                          metric: snapshot.income,
                        ),
                      ),
                      Expanded(
                        child: _MetricCard(
                          label: '支出',
                          metric: snapshot.expense,
                        ),
                      ),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                const Text('净额'),
                                Text(
                                  Money.fromMinor(snapshot.netMinor).format(),
                                  key: const Key('analytics-net'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!snapshot.hasCurrentData)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        key: Key('empty-analytics'),
                        child: Text('本月暂无收支数据'),
                      ),
                    ),
                  _SectionTitle('每日趋势'),
                  _TrendView(points: snapshot.dailyTrend),
                  _SectionTitle('支出分类排行'),
                  _Ranking(
                    items: snapshot.expenseRanking,
                    emptyKey: 'empty-expense-ranking',
                  ),
                  _SectionTitle('收入分类排行'),
                  _Ranking(
                    items: snapshot.incomeRanking,
                    emptyKey: 'empty-income-ranking',
                  ),
                  _SectionTitle('账户余额概览'),
                  ...snapshot.accounts.map(
                    (item) => ListTile(
                      title: Text(item.accountName),
                      subtitle: item.enabled ? null : const Text('已停用'),
                      trailing: Text(
                        Money.fromMinor(item.balanceMinor).format(),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PeriodSwitch extends ConsumerWidget {
  const _PeriodSwitch({required this.period});

  final AnalyticsPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      SegmentedButton<AnalyticsPeriod>(
        key: const Key('analytics-period'),
        segments: const [
          ButtonSegment(value: AnalyticsPeriod.day, label: Text('按日')),
          ButtonSegment(value: AnalyticsPeriod.month, label: Text('按月')),
        ],
        selected: {period},
        onSelectionChanged: (value) =>
            ref.read(analyticsPeriodProvider.notifier).state = value.single,
      );
}

class _DailyAnalyticsView extends ConsumerWidget {
  const _DailyAnalyticsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedOverride = ref.watch(selectedAnalyticsDayProvider);
    final today = ref.watch(ledgerLocalTodayProvider);
    if (selectedOverride == null && today.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (selectedOverride == null && today.hasError) {
      return const Center(child: Text('无法读取账本时区'));
    }
    final selected = selectedOverride ?? today.requireValue;
    final transactions = ref.watch(dailyAnalyticsTransactionsProvider);
    return transactions.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('日统计加载失败：$error')),
      data: (items) {
        final summary = summarizeTransactions(items);
        final date = '${selected.year}年${selected.month}月${selected.day}日';
        return ListView(
          key: const Key('analytics-day-list'),
          padding: const EdgeInsets.all(16),
          children: [
            const _PeriodSwitch(period: AnalyticsPeriod.day),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  key: const Key('analytics-previous-day'),
                  onPressed: () =>
                      ref.read(selectedAnalyticsDayProvider.notifier).state =
                          selected.subtract(const Duration(days: 1)),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    date,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  key: const Key('analytics-next-day'),
                  onPressed: () =>
                      ref.read(selectedAnalyticsDayProvider.notifier).state =
                          selected.add(const Duration(days: 1)),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DayMetric(label: '收入', value: summary.incomeMinor),
                ),
                Expanded(
                  child: _DayMetric(label: '支出', value: summary.expenseMinor),
                ),
                Expanded(
                  child: _DayMetric(label: '净额', value: summary.netMinor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('当天账单', style: Theme.of(context).textTheme.titleMedium),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Text('当天暂无收支数据', key: Key('empty-day-analytics')),
                ),
              )
            else
              for (final item in items)
                ListTile(
                  title: Text(item.categoryName ?? item.type.name),
                  subtitle: Text(item.accountName),
                  trailing: Text(
                    '${item.type == LedgerTransactionType.income ? '+' : '-'}'
                    '${Money.fromMinor(item.amountMinor).format()}',
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _DayMetric extends StatelessWidget {
  const _DayMetric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Text(label),
          FittedBox(child: Text(Money.fromMinor(value).format())),
        ],
      ),
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.metric});

  final String label;
  final MonthMetric metric;

  @override
  Widget build(BuildContext context) {
    final rate = metric.displayChangeRate;
    final comparison = rate == null
        ? '环比 --'
        : '环比 ${(rate * 100).toStringAsFixed(1)}%';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(label),
            Text(
              Money.fromMinor(metric.currentMinor).format(),
              key: Key('analytics-${label == '收入' ? 'income' : 'expense'}'),
            ),
            Text(comparison, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _TrendView extends StatelessWidget {
  const _TrendView({required this.points});
  final List<DailyTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final active = points
        .where((item) => item.incomeMinor != 0 || item.expenseMinor != 0)
        .toList();
    if (active.isEmpty) {
      return const Text('暂无趋势数据', key: Key('empty-trend'));
    }
    return Column(
      children: active
          .map(
            (item) => ListTile(
              dense: true,
              title: Text(item.localDate.substring(5)),
              subtitle: LinearProgressIndicator(
                value: item.incomeMinor + item.expenseMinor == 0
                    ? 0
                    : item.expenseMinor /
                          (item.incomeMinor + item.expenseMinor),
              ),
              trailing: Text(
                '收 ${Money.fromMinor(item.incomeMinor).format()}\n'
                '支 ${Money.fromMinor(item.expenseMinor).format()}',
                textAlign: TextAlign.end,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _Ranking extends StatelessWidget {
  const _Ranking({required this.items, required this.emptyKey});
  final List<CategoryRank> items;
  final String emptyKey;

  @override
  Widget build(BuildContext context) => items.isEmpty
      ? Text('暂无数据', key: Key(emptyKey))
      : Column(
          children: [
            for (var index = 0; index < items.length; index++)
              ListTile(
                dense: true,
                leading: Text('${index + 1}'),
                title: Text(items[index].categoryName),
                trailing: Text(
                  Money.fromMinor(items[index].amountMinor).format(),
                ),
              ),
          ],
        );
}
