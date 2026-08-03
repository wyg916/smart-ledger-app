import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ledger/app/ledger_theme.dart';
import 'package:smart_ledger/app/router.dart';

class SmartLedgerApp extends ConsumerWidget {
  const SmartLedgerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: '智能记账',
      debugShowCheckedModeBanner: false,
      theme: buildLedgerTheme(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
