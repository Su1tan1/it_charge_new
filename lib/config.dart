class Config {
  // Значения будут подставляться через --dart-define при сборке/запуске.
  // Пример: flutter run --dart-define=BASE_URL=https://api.example.com --dart-define=API_KEY=abcd
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://176.88.248.139:8081',
  );
  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: '',
  );
  // Включить для тестирования: количество попыток retry
  static const int maxRetries = int.fromEnvironment(
    'MAX_RETRIES',
    defaultValue: 3,
  );
  static const int retryBaseDelayMs = int.fromEnvironment(
    'RETRY_BASE_DELAY_MS',
    defaultValue: 300,
  );
}
