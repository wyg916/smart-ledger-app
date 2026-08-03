import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_ledger/app/ledger_theme.dart';
import 'package:smart_ledger/app/ledger_visuals.dart';

class AiAssistantPage extends StatelessWidget {
  const AiAssistantPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AI 小伙伴')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          color: LedgerPalette.honeySoft,
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Row(
              children: [
                LedgerBuddy(size: 68),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '想看懂哪一部分呢？',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text('我只阅读本地聚合，不看原始账单，也不会替你修改任何数据。'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _Entry(
          key: const Key('ai-monthly-entry'),
          title: '月度消费总结',
          subtitle: '解释收支、趋势和分类聚合',
          icon: Icons.calendar_month_rounded,
          color: LedgerPalette.coralSoft,
          onTap: () => context.push('/ai/monthly-summary'),
        ),
        _Entry(
          key: const Key('ai-budget-entry'),
          title: '预算执行解释',
          subtitle: '解释预算使用、剩余和超支',
          icon: Icons.savings_rounded,
          color: LedgerPalette.mintSoft,
          onTap: () => context.push('/ai/budget-review'),
        ),
        _Entry(
          key: const Key('ai-plan-entry'),
          title: '财务规划建议',
          subtitle: '基于目标和确定性缺口给出一般建议',
          icon: Icons.flag_rounded,
          color: LedgerPalette.honeySoft,
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
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(backgroundColor: color, child: Icon(icon)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
