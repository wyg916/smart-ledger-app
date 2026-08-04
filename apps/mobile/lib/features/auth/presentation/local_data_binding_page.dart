import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ledger/features/auth/presentation/auth_providers.dart';

class LocalDataBindingPage extends ConsumerWidget {
  const LocalDataBindingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(title: const Text('绑定本机账本')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.folder_copy_rounded, size: 64),
            const SizedBox(height: 16),
            Text(
              '发现登录前的本地账本',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text('绑定只会在本机复制一份到当前账号的独立数据库，不会上传服务器，也不会删除原文件。以后切换账号时互不可见。'),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('bind-existing-ledger'),
              onPressed: auth.isBusy
                  ? null
                  : () => ref
                        .read(authControllerProvider.notifier)
                        .bindLegacyData(),
              child: const Text('绑定现有本地账本'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('start-fresh-ledger'),
              onPressed: auth.isBusy
                  ? null
                  : () => ref
                        .read(authControllerProvider.notifier)
                        .startFreshLedger(),
              child: const Text('使用全新账本'),
            ),
            if (auth.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                auth.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
