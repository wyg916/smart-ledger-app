import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ledger/core/database/database_providers.dart';
import 'package:smart_ledger/core/money/money.dart';
import 'package:smart_ledger/features/accounts/domain/ledger_account.dart';
import 'package:smart_ledger/features/transactions/presentation/ledger_providers.dart';

class AccountsPage extends ConsumerWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(allAccountsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('账户管理')),
      floatingActionButton: FloatingActionButton(
        key: const Key('add-account'),
        onPressed: () => _showAccountDialog(context),
        child: const Icon(Icons.add),
      ),
      body: accounts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (items) => ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
          children: items
              .map(
                (item) => Card(
                  child: ListTile(
                    key: Key('account-${item.id}'),
                    title: Text(item.name),
                    subtitle: Text(
                      '余额 ${Money.fromMinor(item.currentBalanceMinor).format()}',
                    ),
                    onTap: () => _showAccountDialog(context, account: item),
                    trailing: Switch(
                      key: Key('account-enabled-${item.id}'),
                      value: item.enabled,
                      onChanged: (value) => ref
                          .read(saveAccountUseCaseProvider)
                          .setEnabled(item.id, value),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

Future<void> _showAccountDialog(
  BuildContext context, {
  LedgerAccount? account,
}) => showDialog<void>(
  context: context,
  builder: (_) => _AccountDialog(account: account),
);

class _AccountDialog extends ConsumerStatefulWidget {
  const _AccountDialog({this.account});

  final LedgerAccount? account;

  @override
  ConsumerState<_AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends ConsumerState<_AccountDialog> {
  late final TextEditingController name;
  late final TextEditingController opening;
  late AccountType type;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.account?.name ?? '');
    opening = TextEditingController(
      text: widget.account == null
          ? '0.00'
          : Money.fromMinor(widget.account!.openingBalanceMinor).format(),
    );
    type = widget.account?.type ?? AccountType.cash;
  }

  @override
  void dispose() {
    name.dispose();
    opening.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.account == null ? '新增账户' : '编辑账户'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('account-name'),
            controller: name,
            decoration: const InputDecoration(labelText: '名称'),
          ),
          TextField(
            key: const Key('account-opening-balance'),
            controller: opening,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: const InputDecoration(labelText: '期初金额'),
          ),
          DropdownButton<AccountType>(
            value: type,
            isExpanded: true,
            items: AccountType.values
                .map(
                  (value) =>
                      DropdownMenuItem(value: value, child: Text(value.name)),
                )
                .toList(),
            onChanged: (value) => setState(() => type = value ?? type),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          key: const Key('save-account'),
          onPressed: _save,
          child: const Text('保存'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    try {
      final amount = Money.parseSigned(opening.text).minor;
      final useCase = ref.read(saveAccountUseCaseProvider);
      if (widget.account == null) {
        await useCase.create(
          name: name.text,
          type: type,
          openingBalanceMinor: amount,
        );
      } else {
        await useCase.update(
          id: widget.account!.id,
          name: name.text,
          type: type,
          openingBalanceMinor: amount,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}
