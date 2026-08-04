import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ledger/app/ledger_theme.dart';
import 'package:smart_ledger/features/auth/presentation/auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _agreementsAccepted = false;
  bool _showReview = false;
  final _username = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CircleAvatar(
                      radius: 38,
                      backgroundColor: LedgerPalette.coralSoft,
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 42,
                        color: LedgerPalette.coral,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '欢迎使用智能记账',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '登录后才能打开本机账本。账单仍只保存在当前设备，不会自动上传。',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      key: const Key('phone-login'),
                      onPressed: auth.isBusy
                          ? null
                          : () => ref
                                .read(authControllerProvider.notifier)
                                .loginWithPhone(
                                  agreementsAccepted: _agreementsAccepted,
                                ),
                      icon: const Icon(Icons.sim_card_rounded),
                      label: const Text('本机号码一键登录'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const Key('wechat-login'),
                      onPressed: auth.isBusy
                          ? null
                          : () => ref
                                .read(authControllerProvider.notifier)
                                .loginWithWechat(
                                  agreementsAccepted: _agreementsAccepted,
                                ),
                      icon: const Icon(Icons.chat_bubble_rounded),
                      label: const Text('微信登录'),
                    ),
                    CheckboxListTile(
                      key: const Key('login-agreements'),
                      contentPadding: EdgeInsets.zero,
                      value: _agreementsAccepted,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text('我已阅读并同意'),
                          TextButton(
                            onPressed: () => _showPolicy(
                              context,
                              '隐私政策',
                              'https://www.znjz.site/privacy',
                            ),
                            child: const Text('隐私政策'),
                          ),
                          const Text('和'),
                          TextButton(
                            onPressed: () => _showPolicy(
                              context,
                              '用户协议',
                              'https://www.znjz.site/terms',
                            ),
                            child: const Text('用户协议'),
                          ),
                        ],
                      ),
                      onChanged: auth.isBusy
                          ? null
                          : (value) => setState(
                              () => _agreementsAccepted = value ?? false,
                            ),
                    ),
                    if (auth.isBusy) const LinearProgressIndicator(),
                    if (auth.errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        auth.errorMessage!,
                        key: const Key('login-error'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextButton(
                      key: const Key('other-login-methods'),
                      onPressed: auth.isBusy
                          ? null
                          : () => setState(() => _showReview = !_showReview),
                      child: const Text('其他登录方式'),
                    ),
                    if (_showReview)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                '应用商店审核账号',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                key: const Key('review-username'),
                                controller: _username,
                                autocorrect: false,
                                decoration: const InputDecoration(
                                  labelText: '审核账号',
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                key: const Key('review-password'),
                                controller: _password,
                                obscureText: true,
                                enableSuggestions: false,
                                autocorrect: false,
                                decoration: const InputDecoration(
                                  labelText: '审核密码',
                                ),
                              ),
                              const SizedBox(height: 12),
                              FilledButton.tonal(
                                key: const Key('review-login'),
                                onPressed: auth.isBusy
                                    ? null
                                    : () => ref
                                          .read(authControllerProvider.notifier)
                                          .loginForReview(
                                            _username.text.trim(),
                                            _password.text,
                                          ),
                                child: const Text('审核登录'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showPolicy(BuildContext context, String title, String url) =>
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: SelectableText(
            '正式文本地址：$url\n\n当前为待法律审核草案，上架前必须完成主体信息和联系方式。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('知道了'),
            ),
          ],
        ),
      );
}
