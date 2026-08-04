import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ledger/app/ledger_theme.dart';
import 'package:smart_ledger/app/ledger_visuals.dart';
import 'package:smart_ledger/features/security/presentation/security_providers.dart';

class AppLockGate extends ConsumerWidget {
  const AppLockGate({required this.child, super.key});

  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appLockControllerProvider);
    if (!state.initialized) {
      return const ColoredBox(
        color: LedgerPalette.cream,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!state.locked) return child ?? const SizedBox.shrink();
    return ColoredBox(
      color: LedgerPalette.cream,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LedgerBuddy(size: 88),
                const SizedBox(height: 20),
                Text(
                  '智能记账已锁定',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text('使用系统生物识别或设备凭据解锁。'),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const Key('unlock-app'),
                  onPressed: () =>
                      ref.read(appLockControllerProvider.notifier).unlock(),
                  icon: const Icon(Icons.lock_open_rounded),
                  label: const Text('验证并解锁'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
