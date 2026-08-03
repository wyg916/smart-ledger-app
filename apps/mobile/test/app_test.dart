import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/app/app.dart';
import 'package:smart_ledger/core/config/app_environment.dart';

void main() {
  testWidgets('renders the platform foundation page', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appEnvironmentProvider.overrideWithValue(AppEnvironment.test),
        ],
        child: const SmartLedgerApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('智能记账'), findsOneWidget);
    expect(find.text('平台工程基础已就绪'), findsOneWidget);
    expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);
    expect(find.text('test · Flutter foundation ready'), findsOneWidget);
  });
}
