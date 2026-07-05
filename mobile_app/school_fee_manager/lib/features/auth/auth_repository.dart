import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_fee_manager/core/api/dio_client.dart';
import 'package:school_fee_manager/core/constants/app_constants.dart';

import 'package:dio/dio.dart';

/// Repository that handles all authentication network and storage operations.
class AuthRepository {
  AuthRepository(this._dioClient, this._secureStorage);

  final DioClient _dioClient;
  final FlutterSecureStorage _secureStorage;

  // ── Network ───────────────────────────────────────────────────────────────

  /// Calls POST /auth/login and returns the JWT on success.
  ///
  /// Throws:
  ///   • 'Invalid Credentials'  — wrong username or password (401)
  ///   • 'Server Connection Failed: ...' — network/timeout/connection error
  Future<String> login(String username, String password) async {
    try {
      final response = await _dioClient.dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );

      final body = response.data as Map<String, dynamic>;

      if (body['success'] == true) {
        return body['data']['token'] as String;
      }

      // Server returned success:false with a non-401 status
      final serverMsg = body['error'] as String? ?? 'Login failed';
      throw _AuthException(serverMsg);

    } on _AuthException {
      rethrow;
    } on DioException catch (e) {
      throw _AuthException(_classifyDioError(e));
    } catch (e) {
      // Guard: never mask a real connection error as "Invalid Credentials"
      final msg = e.toString();
      if (msg.contains('Invalid Credentials') || msg.contains('SocketException') == false) {
        throw const _AuthException('Invalid Credentials');
      }
      throw const _AuthException('Server Connection Failed: Unexpected error. Please try again.');
    }
  }

  /// Classifies a Dio error into a user-facing message.
  String _classifyDioError(DioException e) {
    // 401 from server → credential problem
    if (e.response?.statusCode == 401) {
      return 'Invalid Credentials';
    }

    // Server returned an error body
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic> && data['error'] != null) {
        return data['error'] as String;
      }
      return 'Server error (${e.response!.statusCode}). Please try again.';
    }

    // Network / transport errors
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Server Connection Failed: Connection timed out. Check your Wi-Fi and server IP.';
      case DioExceptionType.sendTimeout:
        return 'Server Connection Failed: Request timed out. The server may be busy.';
      case DioExceptionType.receiveTimeout:
        return 'Server Connection Failed: Server took too long to respond. Try again.';
      case DioExceptionType.connectionError:
        final inner = e.error;
        if (inner is SocketException) {
          return 'Server Connection Failed: Cannot reach server at ${AppConstants.apiBaseUrl}. '
              'Ensure the server is running and your device is on the same Wi-Fi.';
        }
        return 'Server Connection Failed: Network error. Check your connection.';
      case DioExceptionType.unknown:
        final inner = e.error;
        if (inner is SocketException) {
          return 'Server Connection Failed: Cannot reach server. Check Wi-Fi and server IP.';
        }
        return 'Server Connection Failed: Unexpected network error.';
      default:
        return 'Server Connection Failed: ${e.message ?? "Unknown error"}';
    }
  }

  // ── Secure storage ────────────────────────────────────────────────────────

  Future<String?> getToken() =>
      _secureStorage.read(key: AppConstants.jwtTokenKey);

  Future<void> saveToken(String token) =>
      _secureStorage.write(key: AppConstants.jwtTokenKey, value: token);

  Future<void> clearToken() =>
      _secureStorage.delete(key: AppConstants.jwtTokenKey);

  // ── Token inspection (client-side only, no signature verify) ─────────────

  /// Returns true if the token is missing, malformed, or its exp has passed.
  bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      // Base64Url decode the payload section
      final padded = base64Url.normalize(parts[1]);
      final payload = json.decode(utf8.decode(base64Url.decode(padded)))
          as Map<String, dynamic>;
      final exp = payload['exp'] as int?;
      if (exp == null) return false; // no expiry claim → treat as valid
      return DateTime.now()
          .isAfter(DateTime.fromMillisecondsSinceEpoch(exp * 1000));
    } catch (_) {
      return true; // any parse error → treat as expired
    }
  }
}

// ── Internal exception used within this file only ─────────────────────────────

class _AuthException implements Exception {
  const _AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

// ── Riverpod providers ────────────────────────────────────────────────────────

final _secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    DioClient(),
    ref.watch(_secureStorageProvider),
  );
});
