import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Configuration for MindPay ML Backend API connectivity.
class ApiConfig {
  /// Base port where the FastAPI backend runs.
  static const int port = 8000;

  /// Override URL for custom deployments or physical device testing over LAN.
  /// Set this to non-null (e.g., 'http://192.168.1.50:8000') if testing on a real device.
  static String? customBaseUrl;

  /// Returns the appropriate base URL depending on the runtime platform.
  /// - Android emulator uses `10.0.2.2` to access host machine localhost.
  /// - iOS simulator, desktop, or web uses `127.0.0.1`.
  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      return customBaseUrl!;
    }

    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:$port';
    }

    return 'http://127.0.0.1:$port';
  }

  /// ML prediction endpoint URL.
  static String get predictUrl => '$baseUrl/predict';

  /// Health check endpoint URL.
  static String get healthUrl => '$baseUrl/health';

  /// Request timeout duration before falling back to local rule-based scoring.
  static const Duration requestTimeout = Duration(milliseconds: 3500);
}

