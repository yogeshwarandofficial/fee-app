import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:school_fee_manager/core/constants/app_constants.dart';

/// Production-ready singleton Dio HTTP client.
///
/// Features:
///   • Correct base URL from [AppConstants.apiBaseUrl]
///   • JWT Bearer token injected on every request
///   • Auto-retry with exponential back-off (up to [_maxRetries] attempts)
///     for transient network failures (connection refused, timeout, socket errors)
///   • Tight timeout values: connect 10 s, send 10 s, receive 30 s
///   • HTTP keep-alive enabled for connection reuse
///   • Errors are passed through to the feature layer for domain-specific handling
class DioClient {
  DioClient._internal();

  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  static const _secureStorage = FlutterSecureStorage();
  static const int _maxRetries = 3;

  late final Dio _dio = _buildDio();

  /// The underlying Dio instance. Use this for all API calls.
  Dio get dio => _dio;

  Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Enable HTTP keep-alive to reuse TCP connections
          'Connection': 'keep-alive',
        },
        // Follow redirects automatically
        followRedirects: true,
        maxRedirects: 3,
      ),
    );

    // ── Enable HTTP keep-alive at the adapter level ────────────────────────
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.idleTimeout = const Duration(seconds: 90);
      client.connectionTimeout = const Duration(seconds: 10);
      return client;
    };

    // ── Interceptor 1: JWT Bearer token ───────────────────────────────────
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.read(
            key: AppConstants.jwtTokenKey,
          );
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    // ── Interceptor 2: Retry with exponential back-off ────────────────────
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          // Only retry on transient network-level errors, never on auth/logic errors
          if (!_isRetryable(error)) {
            return handler.next(error);
          }

          final attempt = (error.requestOptions.extra['_retryCount'] as int?) ?? 0;
          if (attempt >= _maxRetries) {
            return handler.next(error);
          }

          // Exponential back-off: 1 s, 2 s, 4 s
          final delay = Duration(milliseconds: 1000 * (1 << attempt));
          await Future.delayed(delay);

          // Clone the request with incremented retry count
          final options = error.requestOptions;
          options.extra['_retryCount'] = attempt + 1;

          try {
            final response = await dio.fetch(options);
            return handler.resolve(response);
          } on DioException catch (e) {
            return handler.next(e);
          }
        },
      ),
    );

    return dio;
  }

  /// Returns true for transient network failures that are safe to retry.
  /// Never retries 4xx (client errors) or 5xx (already-handled server errors).
  bool _isRetryable(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.unknown:
        // Retry on socket-level errors (ENETUNREACH, ECONNREFUSED, etc.)
        final inner = error.error;
        return inner is SocketException || inner is IOException;
      default:
        return false;
    }
  }
}
