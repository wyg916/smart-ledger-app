import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ledger/app/ledger_theme.dart';
import 'package:smart_ledger/app/router.dart';
import 'package:smart_ledger/features/auth/domain/auth_session.dart';
import 'package:smart_ledger/features/auth/presentation/auth_providers.dart';
import 'package:smart_ledger/features/security/presentation/app_lock_gate.dart';
import 'package:smart_ledger/features/security/presentation/security_providers.dart';
import 'package:smart_ledger/features/telemetry/presentation/telemetry_providers.dart';

class SmartLedgerApp extends ConsumerStatefulWidget {
  const SmartLedgerApp({super.key});

  @override
  ConsumerState<SmartLedgerApp> createState() => _SmartLedgerAppState();
}

class _SmartLedgerAppState extends ConsumerState<SmartLedgerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      ref.read(appLockControllerProvider.notifier).lockForBackground();
    }
    if (state == AppLifecycleState.detached &&
        ref.read(authControllerProvider).phase == AuthPhase.authenticated) {
      unawaited(
        ref
            .read(telemetryCoordinatorProvider.future)
            .then((coordinator) => coordinator.end()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    if (auth.phase == AuthPhase.authenticated) {
      ref.watch(telemetryCoordinatorProvider);
    }
    return MaterialApp.router(
      title: '智能记账',
      debugShowCheckedModeBanner: false,
      theme: buildLedgerTheme(),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => auth.phase == AuthPhase.authenticated
          ? AppLockGate(child: child)
          : child ?? const SizedBox.shrink(),
    );
  }
}
