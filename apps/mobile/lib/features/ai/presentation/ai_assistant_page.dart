import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_ledger/app/ledger_theme.dart';
import 'package:smart_ledger/app/ledger_visuals.dart';
import 'package:smart_ledger/core/money/money.dart';
import 'package:smart_ledger/features/ai/domain/ai_models.dart';
import 'package:smart_ledger/features/ai/presentation/ai_providers.dart';
import 'package:smart_ledger/features/ai/presentation/ai_result_panel.dart';
import 'package:smart_ledger/features/home/presentation/home_providers.dart';
import 'package:smart_ledger/features/telemetry/presentation/telemetry_providers.dart';
import 'package:smart_ledger/features/transactions/domain/ledger_transaction.dart';
import 'package:uuid/uuid.dart';

class AiAssistantPage extends ConsumerStatefulWidget {
  const AiAssistantPage({super.key});

  @override
  ConsumerState<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends ConsumerState<AiAssistantPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  ChatResult? _lastResult;
  ImageAnalysisResult? _imageResult;
  Uint8List? _preview;
  bool _includeToday = false;
  bool _includeMonth = false;
  bool _includeBudget = false;
  bool _loading = false;
  String? _error;
  int _requestId = 0;
  String? _lastChatOperationId;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quota = ref.watch(aiQuotaProvider);
    final quotaExhausted = quota.valueOrNull?.isExhausted ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 小伙伴'),
        actions: [
          IconButton(
            key: const Key('ai-new-session'),
            tooltip: '新对话',
            onPressed: _newSession,
            icon: const Icon(Icons.add_comment_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              key: const Key('ai-chat-list'),
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                const _IntroCard(),
                AiQuotaPanel(quota: quota),
                const _LegacyTools(),
                _ContextChooser(
                  includeToday: _includeToday,
                  includeMonth: _includeMonth,
                  includeBudget: _includeBudget,
                  onToday: (value) => setState(() => _includeToday = value),
                  onMonth: (value) => setState(() => _includeMonth = value),
                  onBudget: (value) => setState(() => _includeBudget = value),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 7,
                  children: [
                    for (final prompt in const [
                      '帮我看看最近的消费习惯',
                      '我该怎样开始控制支出？',
                      '给我三个温和可行的建议',
                    ])
                      ActionChip(
                        label: Text(prompt),
                        onPressed: _loading || quotaExhausted
                            ? null
                            : () => _send(prompt),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final message in _messages)
                  _MessageBubble(message: message),
                if (_lastResult != null) _ResultCard(result: _lastResult!),
                if (_preview != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.memory(
                      _preview!,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                if (_imageResult != null)
                  _ImageResultCard(result: _imageResult!),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (_error != null)
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _error!,
                              key: const Key('ai-chat-error'),
                            ),
                          ),
                          TextButton(
                            onPressed: quotaExhausted ? null : _retry,
                            child: const Text('重试'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton.filledTonal(
                    key: const Key('ai-image-picker'),
                    tooltip: '选择财务截图',
                    onPressed: _loading || quotaExhausted ? null : _pickImage,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      key: const Key('ai-chat-input'),
                      controller: _controller,
                      enabled: !_loading,
                      maxLines: 4,
                      minLines: 1,
                      maxLength: 2000,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _loading || quotaExhausted
                          ? null
                          : (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: '问问账本小伙伴…',
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: const Key('ai-chat-submit'),
                    tooltip: _loading ? '停止等待' : '发送',
                    onPressed: _loading
                        ? _stop
                        : quotaExhausted
                        ? null
                        : _send,
                    icon: Icon(
                      _loading
                          ? Icons.stop_rounded
                          : Icons.arrow_upward_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send([String? preset, String? retryRequestId]) async {
    final content = (preset ?? _controller.text).trim();
    if (content.isEmpty || _loading) return;
    _controller.clear();
    final requestId = ++_requestId;
    final operationId = retryRequestId ?? const Uuid().v4();
    _lastChatOperationId = operationId;
    setState(() {
      _messages.add(ChatMessage(role: ChatRole.user, content: content));
      if (_messages.length > 16) {
        _messages.removeRange(0, _messages.length - 16);
      }
      _loading = true;
      _error = null;
      _lastResult = null;
    });
    _record(
      'ai_chat_submitted',
      properties: {'message_count': _messages.length, 'has_image': false},
    );
    try {
      final result = await ref
          .read(aiApiClientProvider)
          .chat(
            messages: List.unmodifiable(_messages),
            context: _buildContext(),
            requestId: operationId,
          );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _lastResult = result;
        _messages.add(
          ChatMessage(role: ChatRole.assistant, content: result.answer),
        );
        if (_messages.length > 16) {
          _messages.removeRange(0, _messages.length - 16);
        }
      });
      _record(
        'ai_chat_success',
        properties: {'message_count': _messages.length},
      );
      ref.invalidate(aiQuotaProvider);
    } on AiFailure catch (failure) {
      if (!mounted || requestId != _requestId) return;
      setState(() => _error = failure.message);
      _record(
        'ai_chat_failed',
        properties: {'failure_kind': failure.kind.name},
      );
      if (failure.kind == AiFailureKind.quotaExceeded) {
        ref.invalidate(aiQuotaProvider);
      }
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() => _error = 'AI 暂时没有回应，请稍后再试');
      _record('ai_chat_failed', properties: const {'failure_kind': 'unknown'});
    } finally {
      if (mounted && requestId == _requestId) setState(() => _loading = false);
      _scrollToEnd();
    }
  }

  Map<String, String> _buildContext() {
    final context = <String, String>{};
    if (_includeToday) {
      final items = ref.read(todayTransactionsProvider).valueOrNull ?? const [];
      context['today_summary'] = _transactionSummary('今天', items);
    }
    if (_includeMonth) {
      final items =
          ref.read(homeMonthTransactionsProvider).valueOrNull ?? const [];
      context['month_summary'] = _transactionSummary('本月', items);
    }
    if (_includeBudget) {
      final budgets = ref.read(homeBudgetsProvider).valueOrNull ?? const [];
      context['budget_summary'] = budgets.isEmpty
          ? '本月没有启用中的预算。'
          : budgets
                .take(10)
                .map(
                  (item) =>
                      '${item.name}：已用${item.usedMinor}分，'
                      '预算${item.amountMinor}分，剩余${item.remainingMinor}分',
                )
                .join('；');
    }
    return context;
  }

  String _transactionSummary(String label, List<LedgerTransaction> items) {
    final summary = summarizeTransactions(items);
    return '$label共${items.length}笔；收入${summary.incomeMinor}分；'
        '支出${summary.expenseMinor}分；净额${summary.netMinor}分。';
  }

  Future<void> _pickImage() async {
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
      _imageResult = null;
    });
    try {
      final image = await ref
          .read(imageProcessingServiceProvider)
          .pickAndProcess();
      if (image == null || !mounted || requestId != _requestId) return;
      setState(() => _preview = image.bytes);
      _record(
        'image_analysis_submitted',
        properties: const {'has_image': true},
      );
      final result = await ref
          .read(aiApiClientProvider)
          .analyzeImage(
            bytes: image.bytes,
            filename: image.filename,
            mimeType: image.mimeType,
            requestId: const Uuid().v4(),
          );
      if (!mounted || requestId != _requestId) return;
      setState(() => _imageResult = result);
      _record('image_analysis_success', properties: const {'has_image': true});
      ref.invalidate(aiQuotaProvider);
    } on FormatException catch (error) {
      if (mounted && requestId == _requestId) {
        setState(() => _error = error.message.toString());
      }
      _record(
        'image_analysis_failed',
        properties: const {'failure_kind': 'validation'},
      );
    } on AiFailure catch (failure) {
      if (mounted && requestId == _requestId) {
        setState(() => _error = failure.message);
      }
      _record(
        'image_analysis_failed',
        properties: {'failure_kind': failure.kind.name},
      );
      if (failure.kind == AiFailureKind.quotaExceeded) {
        ref.invalidate(aiQuotaProvider);
      }
    } catch (_) {
      if (mounted && requestId == _requestId) {
        setState(() => _error = '图片分析暂不可用，请稍后重试');
      }
      _record(
        'image_analysis_failed',
        properties: const {'failure_kind': 'unknown'},
      );
    } finally {
      if (mounted && requestId == _requestId) setState(() => _loading = false);
      _scrollToEnd();
    }
  }

  void _stop() {
    _requestId++;
    setState(() {
      _loading = false;
      _error = '已停止等待；服务端不会写入或修改账本。';
    });
  }

  void _retry() {
    final index = _messages.lastIndexWhere(
      (message) => message.role == ChatRole.user,
    );
    if (index < 0) return;
    final content = _messages[index].content;
    setState(() {
      _messages.removeAt(index);
      _error = null;
    });
    if (content.isNotEmpty) _send(content, _lastChatOperationId);
  }

  void _newSession() {
    _requestId++;
    setState(() {
      _messages.clear();
      _lastResult = null;
      _imageResult = null;
      _preview = null;
      _error = null;
      _loading = false;
      _lastChatOperationId = null;
    });
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _record(String name, {Map<String, Object> properties = const {}}) {
    unawaited(
      ref
          .read(telemetryCoordinatorProvider.future)
          .then(
            (coordinator) => coordinator.record(name, properties: properties),
          ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) => const Card(
    color: LedgerPalette.honeySoft,
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          LedgerBuddy(size: 56),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '想看懂哪一部分呢？',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4),
                Text('默认不附带账本。只有勾选的本地汇总会随本次对话发送。'),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ContextChooser extends StatelessWidget {
  const _ContextChooser({
    required this.includeToday,
    required this.includeMonth,
    required this.includeBudget,
    required this.onToday,
    required this.onMonth,
    required this.onBudget,
  });

  final bool includeToday;
  final bool includeMonth;
  final bool includeBudget;
  final ValueChanged<bool> onToday;
  final ValueChanged<bool> onMonth;
  final ValueChanged<bool> onBudget;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    key: const Key('ai-context-chooser'),
    title: const Text('本次可选上下文'),
    subtitle: Text(
      [includeToday, includeMonth, includeBudget].where((v) => v).isEmpty
          ? '未附带账本数据'
          : '仅发送已勾选的聚合摘要',
    ),
    children: [
      CheckboxListTile(
        value: includeToday,
        onChanged: (v) => onToday(v ?? false),
        title: const Text('今天收支汇总'),
      ),
      CheckboxListTile(
        value: includeMonth,
        onChanged: (v) => onMonth(v ?? false),
        title: const Text('本月收支汇总'),
      ),
      CheckboxListTile(
        value: includeBudget,
        onChanged: (v) => onBudget(v ?? false),
        title: const Text('本月预算汇总'),
      ),
    ],
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final user = message.role == ChatRole.user;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 330),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: user ? LedgerPalette.coralSoft : LedgerPalette.paper,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(message.content),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final ChatResult result;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(result.title, style: Theme.of(context).textTheme.titleMedium),
          for (final value in result.insights)
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text('• $value'),
            ),
          for (final value in result.actions)
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text('建议：$value'),
            ),
          for (final value in result.warnings)
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text('注意：$value'),
            ),
          const SizedBox(height: 8),
          Text(result.disclaimer, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}

class _ImageResultCard extends StatelessWidget {
  const _ImageResultCard({required this.result});

  final ImageAnalysisResult result;

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('image-analysis-result'),
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('截图分析', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(result.summary),
          for (final value in result.importantInformation) Text('• $value'),
          for (final value in result.riskFlags) Text('风险提示：$value'),
          if (result.transactionDrafts.isNotEmpty) ...[
            const Divider(),
            const Text(
              '识别到的记账草稿（待确认）',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            for (final draft in result.transactionDrafts)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${draft['transaction_type'] == 'income' ? '收入' : '支出'} '
                  '${Money.fromMinor(draft['amount_minor']! as int).format()}',
                ),
                subtitle: Text(
                  '${draft['category_candidate'] ?? '未确定分类'} · 待确认，不会自动保存',
                ),
              ),
          ],
          Text(result.disclaimer, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}

class _LegacyTools extends StatelessWidget {
  const _LegacyTools();

  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: [
        ListTile(
          key: const Key('ai-monthly-entry'),
          title: const Text('月度消费总结'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/ai/monthly-summary'),
        ),
        ListTile(
          key: const Key('ai-budget-entry'),
          title: const Text('预算执行解释'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/ai/budget-review'),
        ),
        ListTile(
          key: const Key('ai-plan-entry'),
          title: const Text('财务规划建议'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/ai/financial-plan'),
        ),
      ],
    ),
  );
}
