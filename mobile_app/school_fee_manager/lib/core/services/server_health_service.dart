import 'package:dio/dio.dart';
import 'package:school_fee_manager/core/constants/app_constants.dart';

/// Lightweight service to check if the backend server is reachable.
///
/// Used on login screen load to give early feedback about connectivity,
/// separate from the auth flow.
class ServerHealthService {
  static final _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {'Accept': 'application/json'},
    ),
  );

  /// Returns true if the /health endpoint responds successfully.
  /// Never throws — always returns a boolean.
  static Future<bool> isReachable() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200 &&
          response.data is Map &&
          response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
