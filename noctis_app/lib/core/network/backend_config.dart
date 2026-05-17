// Конфигурация подключения к бэкенду NOCTIS.
//
// Значение задаётся при сборке: `--dart-define=BACKEND_URL=https://your.host`.
// Пустая строка — режим offline-демо (мок-OTP "000000").
class BackendConfig {
  const BackendConfig._();

  static const String baseUrl =
      String.fromEnvironment('BACKEND_URL', defaultValue: '');

  static bool get isConfigured => baseUrl.isNotEmpty;

  static String httpUrl(String path) => '$baseUrl$path';

  static String wsUrl(String path) {
    if (baseUrl.startsWith('https://')) {
      return 'wss://${baseUrl.substring(8)}$path';
    }
    if (baseUrl.startsWith('http://')) {
      return 'ws://${baseUrl.substring(7)}$path';
    }
    return '$baseUrl$path';
  }
}
