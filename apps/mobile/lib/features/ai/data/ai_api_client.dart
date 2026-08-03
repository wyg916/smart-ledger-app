import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:smart_ledger/features/ai/domain/ai_models.dart';
import 'package:smart_ledger/features/ai/domain/ai_requests.dart';

abstract interface class AiApiClient {
  Future<AiResult> monthlySummary(MonthlyAiRequest request);
  Future<AiResult> budgetReview(BudgetAiRequest request);
  Future<AiResult> financialPlan(FinancialPlanAiRequest request);
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

  Future<AiResult> _post(String path, Map<String, Object?> payload) async {
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
      if (response.statusCode == 200) return _decode(response.body);
      final code = _errorCode(response.body);
      if (response.statusCode == 429 || code == 'AI_RATE_LIMITED') {
        throw const AiFailure(AiFailureKind.rateLimited, '请求过于频繁，请稍后重试');
      }
      if (code == 'AI_DISABLED' || code == 'AI_PRODUCTION_AUTH_REQUIRED') {
        throw const AiFailure(AiFailureKind.disabled, 'AI 服务当前未启用');
      }
      if (code == 'AI_INVALID_RESPONSE') {
        throw const AiFailure(AiFailureKind.invalidResponse, 'AI 返回格式无效');
      }
      if (code == 'AI_UPSTREAM_TIMEOUT') {
        throw const AiFailure(AiFailureKind.timeout, 'AI 请求超时');
      }
      throw const AiFailure(AiFailureKind.unavailable, 'AI 服务暂不可用');
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

  String? _errorCode(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, Object?>;
      final error = decoded['error'] as Map<String, Object?>?;
      return error?['code'] as String?;
    } on FormatException {
      return null;
    }
  }

  AiResult _decode(String body) {
    final decoded = jsonDecode(body) as Map<String, Object?>;
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
