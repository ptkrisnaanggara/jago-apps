/// App-wide configuration. Compile-time overridable via --dart-define.
class AppConfig {
  AppConfig._();

  /// When true (default), the app uses in-memory mock repositories. Set
  /// `--dart-define=USE_MOCK_DATA=false` to talk to the real backend.
  static const bool useMockData =
      bool.fromEnvironment('USE_MOCK_DATA', defaultValue: true);

  /// Base URL of the backend API. Defaults to the Android emulator's host
  /// loopback (`10.0.2.2`) so a locally-run backend is reachable from an
  /// emulator; override per environment with `--dart-define=API_BASE_URL=...`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api/v1',
  );
}
