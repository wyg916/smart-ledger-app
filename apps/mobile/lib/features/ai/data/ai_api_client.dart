import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:smart_ledger/features/ai/domain/ai_models.dart';
import 'package:smart_ledger/features/ai/domain/ai_requests.dart';
import 'package:smart_ledger/features/categories/domain/ledger_category.dart';
import 'package:smart_ledger/features/quick_entry/domain/transaction_draft.dart';
import 'package:smart_ledger/features/transactions/domain/ledger_transaction.dart';

abstract interface class AiApiClient {
  Future<AiResult> monthlySummary(MonthlyAiRequest request);
  Future<AiResult> budgetReview(BudgetAiRequest request);
  Future<AiResult> financialPlan(FinancialPlanAiRequest request);
  Future<ChatResult> chat({
    required List<ChatMessage> messages,
    Map<String, String> context = const {},
  });
  Future<TransactionDraft> parseTransaction({
    required String text,
    required String timeZoneId,
    required List<LedgerCategory> categories,
  });
  Future<ImageAnalysisResult> analyzeImage({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  });
}

final class HttpAiApiClient implements AiApiClient {
  const HttpAiApiClient(this._client, this._baseUrl);

  final http.Client _client;
  final String _baseUrl;

  @override
  Future<AiResult> monthlySummary(MonthlyAiRequest request) =>
      _post('monthly-summary', request.toJson());

  @override
  Future<AiResult> budgetReview(BudgetAiRequest request) =>
      _post('budget-review', request.toJson());

  @override
  Future<AiResult> financialPlan(FinancialPlanAiRequest request) =>
      _post('financial-plan', request.toJson());

  @override
  Future<ChatResult> chat({
    required List<ChatMessage> messages,
    Map<String, String> context = const {},
  }) async {
    final body = await _postJson('chat', {
      'messages': messages
          .skip(messages.length > 16 ? messages.length - 16 : 0)
          .map((message) => message.toJson())
          .toList(),
      'context': context,
    });
    final result = body['result']! as Map<String, Object?>;
    return ChatResult(
      title: result['title']! as String,
      answer: result['answer']! as String,
      insights: (result['insights']! as List).cast<String>(),
      actions: (result['actions']! as List).cast<String>(),
      warnings: (result['warnings']! as List).cast<String>(),
      disclaimer: result['disclaimer']! as String,
    );
  }

  @override
  Future<TransactionDraft> parseTransaction({
    required String text,
    required String timeZoneId,
    required List<LedgerCategory> categories,
  }) async {
    final body = await _postJson('parse-transaction', {
      'text': text,
      'timezone': timeZoneId,
      'currency_code': 'CNY',
      'categories': categories
          .map(
            (category) => {
              'name': category.name,
              'transaction_type': category.type.name,
            },
          )
          .toList(),
    });
    final result = body['result']! as Map<String, Object?>;
    return TransactionDraft(
      type: LedgerTransactionType.values.byName(
        result['transaction_type']! as String,
      ),
      amountMinor: result['amount_minor']! as int,
      currencyCode: result['currency_code']! as String,
      categoryCandidate: result['category_candidate'] as String?,
      occurredAtUtc: DateTime.parse(result['occurred_at']! as String).toUtc(),
      timeZoneId: result['timezone']! as String,
      note: result['note']! as String,
      confidence: (result['confidence']! as num).toDouble(),
      needsConfirmation: result['needs_confirmation']! as bool,
      warnings: (result['warnings']! as List).cast<String>(),
      source: 'ai',
    );
  }

  @override
  Future<ImageAnalysisResult> analyzeImage({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) async {
    if (_baseUrl.isEmpty) {
      throw const AiFailure(AiFailureKind.disabled, 'AI 服务地址未配置');
    }
    try {
      final request =
          http.MultipartRequest(
              'POST',
              Uri.parse('$_baseUrl/api/v1/ai/analyze-image'),
            )
            ..files.add(
              http.MultipartFile.fromBytes(
                'image',
                bytes,
                filename: filename,
                contentType: MediaType.parse(mimeType),
              ),
            );
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 40));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        throw _failureFor(response.statusCode, response.body);
      }
      final body = jsonDecode(response.body) as Map<String, Object?>;
      final result = body['result']! as Map<String, Object?>;
      return ImageAnalysisResult(
        summary: result['summary']! as String,
        importantInformation: (result['important_information']! as List)
            .cast<String>(),
        riskFlags: (result['risk_flags']! as List).cast<String>(),
        transactionDrafts: (result['transaction_drafts']! as List)
            .map((item) => (item as Map<String, Object?>))
            .toList(growable: false),
        disclaimer: result['disclaimer']! as String,
      );
    } on TimeoutException {
      throw const AiFailure(AiFailureKind.timeout, 'AI 请求超时');
    } on SocketException {
      throw const AiFailure(AiFailureKind.offline, '网络不可用');
    } on http.ClientException {
      throw const AiFailure(AiFailureKind.offline, '无法连接 AI 服务');
    }
  }

  Future<AiResult> _post(String path, Map<String, Object?> payload) async {
    final body = await _postJson(path, payload);
    return _decodeMap(body);
  }

  Future<Map<String, Object?>> _postJson(
    String path,
    Map<String, Object?> payload,
  ) async {
    if (_baseUrl.isEmpty) {
      throw const AiFailure(AiFailureKind.disabled, 'AI 服务地址未配置');
    }
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/api/v1/ai/$path'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 40));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, Object?>;
      }
      throw _failureFor(response.statusCode, response.body);
    } on TimeoutException {
      throw const AiFailure(AiFailureKind.timeout, 'AI 请求超时');
    } on SocketException {
      throw const AiFailure(AiFailureKind.offline, '网络不可用');
    } on http.ClientException {
      throw const AiFailure(AiFailureKind.offline, '无法连接 AI 服务');
    } on FormatException {
      throw const AiFailure(AiFailureKind.invalidResponse, 'AI 返回格式无效');
    }
  }

  AiFailure _failureFor(int statusCode, String body) {
    final code = _errorCode(body);
    if (statusCode == 429 || code == 'AI_RATE_LIMITED') {
      return const AiFailure(AiFailureKind.rateLimited, '请求过于频繁，请稍后重试');
    }
    if (code == 'AI_DISABLED' || code == 'AI_PRODUCTION_AUTH_REQUIRED') {
      return const AiFailure(AiFailureKind.disabled, 'AI 服务当前未启用');
    }
    if (code == 'AI_INVALID_RESPONSE') {
      return const AiFailure(AiFailureKind.invalidResponse, 'AI 返回格式无效');
    }
    if (code == 'AI_UPSTREAM_TIMEOUT') {
      return const AiFailure(AiFailureKind.timeout, 'AI 请求超时');
    }
    return const AiFailure(AiFailureKind.unavailable, 'AI 服务暂不可用');
  }

  String? _errorCode(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, Object?>;
      final error = decoded['error'] as Map<String, Object?>?;
      return error?['code'] as String?;
    } on FormatException {
      return null;
    }
  }

  AiResult _decodeMap(Map<String, Object?> decoded) {
    final result = decoded['result'] as Map<String, Object?>;
    final insights = (result['insights'] as List<Object?>)
        .map((item) => item as Map<String, Object?>)
        .map(
          (item) => AiInsight(
            type: AiInsightType.values.byName(item['type'] as String),
            title: item['title'] as String,
            detail: item['detail'] as String,
            evidence: item['evidence'] as String,
          ),
        )
        .toList(growable: false);
    final actions = (result['actions'] as List<Object?>)
        .map((item) => item as Map<String, Object?>)
        .map(
          (item) => AiAction(
            priority: item['priority'] as int,
            title: item['title'] as String,
            detail: item['detail'] as String,
          ),
        )
        .toList(growable: false);
    return AiResult(
      title: result['title'] as String,
      summary: result['summary'] as String,
      insights: insights,
      actions: actions,
      riskTips: (result['risk_tips'] as List<Object?>).cast<String>(),
      disclaimer: result['disclaimer'] as String,
    );
  }
}
