/// Application-wide constants.
///
/// The API base URL is the single source-of-truth for all network requests.
/// Change it here to switch between environments (local dev, staging, production).
class AppConstants {
  AppConstants._(); // prevent instantiation

  /// Base URL for the backend REST API.
  /// In development, use your machine's local IP (not localhost) when running
  /// on a physical Android/iOS device. For emulators, 10.0.2.2 maps to host.
  static const String apiBaseUrl = 'https://fee-app-1js9.onrender.com/api';

  /// JWT token key used by flutter_secure_storage.
  static const String jwtTokenKey = 'jwt_token';

  /// App display name.
  static const String appName = 'MRT & ABR Matriculation School';

  /// Supported academic grades.
  static const List<String> grades = [
    'LKG',
    'UKG',
    'Grade 1',
    'Grade 2',
    'Grade 3',
    'Grade 4',
    'Grade 5',
    'Grade 6',
    'Grade 7',
    'Grade 8',
  ];
}
