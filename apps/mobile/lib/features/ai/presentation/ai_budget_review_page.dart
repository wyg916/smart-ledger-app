import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ledger/core/money/money.dart';
import 'package:smart_ledger/features/ai/domain/ai_models.dart';
import 'package:smart_ledger/features/ai/domain/ai_request_factories.dart';
import 'package:smart_ledger/features/ai/presentation/ai_providers.dart';
import 'package:smart_ledger/features/ai/presentation/ai_result_panel.dart';
import 'package:smart_ledger/features/analytics/domain/ledger_analytics.dart';
import 'package:smart_ledger/features/analytics/presentation/analytics_providers.dart';
import 'package:smart_ledger/features/budgets/domain/ledger_budget.dart';
import 'package:smart_ledger/features/budgets/presentation/budget_providers.dart';
import 'package:uuid/uuid.dart';

class AiBudgetReviewPage extends ConsumerStatefulWidget {
  const AiBudgetReviewPage({super.key});

  @override
  ConsumerState<AiBudgetReviewPage> createState() => _AiBudgetReviewPageState();
}

class _AiBudgetReviewPageState extends ConsumerState<AiBudgetReviewPage> {
  bool _loading = false;
  AiResult? _result;
  AiFailure? _failure;
  String? _operationRequestId;

  Future<void> _run(
    AnalyticsSnapshot snapshot,
    List<LedgerBudget> budgets, {
    bool retry = false,
  }) async {
    if (!retry || _operationRequestId == null) {
      _operationRequestId = const Uuid().v4();
    }
    setState(() {
      _loading = true;
      _failure = null;
    });
    try {
      final request = budgetAiRequest(
        snapshot,
        budgets,
        daysRemaining: _daysRemaining(snapshot),
      );
      final result = await ref
          .read(aiApiClientProvider)
          .budgetReview(request, requestId: _operationRequestId);
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

  int _daysRemaining(AnalyticsSnapshot snapshot) {
    final now = DateTime.now();
    if (snapshot.month.year != now.year || snapshot.month.month != now.month) {
      final selected = DateTime(snapshot.month.year, snapshot.month.month);
      return selected.isAfter(DateTime(now.year, now.month))
          ? snapshot.month.daysInMonth
          : 0;
    }
    return snapshot.month.daysInMonth - now.day;
  }

  @override
  Widget build(BuildContext context) {
    final analytics = ref.watch(analyticsProvider);
    final budgets = ref.watch(monthlyBudgetsProvider);
    final quota = ref.watch(aiQuotaProvider);
    final exhausted = quota.valueOrNull?.isExhausted ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('预算执行解释')),
      body: analytics.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('统计加载失败：$error')),
        data: (snapshot) => budgets.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('预算加载失败：$error')),
          data: (items) {
            final total = items
                .where((item) => item.scope == BudgetScope.total)
                .firstOrNull;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AiQuotaPanel(quota: quota),
                Card(
                  key: const Key('budget-deterministic'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '预算 ${Money.fromMinor(total?.amountMinor ?? 0).format()} · '
                      '已用 ${Money.fromMinor(total?.usedMinor ?? 0).format()} · '
                      '剩余 ${Money.fromMinor(total?.remainingMinor ?? 0).format()} · '
                      '超支 ${Money.fromMinor(total?.overrunMinor ?? 0).format()}',
                    ),
                  ),
                ),
                FilledButton(
                  key: const Key('generate-budget-ai'),
                  onPressed: _loading || exhausted
                      ? null
                      : () => _run(snapshot, items),
                  child: const Text('生成预算解释'),
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
                        : () => _run(snapshot, items, retry: true),
                  ),
                if (_result case final result?) AiResultPanel(result: result),
              ],
            );
          },
        ),
      ),
    );
  }
}
