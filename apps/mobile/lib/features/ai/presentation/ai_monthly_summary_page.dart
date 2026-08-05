import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ledger/core/money/money.dart';
import 'package:smart_ledger/features/ai/domain/ai_models.dart';
import 'package:smart_ledger/features/ai/domain/ai_request_factories.dart';
import 'package:smart_ledger/features/ai/presentation/ai_providers.dart';
import 'package:smart_ledger/features/ai/presentation/ai_result_panel.dart';
import 'package:smart_ledger/features/analytics/domain/ledger_analytics.dart';
import 'package:smart_ledger/features/analytics/presentation/analytics_providers.dart';
import 'package:uuid/uuid.dart';

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
  String? _operationRequestId;

  Future<void> _run(AnalyticsSnapshot snapshot, {bool retry = false}) async {
    if (!retry || _operationRequestId == null) {
      _operationRequestId = const Uuid().v4();
    }
    setState(() {
      _loading = true;
      _failure = null;
      _lastSnapshot = snapshot;
    });
    try {
      final result = await ref
          .read(aiApiClientProvider)
          .monthlySummary(
            monthlyAiRequest(snapshot),
            requestId: _operationRequestId,
          );
      if (!mounted) return;
      setState(() => _result = result);
      ref.invalidate(aiQuotaProvider);
    } on AiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _failure = failure);
      if (failure.kind == AiFailureKind.quotaExceeded) {
        ref.invalidate(aiQuotaProvider);
      }
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
    final quota = ref.watch(aiQuotaProvider);
    final exhausted = quota.valueOrNull?.isExhausted ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('月度消费总结')),
      body: analytics.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('统计加载失败：$error')),
        data: (snapshot) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AiQuotaPanel(quota: quota),
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
              onPressed: _loading || exhausted ? null : () => _run(snapshot),
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
                onRetry: exhausted
                    ? null
                    : () => _run(_lastSnapshot ?? snapshot, retry: true),
              ),
            if (_result case final result?) AiResultPanel(result: result),
          ],
        ),
      ),
    );
  }
}
