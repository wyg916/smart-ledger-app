import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_ledger/app/ledger_theme.dart';
import 'package:smart_ledger/features/security/presentation/security_providers.dart';

class GuestSecurityPage extends ConsumerWidget {
  const GuestSecurityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lock = ref.watch(appLockControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('访客与安全')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            color: LedgerPalette.honeySoft,
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '访客模式',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 6),
                  Text('无需注册。账本默认只保存在这台设备上；匿名标识仅用于去重和产品运行分析。'),
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
              leading: Icon(Icons.cloud_off_rounded),
              title: Text('当前不提供云同步'),
              subtitle: Text('后续若提供同步，会先明确说明数据范围并征得同意。'),
            ),
          ),
          const SizedBox(height: 12),
          Text('账本设置', style: Theme.of(context).textTheme.titleMedium),
          ListTile(
            key: const Key('guest-accounts'),
            leading: const Icon(Icons.account_balance_wallet_rounded),
            title: const Text('账户'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/accounts'),
          ),
          ListTile(
            key: const Key('guest-categories'),
            leading: const Icon(Icons.category_rounded),
            title: const Text('分类'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/categories'),
          ),
          ListTile(
            key: const Key('guest-budgets'),
            leading: const Icon(Icons.savings_rounded),
            title: const Text('预算'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/budgets'),
          ),
        ],
      ),
    );
  }
}
