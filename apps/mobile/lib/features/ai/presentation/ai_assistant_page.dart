import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AiAssistantPage extends StatelessWidget {
  const AiAssistantPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AI 助手')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('AI 仅解释本地确定性聚合，不读取原始账单，也不会修改交易或预算。'),
          ),
        ),
        _Entry(
          key: const Key('ai-monthly-entry'),
          title: '月度消费总结',
          subtitle: '解释收支、趋势和分类聚合',
          onTap: () => context.push('/ai/monthly-summary'),
        ),
        _Entry(
          key: const Key('ai-budget-entry'),
          title: '预算执行解释',
          subtitle: '解释预算使用、剩余和超支',
          onTap: () => context.push('/ai/budget-review'),
        ),
        _Entry(
          key: const Key('ai-plan-entry'),
          title: '财务规划建议',
          subtitle: '基于目标和确定性缺口给出一般建议',
          onTap: () => context.push('/ai/financial-plan'),
        ),
      ],
    ),
  );
}

class _Entry extends StatelessWidget {
  const _Entry({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
