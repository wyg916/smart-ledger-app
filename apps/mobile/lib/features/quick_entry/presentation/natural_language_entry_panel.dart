import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ledger/app/ledger_theme.dart';
import 'package:smart_ledger/core/database/database_providers.dart';
import 'package:smart_ledger/core/money/money.dart';
import 'package:smart_ledger/features/accounts/domain/ledger_account.dart';
import 'package:smart_ledger/features/ai/domain/ai_models.dart';
import 'package:smart_ledger/features/ai/presentation/ai_providers.dart';
import 'package:smart_ledger/features/categories/domain/ledger_category.dart';
import 'package:smart_ledger/features/home/presentation/home_providers.dart';
import 'package:smart_ledger/features/quick_entry/domain/natural_language_parser.dart';
import 'package:smart_ledger/features/quick_entry/domain/transaction_draft.dart';
import 'package:smart_ledger/features/telemetry/presentation/telemetry_providers.dart';
import 'package:smart_ledger/features/transactions/domain/ledger_transaction.dart';
import 'package:smart_ledger/features/transactions/presentation/ledger_providers.dart';

class NaturalLanguageEntryPanel extends ConsumerStatefulWidget {
  const NaturalLanguageEntryPanel({
    super.key,
    this.compact = false,
    this.onConfirmed,
  });

  final bool compact;
  final VoidCallback? onConfirmed;

  @override
  ConsumerState<NaturalLanguageEntryPanel> createState() =>
      _NaturalLanguageEntryPanelState();
}

class _NaturalLanguageEntryPanelState
    extends ConsumerState<NaturalLanguageEntryPanel> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: LedgerPalette.paper,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.compact) ...[
              Text('一句话记账', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              const Text('例如：今天早餐花了25元。确认草稿后才会保存。'),
              const SizedBox(height: 10),
            ],
            TextField(
              key: const Key('natural-entry-input'),
              controller: _controller,
              enabled: !_loading,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: '今天早餐花了25元',
                prefixIcon: const Icon(Icons.auto_awesome_rounded),
                suffixIcon: IconButton(
                  key: const Key('natural-entry-submit'),
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_upward_rounded),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                key: const Key('natural-entry-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    _record('natural_language_entry_submitted');
    try {
      final timeZoneId = await ref.read(homeLedgerTimeZoneProvider.future);
      final allCategories = await ref.read(allCategoriesProvider.future);
      final enabled = allCategories
          .where((category) => category.enabled)
          .toList();
      final local = const NaturalLanguageTransactionParser().parse(
        text: text,
        nowUtc: ref.read(ledgerClockProvider).nowUtc(),
        timeZoneId: timeZoneId,
      );
      TransactionDraft draft;
      if (local != null && local.confidence >= 0.8) {
        draft = local;
      } else {
        try {
          draft = await ref
              .read(aiApiClientProvider)
              .parseTransaction(
                text: text,
                timeZoneId: timeZoneId,
                categories: enabled,
              );
        } on AiFailure {
          if (local == null) rethrow;
          draft = local;
        }
      }
      if (!mounted) return;
      final accounts = await ref.read(enabledAccountsProvider.future);
      if (!mounted) return;
      final choice = await showDialog<_DraftChoice>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _DraftConfirmationDialog(
          draft: draft,
          categories: enabled,
          accounts: accounts,
        ),
      );
      if (choice == null) {
        _record('natural_language_entry_cancelled');
        return;
      }
      await ref
          .read(saveTransactionUseCaseProvider)
          .create(
            type: draft.type,
            accountId: choice.accountId,
            categoryId: choice.categoryId,
            amountMinor: draft.amountMinor,
            occurredAtUtc: draft.occurredAtUtc,
            timeZoneId: draft.timeZoneId,
            note: draft.note,
            sourceType: 'ai_assisted',
          );
      _record('natural_language_entry_confirmed');
      _record(
        'transaction_created',
        properties: const {'entry_method': 'natural_language'},
      );
      _controller.clear();
      widget.onConfirmed?.call();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已确认并保存这笔账')));
      }
    } on AiFailure catch (failure) {
      if (mounted) setState(() => _error = '${failure.message}，可以改用手动记账');
    } catch (error) {
      if (mounted) setState(() => _error = '暂时无法形成草稿：$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _record(String name, {Map<String, Object> properties = const {}}) {
    unawaited(
      ref
          .read(telemetryCoordinatorProvider.future)
          .then((value) => value.record(name, properties: properties)),
    );
  }
}

final class _DraftChoice {
  const _DraftChoice({required this.accountId, required this.categoryId});
  final String accountId;
  final String categoryId;
}

class _DraftConfirmationDialog extends StatefulWidget {
  const _DraftConfirmationDialog({
    required this.draft,
    required this.categories,
    required this.accounts,
  });

  final TransactionDraft draft;
  final List<LedgerCategory> categories;
  final List<LedgerAccount> accounts;

  @override
  State<_DraftConfirmationDialog> createState() =>
      _DraftConfirmationDialogState();
}

class _DraftConfirmationDialogState extends State<_DraftConfirmationDialog> {
  String? _categoryId;
  String? _accountId;

  @override
  void initState() {
    super.initState();
    final type = widget.draft.type == LedgerTransactionType.income
        ? CategoryType.income
        : CategoryType.expense;
    final candidates = widget.categories.where(
      (category) => category.type == type,
    );
    _categoryId = candidates
        .where((category) => category.name == widget.draft.categoryCandidate)
        .firstOrNull
        ?.id;
    _categoryId ??= candidates.firstOrNull?.id;
    _accountId = widget.accounts.firstOrNull?.id;
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.draft.type == LedgerTransactionType.income
        ? CategoryType.income
        : CategoryType.expense;
    final categories = widget.categories
        .where((category) => category.type == type)
        .toList();
    return AlertDialog(
      key: const Key('natural-entry-confirmation'),
      title: const Text('确认记账草稿'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Money.fromMinor(
                widget.draft.amountMinor,
              ).format(withCurrencySymbol: true),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              widget.draft.type == LedgerTransactionType.income ? '收入' : '支出',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('draft-category'),
              initialValue: _categoryId,
              decoration: const InputDecoration(labelText: '分类'),
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
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              key: const Key('draft-account'),
              initialValue: _accountId,
              decoration: const InputDecoration(labelText: '账户'),
              items: widget.accounts
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _accountId = value),
            ),
            const SizedBox(height: 10),
            Text('时间：${widget.draft.occurredAtUtc.toLocal()}'),
            Text('备注：${widget.draft.note}'),
            if (widget.draft.warnings.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final warning in widget.draft.warnings) Text('• $warning'),
            ],
            const SizedBox(height: 8),
            const Text('此处仅为草稿，点击确认后才会写入本地账本。'),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('cancel-natural-entry'),
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          key: const Key('confirm-natural-entry'),
          onPressed: _categoryId == null || _accountId == null
              ? null
              : () => Navigator.pop(
                  context,
                  _DraftChoice(
                    accountId: _accountId!,
                    categoryId: _categoryId!,
                  ),
                ),
          child: const Text('确认记账'),
        ),
      ],
    );
  }
}
