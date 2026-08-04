import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_ledger/app/ledger_theme.dart';
import 'package:smart_ledger/features/auth/presentation/auth_providers.dart';
import 'package:smart_ledger/features/security/presentation/security_providers.dart';

class AccountSecurityPage extends ConsumerWidget {
  const AccountSecurityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final lock = ref.watch(appLockControllerProvider);
    final providers = auth.session?.providers.join('、') ?? '已登录';
    return Scaffold(
      appBar: AppBar(title: const Text('账号与安全')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: LedgerPalette.honeySoft,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '当前账号',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text('登录方式：$providers'),
                  if (auth.isOffline)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text('离线登录中；联网后将自动恢复服务端校验。'),
                    ),
                ],
              ),
            ),
          ),
          Card(
            child: SwitchListTile(
              key: const Key('app-lock-toggle'),
              title: const Text('应用锁'),
              subtitle: const Text('离开应用后，使用设备密码或生物识别再次解锁'),
              value: lock.enabled,
              onChanged: lock.initialized
                  ? (value) async {
                      final changed = await ref
                          .read(appLockControllerProvider.notifier)
                          .setEnabled(value);
                      if (!changed && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('未通过设备身份验证，设置未更改')),
                        );
                      }
                    }
                  : null,
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.phonelink_lock_rounded),
              title: Text('账号数据相互隔离'),
              subtitle: Text('每个账号使用独立的本机数据库；当前不提供云同步。'),
            ),
          ),
          const SizedBox(height: 12),
          Text('账本设置', style: Theme.of(context).textTheme.titleMedium),
          ListTile(
            key: const Key('account-accounts'),
            leading: const Icon(Icons.account_balance_wallet_rounded),
            title: const Text('账户'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/accounts'),
          ),
          ListTile(
            key: const Key('account-categories'),
            leading: const Icon(Icons.category_rounded),
            title: const Text('分类'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/categories'),
          ),
          ListTile(
            key: const Key('account-budgets'),
            leading: const Icon(Icons.savings_rounded),
            title: const Text('预算'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/budgets'),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            key: const Key('logout'),
            onPressed: auth.isBusy ? null : () => _confirmLogout(context, ref),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('退出登录'),
          ),
          const SizedBox(height: 8),
          TextButton(
            key: const Key('delete-account'),
            onPressed: auth.isBusy
                ? null
                : () => _confirmDeletion(context, ref),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('注销账号'),
          ),
          if (auth.errorMessage != null)
            Text(
              auth.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录？'),
        content: const Text('本机账本会保留并继续与当前账号隔离。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            key: const Key('confirm-logout'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  Future<void> _confirmDeletion(BuildContext context, WidgetRef ref) async {
    var deleteLocalData = false;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('确认注销账号'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('注销会立即撤销登录会话。此操作不可撤销。'),
              const SizedBox(height: 12),
              CheckboxListTile(
                key: const Key('delete-local-data'),
                contentPadding: EdgeInsets.zero,
                value: deleteLocalData,
                title: const Text('同时删除本机上的当前账号账本'),
                subtitle: const Text('不勾选则账本继续隔离保留，重新登录后可见。'),
                onChanged: (value) =>
                    setState(() => deleteLocalData = value ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              key: const Key('confirm-delete-account'),
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('确认注销'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await ref
          .read(authControllerProvider.notifier)
          .deleteAccount(deleteLocalData: deleteLocalData);
    }
  }
}
