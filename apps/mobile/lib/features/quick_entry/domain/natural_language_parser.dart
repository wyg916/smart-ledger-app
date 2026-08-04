import 'package:smart_ledger/core/money/money.dart';
import 'package:smart_ledger/core/time/ledger_time.dart';
import 'package:smart_ledger/features/quick_entry/domain/transaction_draft.dart';
import 'package:smart_ledger/features/transactions/domain/ledger_transaction.dart';

final class NaturalLanguageTransactionParser {
  const NaturalLanguageTransactionParser();

  TransactionDraft? parse({
    required String text,
    required DateTime nowUtc,
    required String timeZoneId,
  }) {
    final input = text.trim();
    if (input.isEmpty) return null;
    final amountTexts = _amountCandidates(input);
    if (amountTexts.isEmpty) return null;
    int amountMinor;
    try {
      amountMinor = Money.parsePositive(amountTexts.first).minor;
    } catch (_) {
      return null;
    }

    final category = _category(input);
    final type = _type(input, category);
    final date = _occurredAt(input, nowUtc, timeZoneId);
    final warnings = <String>[
      if (amountTexts.length > 1) '识别到多个金额，请核对采用的金额',
      if (category == null) '没有找到明确分类，请选择分类',
      if (date.ambiguous) '日期表达可能有歧义，请核对日期',
    ];
    final confidence = warnings.isEmpty ? 0.96 : 0.62;
    return TransactionDraft(
      type: type,
      amountMinor: amountMinor,
      currencyCode: 'CNY',
      categoryCandidate: category,
      occurredAtUtc: date.value,
      timeZoneId: timeZoneId,
      note: input,
      confidence: confidence,
      needsConfirmation: true,
      warnings: warnings,
      source: 'local',
    );
  }

  List<String> _amountCandidates(String input) {
    final withUnit = RegExp(
      r'(?:[¥￥]\s*)?(\d+(?:\.\d{1,2})?)\s*(?:元|块钱|块)',
    ).allMatches(input).map((match) => match.group(1)!).toList();
    if (withUnit.isNotEmpty) return withUnit;
    final plain = RegExp(
      r'\d+(?:\.\d{1,2})?',
    ).allMatches(input).map((match) => match.group(0)!).toList();
    return plain.isEmpty ? const [] : [plain.last];
  }

  String? _category(String input) {
    const mapping = <String, List<String>>{
      '餐饮': ['早餐', '午餐', '晚餐', '早饭', '午饭', '晚饭', '奶茶', '咖啡', '吃饭'],
      '交通': ['打车', '出租车', '公交', '地铁', '交通卡', '加油', '停车'],
      '购物': ['购物', '买衣服', '网购'],
      '住房': ['房租', '房贷'],
      '医疗': ['看病', '买药', '医疗'],
      '教育': ['学费', '课程', '教育'],
      '娱乐': ['电影', '游戏', '娱乐'],
      '旅行': ['酒店', '机票', '旅行'],
      '工资': ['工资', '薪水'],
      '奖金': ['奖金', '年终奖'],
      '兼职': ['兼职'],
      '报销': ['报销'],
      '红包礼金': ['红包', '礼金'],
      '退款': ['退款'],
      '理财收益': ['利息', '理财收益'],
    };
    for (final entry in mapping.entries) {
      if (entry.value.any(input.contains)) return entry.key;
    }
    return null;
  }

  LedgerTransactionType _type(String input, String? category) {
    const incomeWords = ['收入', '到账', '收到', '工资', '奖金', '兼职', '报销', '退款', '收益'];
    if (incomeWords.any(input.contains) ||
        const {
          '工资',
          '奖金',
          '兼职',
          '报销',
          '退款',
          '理财收益',
          '红包礼金',
        }.contains(category)) {
      return LedgerTransactionType.income;
    }
    return LedgerTransactionType.expense;
  }

  ({DateTime value, bool ambiguous}) _occurredAt(
    String input,
    DateTime nowUtc,
    String timeZoneId,
  ) {
    final localToday = localDateForUtc(nowUtc, timeZoneId);
    DateTime localDate = localToday;
    var ambiguous = false;
    if (input.contains('前天')) {
      localDate = localToday.subtract(const Duration(days: 2));
    } else if (input.contains('昨天')) {
      localDate = localToday.subtract(const Duration(days: 1));
    } else {
      final explicit = RegExp(
        r'(\d{4})[-年/](\d{1,2})[-月/](\d{1,2})日?',
      ).firstMatch(input);
      if (explicit != null) {
        final candidate = DateTime(
          int.parse(explicit.group(1)!),
          int.parse(explicit.group(2)!),
          int.parse(explicit.group(3)!),
        );
        if (candidate.year == int.parse(explicit.group(1)!) &&
            candidate.month == int.parse(explicit.group(2)!) &&
            candidate.day == int.parse(explicit.group(3)!)) {
          localDate = candidate;
        } else {
          ambiguous = true;
        }
      }
    }
    if (localDate == localToday) {
      return (value: nowUtc.toUtc(), ambiguous: ambiguous);
    }
    final range = dayRangeInTimeZone(localDate, timeZoneId);
    return (
      value: range.start.add(const Duration(hours: 12)),
      ambiguous: ambiguous,
    );
  }
}
