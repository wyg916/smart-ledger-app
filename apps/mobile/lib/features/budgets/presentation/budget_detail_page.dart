import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_ledger/core/database/database_providers.dart';
import 'package:smart_ledger/core/money/money.dart';
import 'package:smart_ledger/features/budgets/presentation/budget_providers.dart';

class BudgetDetailPage extends ConsumerWidget {
  const BudgetDetailPage({required this.budgetId, super.key});

  final String budgetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(budgetDetailProvider(budgetId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('预算详情'),
        actions: [
          IconButton(
            key: const Key('edit-budget'),
            onPressed: () => context.push('/budgets/$budgetId/edit'),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('预算加载失败：$error')),
        data: (budget) {
          if (budget == null) return const Center(child: Text('预算不存在'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                budget.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: budget.displayUsageRate),
              const SizedBox(height: 12),
              Text('预算：${Money.fromMinor(budget.amountMinor).format()}'),
              Text('已用：${Money.fromMinor(budget.usedMinor).format()}'),
              Text('剩余：${Money.fromMinor(budget.remainingMinor).format()}'),
              Text(
                '超支：${Money.fromMinor(budget.overrunMinor).format()}',
                key: const Key('budget-overrun'),
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                key: const Key('budget-active'),
                title: const Text('启用预算'),
                value: budget.isActive,
                onChanged: (value) async {
                  await ref
                      .read(saveBudgetUseCaseProvider)
                      .setActive(budget.id, value);
                  ref.invalidate(budgetDetailProvider(budget.id));
                },
              ),
              OutlinedButton.icon(
                key: const Key('delete-budget'),
                onPressed: () => _delete(context, ref),
                icon: const Icon(Icons.delete_outline),
                label: const Text('删除预算'),
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
        title: const Text('删除预算？'),
        content: const Text('预算将被逻辑删除，历史账单不会受影响。'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(saveBudgetUseCaseProvider).delete(budgetId);
    if (context.mounted) context.pop();
  }
}
