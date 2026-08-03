import 'package:drift/drift.dart';
import 'package:smart_ledger/core/database/app_database.dart';
import 'package:smart_ledger/core/database/local_ledger_bootstrapper.dart';
import 'package:smart_ledger/core/errors/ledger_exception.dart';
import 'package:smart_ledger/core/time/ledger_time.dart';
import 'package:smart_ledger/features/analytics/domain/ledger_analytics.dart';

final class DriftAnalyticsRepository implements AnalyticsRepository {
  const DriftAnalyticsRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<AnalyticsSnapshot> watch(AnalyticsFilter filter) async* {
    final ledger =
        await (_database.select(_database.ledgers)..where(
              (row) =>
                  row.id.equals(defaultLedgerId) & row.deletedAtMs.isNull(),
            ))
            .getSingleOrNull();
    if (ledger == null) {
      throw const LedgerException('LEDGER_NOT_FOUND', '账本不存在');
    }
    final currentRange = monthRangeInTimeZone(filter.month, ledger.timeZoneId);
    final previousRange = monthRangeInTimeZone(
      filter.month.previous,
      ledger.timeZoneId,
    );
    final clauses = <String>[
      't.ledger_id = ?',
      't.deleted_at_ms IS NULL',
      't.occurred_at_utc_ms >= ?',
      't.occurred_at_utc_ms < ?',
      "t.transaction_type IN ('income', 'expense')",
    ];
    final variables = <Variable<Object>>[
      Variable.withString(defaultLedgerId),
      Variable.withInt(previousRange.start.millisecondsSinceEpoch),
      Variable.withInt(currentRange.endExclusive.millisecondsSinceEpoch),
    ];
    if (filter.accountId case final id?) {
      clauses.add('t.account_id = ?');
      variables.add(Variable.withString(id));
    }
    if (filter.categoryId case final id?) {
      clauses.add('t.category_id = ?');
      variables.add(Variable.withString(id));
    }
    yield* _database
        .customSelect(
          '''
          SELECT t.transaction_type, t.amount_minor, t.occurred_at_utc_ms,
            t.category_id, c.name AS category_name,
            c.sort_order AS category_sort, c.created_at_ms AS category_created
          FROM transactions t
          LEFT JOIN categories c ON c.id = t.category_id
          WHERE ${clauses.join(' AND ')}
          ORDER BY t.occurred_at_utc_ms ASC, t.id ASC
          ''',
          variables: variables,
          readsFrom: {
            _database.ledgerTransactions,
            _database.categories,
            _database.accounts,
          },
        )
        .watch()
        .asyncMap(
          (rows) =>
              _buildSnapshot(rows, filter, ledger.timeZoneId, currentRange),
        );
  }

  Future<AnalyticsSnapshot> _buildSnapshot(
    List<QueryRow> rows,
    AnalyticsFilter filter,
    String timeZoneId,
    UtcMonthRange currentRange,
  ) async {
    var income = 0;
    var expense = 0;
    var previousIncome = 0;
    var previousExpense = 0;
    var hasPreviousIncome = false;
    var hasPreviousExpense = false;
    final daily = <String, (int, int)>{};
    final incomeCategories = <String, _RankAccumulator>{};
    final expenseCategories = <String, _RankAccumulator>{};

    for (final row in rows) {
      final type = row.read<String>('transaction_type');
      final amount = row.read<int>('amount_minor');
      final occurred = DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('occurred_at_utc_ms'),
        isUtc: true,
      );
      final isCurrent = !occurred.isBefore(currentRange.start);
      if (!isCurrent) {
        if (type == 'income') {
          previousIncome += amount;
          hasPreviousIncome = true;
        } else {
          previousExpense += amount;
          hasPreviousExpense = true;
        }
        continue;
      }
      final day = localDayForUtc(occurred, timeZoneId);
      final dayValue = daily[day] ?? (0, 0);
      final categoryId = row.read<String>('category_id');
      final accumulator = _RankAccumulator(
        id: categoryId,
        name: row.readNullable<String>('category_name') ?? '已停用分类',
        sortOrder: row.readNullable<int>('category_sort') ?? 0,
        createdAtMs: row.readNullable<int>('category_created') ?? 0,
      );
      if (type == 'income') {
        income += amount;
        daily[day] = (dayValue.$1 + amount, dayValue.$2);
        incomeCategories.update(
          categoryId,
          (value) => value..amount += amount,
          ifAbsent: () => accumulator..amount = amount,
        );
      } else {
        expense += amount;
        daily[day] = (dayValue.$1, dayValue.$2 + amount);
        expenseCategories.update(
          categoryId,
          (value) => value..amount += amount,
          ifAbsent: () => accumulator..amount = amount,
        );
      }
    }

    final trend = List.generate(filter.month.daysInMonth, (index) {
      final date =
          '${filter.month}-'
          '${(index + 1).toString().padLeft(2, '0')}';
      final value = daily[date] ?? (0, 0);
      return DailyTrendPoint(
        localDate: date,
        incomeMinor: value.$1,
        expenseMinor: value.$2,
      );
    });
    return AnalyticsSnapshot(
      month: filter.month,
      income: MonthMetric(
        currentMinor: income,
        previousMinor: previousIncome,
        hasBaseline: hasPreviousIncome,
      ),
      expense: MonthMetric(
        currentMinor: expense,
        previousMinor: previousExpense,
        hasBaseline: hasPreviousExpense,
      ),
      dailyTrend: trend,
      expenseRanking: _rank(expenseCategories.values),
      incomeRanking: _rank(incomeCategories.values),
      accounts: await _accountBalances(filter.accountId),
    );
  }

  List<CategoryRank> _rank(Iterable<_RankAccumulator> values) {
    final sorted = values.toList()
      ..sort((left, right) {
        final amount = right.amount.compareTo(left.amount);
        if (amount != 0) return amount;
        final order = left.sortOrder.compareTo(right.sortOrder);
        if (order != 0) return order;
        final created = left.createdAtMs.compareTo(right.createdAtMs);
        if (created != 0) return created;
        return left.id.compareTo(right.id);
      });
    return sorted
        .map(
          (item) => CategoryRank(
            categoryId: item.id,
            categoryName: item.name,
            amountMinor: item.amount,
          ),
        )
        .toList(growable: false);
  }

  Future<List<AccountBalanceOverview>> _accountBalances(
    String? accountId,
  ) async {
    final accountClause = accountId == null ? '' : 'AND a.id = ?';
    final rows = await _database
        .customSelect(
          '''
      SELECT a.id, a.name, a.enabled,
        a.opening_balance_minor + COALESCE(SUM(CASE
          WHEN t.transaction_type = 'income' AND t.account_id = a.id THEN t.amount_minor
          WHEN t.transaction_type = 'expense' AND t.account_id = a.id THEN -t.amount_minor
          WHEN t.transaction_type = 'transfer' AND t.account_id = a.id THEN -t.amount_minor
          WHEN t.transaction_type = 'transfer' AND t.to_account_id = a.id THEN t.amount_minor
          ELSE 0 END), 0) AS balance_minor
      FROM accounts a
      LEFT JOIN transactions t
        ON (t.account_id = a.id OR t.to_account_id = a.id)
        AND t.deleted_at_ms IS NULL
      WHERE a.ledger_id = ? AND a.deleted_at_ms IS NULL $accountClause
      GROUP BY a.id
      ORDER BY a.sort_order ASC, a.created_at_ms ASC, a.id ASC
      ''',
          variables: [
            Variable.withString(defaultLedgerId),
            if (accountId != null) Variable.withString(accountId),
          ],
          readsFrom: {_database.accounts, _database.ledgerTransactions},
        )
        .get();
    return rows
        .map(
          (row) => AccountBalanceOverview(
            accountId: row.read<String>('id'),
            accountName: row.read<String>('name'),
            balanceMinor: row.read<int>('balance_minor'),
            enabled: row.read<int>('enabled') == 1,
          ),
        )
        .toList(growable: false);
  }
}

final class _RankAccumulator {
  _RankAccumulator({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.createdAtMs,
  });

  final String id;
  final String name;
  final int sortOrder;
  final int createdAtMs;
  int amount = 0;
}
