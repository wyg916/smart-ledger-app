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

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://www.znjz.site',
);
const appVersion = '1.0.0';
const applicationId = 'com.wyg916.smartledger';
const releaseChannel = String.fromEnvironment(
  'RELEASE_CHANNEL',
  defaultValue: 'direct',
);

void validateAppConfiguration() {
  final environment = AppEnvironment.fromName(_configuredEnvironment);
  final uri = Uri.tryParse(apiBaseUrl);
  if (environment == AppEnvironment.production &&
      (uri == null || uri.scheme != 'https' || uri.host.isEmpty)) {
    throw StateError('Production API_BASE_URL must be HTTPS');
  }
}
