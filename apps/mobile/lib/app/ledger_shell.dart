import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_ledger/app/ledger_theme.dart';
import 'package:smart_ledger/features/telemetry/presentation/telemetry_providers.dart';

class LedgerShell extends ConsumerWidget {
  const LedgerShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  int get _index {
    if (location.startsWith('/details')) return 1;
    if (location.startsWith('/transactions/new')) return 2;
    if (location.startsWith('/analytics')) return 3;
    if (location == '/ai') return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: child,
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      height: 72,
      indicatorColor: LedgerPalette.coralSoft,
      onDestinationSelected: (index) {
        final path = [
          '/',
          '/details',
          '/transactions/new',
          '/analytics',
          '/ai',
        ][index];
        if (index == 3) _record(ref, 'analytics_viewed');
        context.go(path);
      },
      destinations: const [
        NavigationDestination(
          key: Key('bottom-home'),
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: '首页',
        ),
        NavigationDestination(
          key: Key('bottom-details'),
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: '明细',
        ),
        NavigationDestination(
          key: Key('bottom-entry'),
          icon: CircleAvatar(
            backgroundColor: LedgerPalette.coral,
            foregroundColor: Colors.white,
            child: Icon(Icons.add_rounded),
          ),
          label: '记一笔',
        ),
        NavigationDestination(
          key: Key('bottom-analytics'),
          icon: Icon(Icons.insights_outlined),
          selectedIcon: Icon(Icons.insights_rounded),
          label: '统计',
        ),
        NavigationDestination(
          key: Key('bottom-ai'),
          icon: Icon(Icons.auto_awesome_outlined),
          selectedIcon: Icon(Icons.auto_awesome_rounded),
          label: 'AI',
        ),
      ],
    ),
  );

  void _record(WidgetRef ref, String name) {
    unawaited(
      ref
          .read(telemetryCoordinatorProvider.future)
          .then((value) => value.record(name)),
    );
  }
}
