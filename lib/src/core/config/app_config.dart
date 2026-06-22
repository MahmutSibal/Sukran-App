class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'APPSUKRAN_API_BASE_URL',
    defaultValue: 'https://starr-haustorial-robin.ngrok-free.dev',
  );

  static const bool useMockFallback = bool.fromEnvironment(
    'APPSUKRAN_USE_MOCK_FALLBACK',
    defaultValue: true,
  );

  static const String defaultRestaurantId = String.fromEnvironment(
    'APPSUKRAN_DEMO_RESTAURANT_ID',
    defaultValue: 'restaurant-demo-001',
  );

  static const String defaultTableSessionId = String.fromEnvironment(
    'APPSUKRAN_DEMO_TABLE_SESSION_ID',
    defaultValue: 'table-session-demo-001',
  );
}