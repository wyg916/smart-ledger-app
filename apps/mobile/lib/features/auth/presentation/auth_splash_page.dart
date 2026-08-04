import 'package:flutter/material.dart';

class AuthSplashPage extends StatelessWidget {
  const AuthSplashPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_balance_wallet_rounded, size: 52),
          SizedBox(height: 16),
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('正在安全恢复登录状态…'),
        ],
      ),
    ),
  );
}
