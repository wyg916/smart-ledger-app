import 'package:flutter/material.dart';
import 'package:smart_ledger/features/ai/domain/ai_models.dart';

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
          Text(result.title, style: Theme.of(context).textTheme.titleLarge),
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
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    key: Key('ai-failure-${failure.kind.name}'),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(failure.message),
          const Text('本地确定性结果仍可使用。', key: Key('ai-fallback')),
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
