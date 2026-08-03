import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_ledger/core/database/database_providers.dart';
import 'package:smart_ledger/core/money/money.dart';
import 'package:smart_ledger/features/categories/domain/ledger_category.dart';
import 'package:smart_ledger/features/transactions/domain/ledger_transaction.dart';
import 'package:smart_ledger/features/transactions/presentation/ledger_providers.dart';

class TransactionFormPage extends ConsumerStatefulWidget {
  const TransactionFormPage({super.key, this.transactionId});

  final String? transactionId;

  @override
  ConsumerState<TransactionFormPage> createState() =>
      _TransactionFormPageState();
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  LedgerTransactionType type = LedgerTransactionType.expense;
  String? accountId;
  String? toAccountId;
  String? categoryId;
  late DateTime occurredAt;
  bool loading = false;

  bool get editing => widget.transactionId != null;

  @override
  void initState() {
    super.initState();
    occurredAt = ref.read(ledgerClockProvider).nowUtc().toLocal();
    if (editing) Future<void>.microtask(_load);
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final transaction = await ref
          .read(transactionRepositoryProvider)
          .getById(widget.transactionId!);
      if (transaction == null) throw StateError('交易不存在');
      if (!mounted) return;
      setState(() {
        type = transaction.type;
        accountId = transaction.accountId;
        toAccountId = transaction.toAccountId;
        categoryId = transaction.categoryId;
        amountController.text = Money.fromMinor(
          transaction.amountMinor,
        ).format();
        noteController.text = transaction.note ?? '';
        occurredAt = transaction.occurredAtUtc.toLocal();
      });
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(enabledAccountsProvider).valueOrNull ?? const [];
    final categoryType = type == LedgerTransactionType.income
        ? CategoryType.income
        : CategoryType.expense;
    final categories =
        ref.watch(enabledCategoriesProvider(categoryType)).valueOrNull ??
        const [];

    if (!editing && accountId == null && accounts.isNotEmpty) {
      accountId = accounts.first.id;
    }
    if (accountId != null &&
        accounts.every((item) => item.id != accountId) &&
        !editing) {
      accountId = accounts.isEmpty ? null : accounts.first.id;
    }
    if (type != LedgerTransactionType.transfer &&
        categoryId == null &&
        categories.isNotEmpty &&
        !editing) {
      categoryId = categories.first.id;
    }
    if (type != LedgerTransactionType.transfer &&
        categoryId != null &&
        categories.every((item) => item.id != categoryId) &&
        !editing) {
      categoryId = categories.isEmpty ? null : categories.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? '编辑交易' : '新增交易'),
        actions: [
          if (editing)
            IconButton(
              key: const Key('delete-transaction'),
              onPressed: loading ? null : _confirmDelete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SegmentedButton<LedgerTransactionType>(
                  key: const Key('transaction-type'),
                  segments: const [
                    ButtonSegment(
                      value: LedgerTransactionType.expense,
                      label: Text('支出'),
                    ),
                    ButtonSegment(
                      value: LedgerTransactionType.income,
                      label: Text('收入'),
                    ),
                    ButtonSegment(
                      value: LedgerTransactionType.transfer,
                      label: Text('转账'),
                    ),
                  ],
                  selected: {type},
                  onSelectionChanged: (selected) {
                    setState(() {
                      type = selected.single;
                      categoryId = null;
                      toAccountId = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('transaction-amount'),
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: '金额',
                    prefixText: '¥ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('transaction-account'),
                  initialValue: accountId,
                  decoration: const InputDecoration(
                    labelText: '账户',
                    border: OutlineInputBorder(),
                  ),
                  items: accounts
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => accountId = value),
                ),
                const SizedBox(height: 12),
                if (type == LedgerTransactionType.transfer)
                  DropdownButtonFormField<String>(
                    key: const Key('transaction-target-account'),
                    initialValue: toAccountId,
                    decoration: const InputDecoration(
                      labelText: '目标账户',
                      border: OutlineInputBorder(),
                    ),
                    items: accounts
                        .where((item) => item.id != accountId)
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => toAccountId = value),
                  )
                else
                  DropdownButtonFormField<String>(
                    key: const Key('transaction-category'),
                    initialValue: categoryId,
                    decoration: const InputDecoration(
                      labelText: '分类',
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
                    onChanged: (value) => setState(() => categoryId = value),
                  ),
                const SizedBox(height: 12),
                ListTile(
                  key: const Key('transaction-date'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('日期'),
                  subtitle: Text(
                    '${occurredAt.year}-${occurredAt.month.toString().padLeft(2, '0')}-${occurredAt.day.toString().padLeft(2, '0')}',
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: _pickDate,
                ),
                TextField(
                  key: const Key('transaction-note'),
                  controller: noteController,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: '备注（可选）',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const Key('save-transaction'),
                  onPressed: loading ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(editing ? '保存修改' : '保存交易'),
                ),
              ],
            ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: occurredAt,
    );
    if (selected == null) return;
    setState(() {
      occurredAt = DateTime(
        selected.year,
        selected.month,
        selected.day,
        occurredAt.hour,
        occurredAt.minute,
        occurredAt.second,
      );
    });
  }

  Future<void> _save() async {
    setState(() => loading = true);
    try {
      final selectedAccount = accountId;
      if (selectedAccount == null) throw StateError('请先创建并选择账户');
      final amount = Money.parsePositive(amountController.text).minor;
      final timeZoneId = await ref.read(ledgerTimeZoneProvider).currentIanaId();
      final useCase = ref.read(saveTransactionUseCaseProvider);
      if (editing) {
        await useCase.update(
          id: widget.transactionId!,
          type: type,
          accountId: selectedAccount,
          toAccountId: toAccountId,
          categoryId: categoryId,
          amountMinor: amount,
          occurredAtUtc: occurredAt.toUtc(),
          timeZoneId: timeZoneId,
          note: noteController.text,
        );
        ref.invalidate(transactionDetailProvider(widget.transactionId!));
      } else {
        await useCase.create(
          type: type,
          accountId: selectedAccount,
          toAccountId: toAccountId,
          categoryId: categoryId,
          amountMinor: amount,
          occurredAtUtc: occurredAt.toUtc(),
          timeZoneId: timeZoneId,
          note: noteController.text,
        );
      }
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除？'),
        content: const Text('删除后该记录不会出现在默认列表和汇总中。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            key: const Key('confirm-delete-transaction'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => loading = true);
    try {
      await ref
          .read(saveTransactionUseCaseProvider)
          .delete(widget.transactionId!);
      if (mounted) context.go('/');
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.toString())));
  }
}
