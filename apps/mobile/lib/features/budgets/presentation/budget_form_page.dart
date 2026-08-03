import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_ledger/core/database/database_providers.dart';
import 'package:smart_ledger/core/errors/ledger_exception.dart';
import 'package:smart_ledger/core/money/money.dart';
import 'package:smart_ledger/core/time/ledger_time.dart';
import 'package:smart_ledger/features/budgets/domain/ledger_budget.dart';
import 'package:smart_ledger/features/budgets/presentation/budget_providers.dart';
import 'package:smart_ledger/features/categories/domain/ledger_category.dart';
import 'package:smart_ledger/features/transactions/presentation/ledger_providers.dart';

class BudgetFormPage extends ConsumerStatefulWidget {
  const BudgetFormPage({super.key, this.budgetId});

  final String? budgetId;

  @override
  ConsumerState<BudgetFormPage> createState() => _BudgetFormPageState();
}

class _BudgetFormPageState extends ConsumerState<BudgetFormPage> {
  final _amount = TextEditingController();
  BudgetScope _scope = BudgetScope.total;
  String? _categoryId;
  String? _initializedId;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.budgetId != null;
    final detail = editing
        ? ref.watch(budgetDetailProvider(widget.budgetId!))
        : const AsyncValue<LedgerBudget?>.data(null);
    final categories =
        ref
            .watch(enabledCategoriesProvider(CategoryType.expense))
            .valueOrNull ??
        const <LedgerCategory>[];
    return Scaffold(
      appBar: AppBar(title: Text(editing ? '编辑预算' : '新建预算')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('预算加载失败：$error')),
        data: (budget) {
          if (editing && budget == null) {
            return const Center(child: Text('预算不存在'));
          }
          if (budget != null && _initializedId != budget.id) {
            _initializedId = budget.id;
            _amount.text = Money.fromMinor(budget.amountMinor).format();
            _scope = budget.scope;
            _categoryId = budget.categoryId;
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!editing)
                SegmentedButton<BudgetScope>(
                  key: const Key('budget-scope'),
                  segments: const [
                    ButtonSegment(value: BudgetScope.total, label: Text('总预算')),
                    ButtonSegment(
                      value: BudgetScope.category,
                      label: Text('分类预算'),
                    ),
                  ],
                  selected: {_scope},
                  onSelectionChanged: (value) => setState(() {
                    _scope = value.single;
                    if (_scope == BudgetScope.total) _categoryId = null;
                  }),
                ),
              const SizedBox(height: 16),
              if (_scope == BudgetScope.category && !editing)
                DropdownButtonFormField<String>(
                  key: const Key('budget-category'),
                  initialValue: _categoryId,
                  decoration: const InputDecoration(
                    labelText: '支出分类',
                    border: OutlineInputBorder(),
                  ),
                  items: categories
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _categoryId = value),
                ),
              if (_scope == BudgetScope.category && !editing)
                const SizedBox(height: 16),
              TextField(
                key: const Key('budget-amount'),
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: '每月预算金额',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  key: const Key('budget-form-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('save-budget'),
                onPressed: _saving ? null : () => _save(budget),
                child: Text(_saving ? '保存中…' : '保存'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _save(LedgerBudget? budget) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final amount = Money.parseSigned(_amount.text).minor;
      if (amount < 0) {
        throw const LedgerException('BUDGET_AMOUNT_INVALID', '预算金额不能小于零');
      }
      final useCase = ref.read(saveBudgetUseCaseProvider);
      if (budget == null) {
        final filter = ref.read(ledgerFilterProvider);
        await useCase.create(
          scope: _scope,
          month: LedgerMonth(filter.month.year, filter.month.month),
          amountMinor: amount,
          categoryId: _categoryId,
        );
      } else {
        await useCase.update(id: budget.id, amountMinor: amount);
        ref.invalidate(budgetDetailProvider(budget.id));
      }
      if (mounted) context.pop();
    } on LedgerException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = '保存失败：$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
