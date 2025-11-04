class Config {
  // Все запросы теперь идут через Nginx на порту 80
  // Base URL для всех HTTP запросов
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://176.88.248.139',
  );

  // WebSocket для мобильного приложения (через Nginx)
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'ws://176.88.248.139/mobile',
  );

  // Auth service endpoints (через Nginx /auth)
  static const String authUrl = String.fromEnvironment(
    'AUTH_URL',
    defaultValue: 'http://176.88.248.139/auth',
  );

  // Stations service endpoints (через Nginx /stations)
  static const String stationsUrl = String.fromEnvironment(
    'STATIONS_URL',
    defaultValue: 'http://176.88.248.139/stations',
  );

  // Transactions service endpoints (через Nginx /transactions)
  static const String transactionsUrl = String.fromEnvironment(
    'TRANSACTIONS_URL',
    defaultValue: 'http://176.88.248.139/transactions',
  );

  // Notifications service endpoints (через Nginx /notifications)
  static const String notificationsUrl = String.fromEnvironment(
    'NOTIFICATIONS_URL',
    defaultValue: 'http://176.88.248.139/notifications',
  );

  // API Key for authentication
  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: 'mobile-app-key-2025',
  );

  // Retry configuration
  static const int maxRetries = int.fromEnvironment(
    'MAX_RETRIES',
    defaultValue: 3,
  );
  static const int retryBaseDelayMs = int.fromEnvironment(
    'RETRY_BASE_DELAY_MS',
    defaultValue: 300,
  );
}
