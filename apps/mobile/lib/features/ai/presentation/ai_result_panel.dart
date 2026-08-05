import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ledger/app/ledger_theme.dart';
import 'package:smart_ledger/app/ledger_visuals.dart';
import 'package:smart_ledger/features/ai/domain/ai_models.dart';

class AiQuotaPanel extends StatelessWidget {
  const AiQuotaPanel({super.key, required this.quota});

  final AsyncValue<AiQuotaStatus> quota;

  @override
  Widget build(BuildContext context) => quota.when(
    loading: () => const Card(
      key: Key('ai-quota-loading'),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: LinearProgressIndicator(),
      ),
    ),
    error: (_, _) => const Card(
      key: Key('ai-quota-unavailable'),
      child: ListTile(
        leading: Icon(Icons.cloud_off_outlined),
        title: Text('无法获取AI额度'),
        subtitle: Text('本地记账、预算和统计仍可正常使用。'),
      ),
    ),
    data: (value) => Card(
      key: const Key('ai-quota-status'),
      child: ListTile(
        leading: const Icon(Icons.auto_awesome_outlined),
        title: Text(
          '今日剩余 ${value.dailyRemaining}/${value.dailyLimit} 次 · '
          '本周剩余 ${value.weeklyRemaining}/${value.weeklyLimit} 次',
          key: const Key('ai-quota-remaining'),
        ),
        subtitle: Text(
          value.isExhausted
              ? value.exhaustedMessage
              : '下次日额度恢复：${_resetLabel(value.nextDailyResetAt)}',
          key: const Key('ai-quota-reset'),
        ),
      ),
    ),
  );

  static String _resetLabel(DateTime value) {
    final local = value.toLocal();
    return '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class AiResultPanel extends StatelessWidget {
  const AiResultPanel({super.key, required this.result});
  final AiResult result;

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('ai-success'),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const LedgerBuddy(size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '给你整理好啦',
                      style: TextStyle(color: LedgerPalette.mutedInk),
                    ),
                    Text(
                      result.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(result.summary),
          for (final insight in result.insights) ...[
            const SizedBox(height: 10),
            Text(insight.title, style: Theme.of(context).textTheme.titleMedium),
            Text(insight.detail),
            Text('依据：${insight.evidence}'),
          ],
          for (final action in result.actions) ...[
            const SizedBox(height: 10),
            Text('${action.priority}. ${action.title}'),
            Text(action.detail),
          ],
          if (result.riskTips.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('温柔提醒', style: TextStyle(fontWeight: FontWeight.w800)),
            for (final tip in result.riskTips) Text('• $tip'),
          ],
          const Divider(),
          Text(result.disclaimer, key: const Key('ai-disclaimer')),
        ],
      ),
    ),
  );
}

class AiFailurePanel extends StatelessWidget {
  const AiFailurePanel({
    super.key,
    required this.failure,
    required this.onRetry,
  });
  final AiFailure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Card(
    key: Key('ai-failure-${failure.kind.name}'),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const LedgerBuddy(size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(failure.message),
                const Text('别担心，本地确定性结果仍然安全可用。', key: Key('ai-fallback')),
              ],
            ),
          ),
          TextButton(
            key: const Key('ai-retry'),
            onPressed: onRetry,
            child: const Text('重试'),
          ),
        ],
      ),
    ),
  );
}
