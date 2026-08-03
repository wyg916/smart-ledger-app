import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ledger/core/money/money.dart';
import 'package:smart_ledger/features/ai/domain/ai_models.dart';
import 'package:smart_ledger/features/ai/domain/ai_request_factories.dart';
import 'package:smart_ledger/features/ai/presentation/ai_providers.dart';
import 'package:smart_ledger/features/ai/presentation/ai_result_panel.dart';

class AiFinancialPlanPage extends ConsumerStatefulWidget {
  const AiFinancialPlanPage({super.key});

  @override
  ConsumerState<AiFinancialPlanPage> createState() =>
      _AiFinancialPlanPageState();
}

class _AiFinancialPlanPageState extends ConsumerState<AiFinancialPlanPage> {
  final _goal = TextEditingController(text: '应急金');
  final _target = TextEditingController(text: '10000.00');
  final _current = TextEditingController(text: '1000.00');
  final _monthly = TextEditingController(text: '500.00');
  final _months = TextEditingController(text: '12');
  String _risk = 'conservative';
  bool _loading = false;
  AiResult? _result;
  AiFailure? _failure;
  String? _formError;

  @override
  void dispose() {
    _goal.dispose();
    _target.dispose();
    _current.dispose();
    _monthly.dispose();
    _months.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    try {
      final target = Money.parsePositive(_target.text).minor;
      final current = Money.parseSigned(_current.text).minor;
      final monthly = Money.parseSigned(_monthly.text).minor;
      final months = int.parse(_months.text);
      if (_goal.text.trim().isEmpty ||
          current < 0 ||
          monthly < 0 ||
          months < 1) {
        throw const FormatException();
      }
      final request = financialPlanAiRequest(
        goalName: _goal.text.trim(),
        targetMinor: target,
        deadlineMonths: months,
        currentMinor: current,
        monthlyContributionMinor: monthly,
        riskPreference: _risk,
      );
      setState(() {
        _loading = true;
        _failure = null;
        _formError = null;
      });
      final result = await ref.read(aiApiClientProvider).financialPlan(request);
      if (!mounted) return;
      setState(() => _result = result);
    } on AiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _failure = failure);
    } catch (_) {
      if (!mounted) return;
      setState(() => _formError = '请填写有效的非负金额和期限');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('财务规划建议')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _field(_goal, '目标名称', 'plan-goal'),
        _field(_target, '目标金额', 'plan-target'),
        _field(_current, '当前金额', 'plan-current'),
        _field(_monthly, '每月可投入金额', 'plan-monthly'),
        _field(_months, '目标期限（月）', 'plan-months'),
        DropdownButtonFormField<String>(
          key: const Key('plan-risk'),
          initialValue: _risk,
          decoration: const InputDecoration(labelText: '风险偏好'),
          items: const [
            DropdownMenuItem(value: 'conservative', child: Text('保守')),
            DropdownMenuItem(value: 'balanced', child: Text('平衡')),
            DropdownMenuItem(value: 'growth', child: Text('成长')),
          ],
          onChanged: (value) => setState(() => _risk = value ?? _risk),
        ),
        if (_formError case final error?)
          Text(error, key: const Key('plan-form-error')),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('generate-plan-ai'),
          onPressed: _loading ? null : _run,
          child: const Text('生成规划建议'),
        ),
        if (_loading)
          const Center(
            key: Key('ai-loading'),
            child: CircularProgressIndicator(),
          ),
        if (_failure case final failure?)
          AiFailurePanel(failure: failure, onRetry: _run),
        if (_result case final result?) AiResultPanel(result: result),
      ],
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label,
    String keyName,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        key: Key(keyName),
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
