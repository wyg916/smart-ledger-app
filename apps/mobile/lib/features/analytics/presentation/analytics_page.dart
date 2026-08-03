import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ledger/core/money/money.dart';
import 'package:smart_ledger/features/analytics/domain/ledger_analytics.dart';
import 'package:smart_ledger/features/analytics/presentation/analytics_providers.dart';
import 'package:smart_ledger/features/transactions/presentation/ledger_providers.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(analyticsProvider);
    final filter = ref.watch(ledgerFilterProvider);
    final accounts = ref.watch(allAccountsProvider).valueOrNull ?? const [];
    final categories = ref.watch(allCategoriesProvider).valueOrNull ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('统计分析')),
      body: result.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          key: const Key('analytics-error'),
          child: Text('统计加载失败：$error'),
        ),
        data: (snapshot) => ListView(
          key: const Key('analytics-list'),
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                IconButton(
                  key: const Key('analytics-previous-month'),
                  onPressed: () =>
                      ref.read(ledgerFilterProvider.notifier).state = filter
                          .copyWith(
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
                      ref.read(ledgerFilterProvider.notifier).state = filter
                          .copyWith(
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
                      const DropdownMenuItem(value: null, child: Text('全部账户')),
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
                      const DropdownMenuItem(value: null, child: Text('全部分类')),
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
                  child: _MetricCard(label: '收入', metric: snapshot.income),
                ),
                Expanded(
                  child: _MetricCard(label: '支出', metric: snapshot.expense),
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
                trailing: Text(Money.fromMinor(item.balanceMinor).format()),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
