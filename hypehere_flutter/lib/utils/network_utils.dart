import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../config/app_config.dart';

/// Network Utility Functions
/// Handles network connectivity checks and HTTP requests

class NetworkUtils {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.connectionTimeout,
      receiveTimeout: AppConfig.connectionTimeout,
      headers: {
        'User-Agent': AppConfig.userAgent,
      },
    ),
  );

  /// Check if device has network connectivity
  static Future<bool> hasNetworkConnection() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();

      // Check if connected to WiFi or Mobile data
      return connectivity.contains(ConnectivityResult.wifi) ||
             connectivity.contains(ConnectivityResult.mobile);
    } catch (e) {
      print('Error checking network connectivity: $e');
      return false;
    }
  }

  /// Test server reachability
  static Future<bool> canReachServer() async {
    try {
      final response = await _dio.get(
        '/',
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      return response.statusCode != null && response.statusCode! < 500;
    } catch (e) {
      print('Error reaching server: $e');
      return false;
    }
  }

  /// Get connectivity status stream
  static Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return Connectivity().onConnectivityChanged;
  }

  /// Get current connectivity status
  static Future<List<ConnectivityResult>> getCurrentConnectivity() async {
    return await Connectivity().checkConnectivity();
  }
}
