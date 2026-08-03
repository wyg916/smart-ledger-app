import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_ledger/features/accounts/presentation/accounts_page.dart';
import 'package:smart_ledger/features/analytics/presentation/analytics_page.dart';
import 'package:smart_ledger/features/budgets/presentation/budget_detail_page.dart';
import 'package:smart_ledger/features/budgets/presentation/budget_form_page.dart';
import 'package:smart_ledger/features/budgets/presentation/budgets_page.dart';
import 'package:smart_ledger/features/categories/presentation/categories_page.dart';
import 'package:smart_ledger/features/ai/presentation/ai_assistant_page.dart';
import 'package:smart_ledger/features/ai/presentation/ai_budget_review_page.dart';
import 'package:smart_ledger/features/ai/presentation/ai_financial_plan_page.dart';
import 'package:smart_ledger/features/ai/presentation/ai_monthly_summary_page.dart';
import 'package:smart_ledger/features/transactions/presentation/ledger_home_page.dart';
import 'package:smart_ledger/features/transactions/presentation/transaction_detail_page.dart';
import 'package:smart_ledger/features/transactions/presentation/transaction_form_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LedgerHomePage()),
      GoRoute(
        path: '/accounts',
        builder: (context, state) => const AccountsPage(),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoriesPage(),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const AnalyticsPage(),
      ),
      GoRoute(
        path: '/budgets',
        builder: (context, state) => const BudgetsPage(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const BudgetFormPage(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                BudgetDetailPage(budgetId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) =>
                    BudgetFormPage(budgetId: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/ai',
        builder: (context, state) => const AiAssistantPage(),
        routes: [
          GoRoute(
            path: 'monthly-summary',
            builder: (context, state) => const AiMonthlySummaryPage(),
          ),
          GoRoute(
            path: 'budget-review',
            builder: (context, state) => const AiBudgetReviewPage(),
          ),
          GoRoute(
            path: 'financial-plan',
            builder: (context, state) => const AiFinancialPlanPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/transactions/new',
        builder: (context, state) => const TransactionFormPage(),
      ),
      GoRoute(
        path: '/transactions/:id',
        builder: (context, state) =>
            TransactionDetailPage(transactionId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) =>
                TransactionFormPage(transactionId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
