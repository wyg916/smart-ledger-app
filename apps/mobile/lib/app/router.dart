import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_ledger/features/accounts/presentation/accounts_page.dart';
import 'package:smart_ledger/features/categories/presentation/categories_page.dart';
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
