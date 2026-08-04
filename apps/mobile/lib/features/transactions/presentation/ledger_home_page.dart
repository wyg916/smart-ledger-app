import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_ledger/app/ledger_theme.dart';
import 'package:smart_ledger/app/ledger_visuals.dart';
import 'package:smart_ledger/core/database/database_providers.dart';
import 'package:smart_ledger/core/money/money.dart';
import 'package:smart_ledger/features/budgets/domain/ledger_budget.dart';
import 'package:smart_ledger/features/categories/domain/ledger_category.dart';
import 'package:smart_ledger/features/home/presentation/home_providers.dart';
import 'package:smart_ledger/features/quick_entry/presentation/natural_language_entry_panel.dart';
import 'package:smart_ledger/features/telemetry/presentation/telemetry_providers.dart';
import 'package:smart_ledger/features/transactions/domain/ledger_transaction.dart';

class LedgerHomePage extends ConsumerWidget {
  const LedgerHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(telemetryPageEventProvider('home_viewed'));
    final bootstrap = ref.watch(localLedgerBootstrapProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的小账本'),
        actions: [
          IconButton(
            key: const Key('profile-action'),
            tooltip: '账号与安全',
            onPressed: () => context.push('/account-security'),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-transaction'),
        onPressed: bootstrap.hasValue
            ? () => context.push('/transactions/new')
            : null,
        icon: const Icon(Icons.add),
        label: const Text('记一笔'),
      ),
      body: SafeArea(
        child: bootstrap.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(message: error.toString()),
          data: (_) => const _LedgerBody(),
        ),
      ),
    );
  }
}

class _LedgerBody extends ConsumerWidget {
  const _LedgerBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(homePeriodProvider);
    final source = period == HomePeriod.today
        ? ref.watch(todayTransactionsProvider)
        : ref.watch(homeMonthTransactionsProvider);
    final quick = ref.watch(quickCategoriesProvider(CategoryType.expense));
    final budgets = ref.watch(homeBudgetsProvider);

    return source.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorState(message: error.toString()),
      data: (items) {
        final summary = summarizeTransactions(items);
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(todayTransactionsProvider);
            ref.invalidate(homeMonthTransactionsProvider);
            ref.invalidate(homeBudgetsProvider);
          },
          child: SingleChildScrollView(
            key: const Key('ledger-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _WelcomeCard(),
                const SizedBox(height: 6),
                const _QuickActions(),
                if (items.isNotEmpty) ...[
                  const _SectionTitle('最近账单'),
                  ...items.take(8).map((item) => _TransactionTile(item: item)),
                ],
                const NaturalLanguageEntryPanel(compact: true),
                const SizedBox(height: 8),
                SegmentedButton<HomePeriod>(
                  key: const Key('home-period'),
                  segments: const [
                    ButtonSegment(value: HomePeriod.today, label: Text('今天')),
                    ButtonSegment(value: HomePeriod.month, label: Text('本月')),
                  ],
                  selected: {period},
                  onSelectionChanged: (selection) =>
                      ref.read(homePeriodProvider.notifier).state =
                          selection.single,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: '收入',
                        value: summary.incomeMinor,
                        keyName: 'income-summary',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryCard(
                        label: '支出',
                        value: summary.expenseMinor,
                        keyName: 'expense-summary',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryCard(
                        label: '净额',
                        value: summary.netMinor,
                        keyName: 'net-summary',
                      ),
                    ),
                  ],
                ),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      period == HomePeriod.today ? '今天暂无记录' : '本月暂无记录',
                      key: const Key('empty-ledger'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (items.isEmpty) const _SectionTitle('最近账单'),
                if (items.isEmpty) const Text('从第一笔开始，慢慢把生活理清楚吧'),
                const _SectionTitle('常用分类', hint: '近 90 天智能排序'),
                quick.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const Text('常用分类暂不可用'),
                  data: (categories) => categories.isEmpty
                      ? const Text('完成几笔记账后，这里会显示常用分类')
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categories
                              .take(6)
                              .map((item) => _QuickCategory(category: item))
                              .toList(growable: false),
                        ),
                ),
                const _SectionTitle('本月预算'),
                budgets.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const Text('预算暂不可用'),
                  data: (values) => values.isEmpty
                      ? OutlinedButton.icon(
                          onPressed: () => context.push('/budgets/new'),
                          icon: const Icon(Icons.add),
                          label: const Text('设置第一项预算'),
                        )
                      : Column(
                          children: values
                              .take(3)
                              .map((item) => _BudgetProgress(budget: item))
                              .toList(growable: false),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.hint});

  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (hint != null) ...[
          const Spacer(),
          Text(hint!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    ),
  );
}

class _QuickCategory extends StatelessWidget {
  const _QuickCategory({required this.category});

  final LedgerCategory category;

  @override
  Widget build(BuildContext context) => ActionChip(
    key: Key('quick-category-${category.id}'),
    avatar: Icon(categoryIcon(category.name), size: 18),
    label: Text(category.name),
    onPressed: () => context.push('/transactions/new?category=${category.id}'),
  );
}

class _BudgetProgress extends StatelessWidget {
  const _BudgetProgress({required this.budget});

  final LedgerBudget budget;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(budget.name)),
              Text(
                '${Money.fromMinor(budget.usedMinor).format()} / '
                '${Money.fromMinor(budget.amountMinor).format()}',
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: budget.displayUsageRate,
            color: budget.isOverrun
                ? Theme.of(context).colorScheme.error
                : budget.isNearLimit
                ? LedgerPalette.honey
                : LedgerPalette.mint,
          ),
        ],
      ),
    ),
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.keyName,
  });

  final String label;
  final int value;
  final String keyName;

  @override
  Widget build(BuildContext context) {
    final color = switch (label) {
      '收入' => LedgerPalette.mintSoft,
      '支出' => LedgerPalette.coralSoft,
      _ => LedgerPalette.honeySoft,
    };
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          children: [
            Text(label),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                Money.fromMinor(value).format(),
                key: Key(keyName),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.item});

  final LedgerTransaction item;

  @override
  Widget build(BuildContext context) {
    final sign = switch (item.type) {
      LedgerTransactionType.income => '+',
      LedgerTransactionType.expense => '-',
      LedgerTransactionType.transfer => '↔',
    };
    final title = item.type == LedgerTransactionType.transfer
        ? '${item.accountName} → ${item.toAccountName}'
        : item.categoryName ?? '未知分类';
    final local = item.occurredAtUtc.toLocal();
    final date =
        '${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return Card(
      child: ListTile(
        key: Key('transaction-${item.id}'),
        onTap: () => context.push('/transactions/${item.id}'),
        leading: CircleAvatar(
          backgroundColor: item.type == LedgerTransactionType.income
              ? LedgerPalette.mintSoft
              : LedgerPalette.coralSoft,
          child: Icon(
            item.type == LedgerTransactionType.transfer
                ? Icons.swap_horiz
                : categoryIcon(title),
          ),
        ),
        title: Text(title),
        subtitle: Text(
          item.note == null
              ? '${item.accountName} · $date'
              : '${item.accountName} · $date · ${item.note}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text('$sign${Money.fromMinor(item.amountMinor).format()}'),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) => Card(
    color: LedgerPalette.honeySoft,
    child: const Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          LedgerBuddy(size: 58),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '今天也一起好好记账吧',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4),
                Text('每一笔都算数，也不必一次做到完美。'),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        _QuickAction(
          key: const Key('ai-action'),
          label: 'AI 陪伴',
          icon: Icons.auto_awesome_rounded,
          color: LedgerPalette.coralSoft,
          onTap: () => context.go('/ai'),
        ),
        _QuickAction(
          key: const Key('analytics-action'),
          label: '统计',
          icon: Icons.insights_rounded,
          color: LedgerPalette.mintSoft,
          onTap: () => context.go('/analytics'),
        ),
        _QuickAction(
          key: const Key('budgets-action'),
          label: '预算',
          icon: Icons.savings_rounded,
          color: LedgerPalette.honeySoft,
          onTap: () => context.push('/budgets'),
        ),
        _QuickAction(
          key: const Key('accounts-action'),
          label: '账户',
          icon: Icons.account_balance_wallet_rounded,
          color: LedgerPalette.skySoft,
          onTap: () => context.push('/accounts'),
        ),
        _QuickAction(
          key: const Key('categories-action'),
          label: '分类',
          icon: Icons.category_rounded,
          color: LedgerPalette.coralSoft,
          onTap: () => context.push('/categories'),
        ),
      ],
    ),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 10),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, size: 25),
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(child: Text('加载失败：$message'));
}
