/// HypeHere Flutter WebView Configuration
/// Contains all configuration constants for the application

class AppConfig {
  // Base URL Configuration
  static const String baseUrl = 'https://hypehere.net';

  // WebSocket URL (for Django Channels support)
  static const String wsBaseUrl = 'wss://hypehere.net';

  // App Information
  static const String appName = 'HypeHere';
  static const String appVersion = '1.0.0';

  // WebView Settings
  static const bool enableJavaScript = true;
  static const bool enableDomStorage = true;
  static const bool enableLocationServices = false;
  static const bool enableMediaPlayback = true;

  // Network Settings
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration networkCheckInterval = Duration(seconds: 5);

  // Error Messages
  static const String networkErrorMessage =
      'No internet connection. Please check your network settings.';
  static const String serverErrorMessage =
      'Unable to connect to server. Please try again later.';
  static const String genericErrorMessage =
      'An error occurred. Please try again.';

  // User Agent
  static const String userAgent =
      'HypeHere/1.0.0 (Flutter WebView; Android/iOS)';
}
