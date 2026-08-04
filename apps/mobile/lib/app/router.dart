import 'package:flutter/foundation.dart';
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
import 'package:smart_ledger/features/auth/domain/auth_session.dart';
import 'package:smart_ledger/features/auth/presentation/account_security_page.dart';
import 'package:smart_ledger/features/auth/presentation/auth_providers.dart';
import 'package:smart_ledger/features/auth/presentation/auth_splash_page.dart';
import 'package:smart_ledger/features/auth/presentation/local_data_binding_page.dart';
import 'package:smart_ledger/features/auth/presentation/login_page.dart';
import 'package:smart_ledger/features/transactions/presentation/ledger_home_page.dart';
import 'package:smart_ledger/features/transactions/presentation/details_page.dart';
import 'package:smart_ledger/features/transactions/presentation/transaction_detail_page.dart';
import 'package:smart_ledger/features/transactions/presentation/transaction_form_page.dart';
import 'package:smart_ledger/app/ledger_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefreshNotifier();
  ref.listen<AuthState>(authControllerProvider, (_, _) => refresh.notify());
  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) =>
        authRedirect(ref.read(authControllerProvider), state.matchedLocation),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const AuthSplashPage(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/bind-local-data',
        builder: (context, state) => const LocalDataBindingPage(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            LedgerShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const LedgerHomePage(),
          ),
          GoRoute(
            path: '/details',
            builder: (context, state) => const DetailsPage(),
          ),
          GoRoute(
            path: '/transactions/new',
            builder: (context, state) => TransactionFormPage(
              initialCategoryId: state.uri.queryParameters['category'],
            ),
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsPage(),
          ),
          GoRoute(
            path: '/ai',
            builder: (context, state) => const AiAssistantPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/accounts',
        builder: (context, state) => const AccountsPage(),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoriesPage(),
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
        path: '/ai/monthly-summary',
        builder: (context, state) => const AiMonthlySummaryPage(),
      ),
      GoRoute(
        path: '/ai/budget-review',
        builder: (context, state) => const AiBudgetReviewPage(),
      ),
      GoRoute(
        path: '/ai/financial-plan',
        builder: (context, state) => const AiFinancialPlanPage(),
      ),
      GoRoute(
        path: '/account-security',
        builder: (context, state) => const AccountSecurityPage(),
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
  ref.onDispose(refresh.dispose);
  return router;
});

final class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

String? authRedirect(AuthState auth, String location) {
  final isAuthRoute =
      location == '/splash' ||
      location == '/login' ||
      location == '/bind-local-data';
  return switch (auth.phase) {
    AuthPhase.initializing => location == '/splash' ? null : '/splash',
    AuthPhase.unauthenticated => location == '/login' ? null : '/login',
    AuthPhase.bindingRequired =>
      location == '/bind-local-data' ? null : '/bind-local-data',
    AuthPhase.authenticated => isAuthRoute ? '/' : null,
  };
}
