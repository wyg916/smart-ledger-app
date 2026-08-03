import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ledger/core/money/money.dart';
import 'package:smart_ledger/features/ai/domain/ai_models.dart';
import 'package:smart_ledger/features/ai/domain/ai_request_factories.dart';
import 'package:smart_ledger/features/ai/presentation/ai_providers.dart';
import 'package:smart_ledger/features/ai/presentation/ai_result_panel.dart';
import 'package:smart_ledger/features/analytics/domain/ledger_analytics.dart';
import 'package:smart_ledger/features/analytics/presentation/analytics_providers.dart';

class AiMonthlySummaryPage extends ConsumerStatefulWidget {
  const AiMonthlySummaryPage({super.key});

  @override
  ConsumerState<AiMonthlySummaryPage> createState() =>
      _AiMonthlySummaryPageState();
}

class _AiMonthlySummaryPageState extends ConsumerState<AiMonthlySummaryPage> {
  bool _loading = false;
  AiResult? _result;
  AiFailure? _failure;
  AnalyticsSnapshot? _lastSnapshot;

  Future<void> _run(AnalyticsSnapshot snapshot) async {
    setState(() {
      _loading = true;
      _failure = null;
      _lastSnapshot = snapshot;
    });
    try {
      final result = await ref
          .read(aiApiClientProvider)
          .monthlySummary(monthlyAiRequest(snapshot));
      if (!mounted) return;
      setState(() => _result = result);
    } on AiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _failure = failure);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _failure = const AiFailure(
          AiFailureKind.invalidResponse,
          'AI 返回格式无效',
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final analytics = ref.watch(analyticsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('月度消费总结')),
      body: analytics.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('统计加载失败：$error')),
        data: (snapshot) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              key: const Key('monthly-deterministic'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '收入 ${Money.fromMinor(snapshot.income.currentMinor).format()} · '
                  '支出 ${Money.fromMinor(snapshot.expense.currentMinor).format()} · '
                  '净额 ${Money.fromMinor(snapshot.netMinor).format()}',
                ),
              ),
            ),
            FilledButton(
              key: const Key('generate-monthly-ai'),
              onPressed: _loading ? null : () => _run(snapshot),
              child: const Text('生成 AI 总结'),
            ),
            if (_loading)
              const Center(
                key: Key('ai-loading'),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (_failure case final failure?)
              AiFailurePanel(
                failure: failure,
                onRetry: () => _run(_lastSnapshot ?? snapshot),
              ),
            if (_result case final result?) AiResultPanel(result: result),
          ],
        ),
      ),
    );
  }
}
