import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_ledger/core/database/database_providers.dart';
import 'package:smart_ledger/core/money/money.dart';
import 'package:smart_ledger/features/transactions/domain/ledger_transaction.dart';
import 'package:smart_ledger/features/transactions/presentation/ledger_providers.dart';

class LedgerHomePage extends ConsumerWidget {
  const LedgerHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(localLedgerBootstrapProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('智能记账'),
        actions: [
          IconButton(
            key: const Key('ai-action'),
            onPressed: () => context.push('/ai'),
            icon: const Icon(Icons.auto_awesome_outlined),
            tooltip: 'AI 助手',
          ),
          IconButton(
            key: const Key('analytics-action'),
            onPressed: () => context.push('/analytics'),
            icon: const Icon(Icons.analytics_outlined),
            tooltip: '统计分析',
          ),
          IconButton(
            key: const Key('budgets-action'),
            onPressed: () => context.push('/budgets'),
            icon: const Icon(Icons.savings_outlined),
            tooltip: '预算管理',
          ),
          IconButton(
            key: const Key('accounts-action'),
            onPressed: () => context.push('/accounts'),
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: '账户管理',
          ),
          IconButton(
            key: const Key('categories-action'),
            onPressed: () => context.push('/categories'),
            icon: const Icon(Icons.category_outlined),
            tooltip: '分类管理',
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
    final transactions = ref.watch(ledgerTransactionsProvider);
    final accounts = ref.watch(allAccountsProvider).valueOrNull ?? const [];
    final categories = ref.watch(allCategoriesProvider).valueOrNull ?? const [];
    final filter = ref.watch(ledgerFilterProvider);

    return transactions.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorState(message: error.toString()),
      data: (items) {
        final summary = summarizeTransactions(items);
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(ledgerTransactionsProvider),
          child: ListView(
            key: const Key('ledger-list'),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              Row(
                children: [
                  IconButton(
                    key: const Key('previous-month'),
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
                    key: const Key('next-month'),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      key: const Key('account-filter'),
                      initialValue: filter.accountId,
                      decoration: const InputDecoration(
                        labelText: '账户',
                        border: OutlineInputBorder(),
                      ),
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      key: const Key('category-filter'),
                      initialValue: filter.categoryId,
                      decoration: const InputDecoration(
                        labelText: '分类',
                        border: OutlineInputBorder(),
                      ),
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
              const SizedBox(height: 20),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 52),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 48),
                      SizedBox(height: 12),
                      Text('本月暂无记录', key: Key('empty-ledger')),
                      Text('点击“记一笔”新增收入、支出或转账'),
                    ],
                  ),
                )
              else
                ...items.map((item) => _TransactionTile(item: item)),
            ],
          ),
        );
      },
    );
  }
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(label),
            const SizedBox(height: 4),
            Text(
              Money.fromMinor(value).format(),
              key: Key(keyName),
              style: Theme.of(context).textTheme.titleMedium,
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
        leading: Icon(
          item.type == LedgerTransactionType.transfer
              ? Icons.swap_horiz
              : Icons.receipt_outlined,
        ),
        title: Text(title),
        subtitle: Text(
          item.note == null
              ? '${item.accountName} · $date'
              : '${item.accountName} · $date · ${item.note}',
        ),
        trailing: Text('$sign${Money.fromMinor(item.amountMinor).format()}'),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(child: Text('加载失败：$message'));
}
