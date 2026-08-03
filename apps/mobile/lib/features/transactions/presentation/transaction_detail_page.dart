import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_ledger/core/database/database_providers.dart';
import 'package:smart_ledger/core/money/money.dart';
import 'package:smart_ledger/features/transactions/domain/ledger_transaction.dart';
import 'package:smart_ledger/features/transactions/presentation/ledger_providers.dart';

class TransactionDetailPage extends ConsumerWidget {
  const TransactionDetailPage({required this.transactionId, super.key});

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(transactionDetailProvider(transactionId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('交易详情'),
        actions: [
          IconButton(
            key: const Key('edit-transaction'),
            onPressed: () => context.push('/transactions/$transactionId/edit'),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            key: const Key('detail-delete-transaction'),
            onPressed: () => _delete(context, ref),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (transaction) {
          if (transaction == null) return const Center(child: Text('交易不存在'));
          final title = switch (transaction.type) {
            LedgerTransactionType.income => '收入',
            LedgerTransactionType.expense => '支出',
            LedgerTransactionType.transfer => '转账',
          };
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                Money.fromMinor(
                  transaction.amountMinor,
                ).format(withCurrencySymbol: true),
                key: const Key('detail-amount'),
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const Divider(height: 32),
              ListTile(
                title: const Text('账户'),
                trailing: Text(transaction.accountName),
              ),
              if (transaction.toAccountName != null)
                ListTile(
                  title: const Text('目标账户'),
                  trailing: Text(transaction.toAccountName!),
                ),
              if (transaction.categoryName != null)
                ListTile(
                  title: const Text('分类'),
                  trailing: Text(transaction.categoryName!),
                ),
              ListTile(
                title: const Text('时区'),
                trailing: Text(transaction.timeZoneId),
              ),
              ListTile(
                title: const Text('版本'),
                trailing: Text('${transaction.version}'),
              ),
              ListTile(
                title: const Text('备注'),
                trailing: Text(transaction.note ?? '无'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除？'),
        content: const Text('该操作会逻辑删除交易。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            key: const Key('confirm-detail-delete'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(saveTransactionUseCaseProvider).delete(transactionId);
    if (context.mounted) context.go('/');
  }
}
