import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppEnvironment {
  development,
  test,
  production;

  static AppEnvironment fromName(String value) {
    return AppEnvironment.values.firstWhere(
      (environment) => environment.name == value,
      orElse: () => AppEnvironment.development,
    );
  }
}

const _configuredEnvironment = String.fromEnvironment(
  'APP_ENV',
  defaultValue: 'development',
);

final appEnvironmentProvider = Provider<AppEnvironment>(
  (ref) => AppEnvironment.fromName(_configuredEnvironment),
);

const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
