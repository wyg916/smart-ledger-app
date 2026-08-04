import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ledger/app/app.dart';
import 'package:smart_ledger/core/config/app_environment.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  validateAppConfiguration();
  runApp(const ProviderScope(child: SmartLedgerApp()));
}
