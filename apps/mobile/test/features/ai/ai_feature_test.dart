import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_ledger/app/app.dart';
import 'package:smart_ledger/core/database/database_providers.dart';
import 'package:smart_ledger/core/time/ledger_time.dart';
import 'package:smart_ledger/features/ai/data/ai_api_client.dart';
import 'package:smart_ledger/features/ai/domain/ai_models.dart';
import 'package:smart_ledger/features/ai/domain/ai_request_factories.dart';
import 'package:smart_ledger/features/ai/domain/ai_requests.dart';
import 'package:smart_ledger/features/ai/presentation/ai_financial_plan_page.dart';
import 'package:smart_ledger/features/ai/presentation/ai_providers.dart';
import 'package:smart_ledger/features/analytics/domain/ledger_analytics.dart';

import '../../support/ledger_test_harness.dart';

void main() {
  test(
    'Android release networking is declared and cleartext stays scoped',
    () async {
      final manifest = await File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsString();
      final networkSecurity = await File(
        'android/app/src/main/res/xml/network_security_config.xml',
      ).readAsString();
      expect(manifest, contains('android.permission.INTERNET'));
      expect(manifest, contains('@xml/network_security_config'));
      expect(networkSecurity, contains('cleartextTrafficPermitted="false"'));
      expect(networkSecurity, contains('>10.0.2.2</domain>'));
      expect(
        networkSecurity,
        isNot(contains('cleartextTrafficPermitted="true" />')),
      );
    },
  );

  test('DTO uses Int64 aggregates and excludes raw identity fields', () {
    final json = monthlyAiRequest(_snapshot()).toJson();
    expect(json['income_minor'], isA<int>());
    expect(json['income_minor'], 9007199254740991);
    final encoded = jsonEncode(json);
    for (final forbidden in [
      'note',
      'merchant',
      'device_id',
      'transaction_id',
      'email',
      'phone',
      'reasoning_content',
    ]) {
      expect(encoded, isNot(contains(forbidden)));
    }
  });

  test('financial plan gap is deterministic integer arithmetic', () {
    final json = financialPlanAiRequest(
      goalName: '应急金',
      targetMinor: 1000,
      deadlineMonths: 3,
      currentMinor: 100,
      monthlyContributionMinor: 200,
      riskPreference: 'conservative',
    ).toJson();
    expect(json['monthly_gap_minor'], 100);
    expect(json.values.whereType<double>(), isEmpty);
  });

  testWidgets('monthly, budget and plan AI scenes succeed with disclaimer', (
    tester,
  ) async {
    final harness = await _pumpApp(tester, _FakeAiClient());
    await tester.tap(find.byKey(const Key('ai-action')));
    await tester.pumpAndSettle();
    expect(find.text('月度消费总结'), findsOneWidget);
    expect(find.text('想看懂哪一部分呢？'), findsOneWidget);

    await tester.tap(find.byKey(const Key('ai-monthly-entry')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('generate-monthly-ai')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('monthly-deterministic')), findsOneWidget);
    expect(find.byKey(const Key('ai-success')), findsOneWidget);
    expect(find.byKey(const Key('ai-disclaimer')), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ai-budget-entry')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('generate-budget-ai')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('budget-deterministic')), findsOneWidget);
    expect(find.byKey(const Key('ai-success')), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ai-plan-entry')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('generate-plan-ai')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ai-success')), findsOneWidget);
    expect(find.textContaining('reasoning_content'), findsNothing);
    await _disposeApp(tester, harness);
  });

  testWidgets('loading is visible and success replaces it', (tester) async {
    final completer = Completer<AiResult>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiApiClientProvider.overrideWithValue(_CompletingAiClient(completer)),
        ],
        child: const MaterialApp(home: AiFinancialPlanPage()),
      ),
    );
    await tester.tap(find.byKey(const Key('generate-plan-ai')));
    await tester.pump();
    expect(find.byKey(const Key('ai-loading')), findsOneWidget);
    completer.complete(_result());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ai-success')), findsOneWidget);
  });

  for (final kind in AiFailureKind.values) {
    testWidgets('${kind.name} keeps deterministic fallback and retry', (
      tester,
    ) async {
      final client = _FakeAiClient(failures: [AiFailure(kind, '合成失败')]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [aiApiClientProvider.overrideWithValue(client)],
          child: const MaterialApp(home: AiFinancialPlanPage()),
        ),
      );
      await tester.tap(find.byKey(const Key('generate-plan-ai')));
      await tester.pumpAndSettle();
      expect(find.byKey(Key('ai-failure-${kind.name}')), findsOneWidget);
      expect(find.byKey(const Key('ai-fallback')), findsOneWidget);
      await tester.tap(find.byKey(const Key('ai-retry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ai-success')), findsOneWidget);
      expect(client.planCalls, 2);
    });
  }

  test('HTTP client maps rate limit and never exposes upstream body', () async {
    final client = HttpAiApiClient(
      MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {
              'code': 'AI_RATE_LIMITED',
              'message': 'sensitive upstream',
            },
          }),
          429,
        ),
      ),
      'http://local.test',
    );
    await expectLater(
      client.financialPlan(
        financialPlanAiRequest(
          goalName: '应急金',
          targetMinor: 1000,
          deadlineMonths: 2,
          currentMinor: 0,
          monthlyContributionMinor: 100,
          riskPreference: 'balanced',
        ),
      ),
      throwsA(
        isA<AiFailure>()
            .having((error) => error.kind, 'kind', AiFailureKind.rateLimited)
            .having(
              (error) => error.message,
              'message',
              isNot(contains('sensitive upstream')),
            ),
      ),
    );
  });
}

AnalyticsSnapshot _snapshot() => AnalyticsSnapshot(
  month: const LedgerMonth(2026, 8),
  currencyCode: 'CNY',
  timeZoneId: 'Asia/Shanghai',
  income: const MonthMetric(
    currentMinor: 9007199254740991,
    previousMinor: 100,
    hasBaseline: true,
  ),
  expense: const MonthMetric(
    currentMinor: 50,
    previousMinor: 40,
    hasBaseline: true,
  ),
  dailyTrend: const [
    DailyTrendPoint(localDate: '2026-08-01', incomeMinor: 1, expenseMinor: 2),
  ],
  expenseRanking: const [
    CategoryRank(categoryId: 'not-sent', categoryName: '餐饮', amountMinor: 50),
  ],
  incomeRanking: const [
    CategoryRank(categoryId: 'not-sent', categoryName: '工资', amountMinor: 100),
  ],
  accounts: const [
    AccountBalanceOverview(
      accountId: 'not-sent',
      accountName: '默认账户',
      balanceMinor: 100,
      enabled: true,
    ),
  ],
);

AiResult _result() => const AiResult(
  title: '合成建议',
  summary: '仅依据聚合摘要。',
  insights: [
    AiInsight(
      type: AiInsightType.neutral,
      title: '趋势',
      detail: '保持记录。',
      evidence: '确定性聚合',
    ),
  ],
  actions: [AiAction(priority: 1, title: '记录', detail: '继续记账。')],
  riskTips: ['一般信息'],
  disclaimer: 'AI 结果仅供一般性财务信息参考。',
);

class _FakeAiClient implements AiApiClient {
  _FakeAiClient({List<AiFailure>? failures}) : failures = failures ?? [];
  final List<AiFailure> failures;
  int planCalls = 0;

  Future<AiResult> _next() async {
    if (failures.isNotEmpty) throw failures.removeAt(0);
    return _result();
  }

  @override
  Future<AiResult> monthlySummary(MonthlyAiRequest request) => _next();

  @override
  Future<AiResult> budgetReview(BudgetAiRequest request) => _next();

  @override
  Future<AiResult> financialPlan(FinancialPlanAiRequest request) {
    planCalls++;
    return _next();
  }
}

class _CompletingAiClient implements AiApiClient {
  const _CompletingAiClient(this.completer);
  final Completer<AiResult> completer;

  @override
  Future<AiResult> financialPlan(FinancialPlanAiRequest request) =>
      completer.future;
  @override
  Future<AiResult> budgetReview(BudgetAiRequest request) => completer.future;
  @override
  Future<AiResult> monthlySummary(MonthlyAiRequest request) => completer.future;
}

Future<LedgerTestHarness> _pumpApp(
  WidgetTester tester,
  AiApiClient client,
) async {
  final harness = await LedgerTestHarness.create();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(harness.database),
        ledgerClockProvider.overrideWithValue(harness.clock),
        ledgerTimeZoneProvider.overrideWithValue(
          const FixedLedgerTimeZone('Asia/Shanghai'),
        ),
        entityIdGeneratorProvider.overrideWithValue(harness.ids),
        aiApiClientProvider.overrideWithValue(client),
      ],
      child: const SmartLedgerApp(),
    ),
  );
  await tester.pumpAndSettle();
  return harness;
}

Future<void> _disposeApp(WidgetTester tester, LedgerTestHarness harness) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
  await harness.close();
}
