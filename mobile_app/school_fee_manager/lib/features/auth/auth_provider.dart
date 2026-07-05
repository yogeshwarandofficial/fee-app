import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';

// ── Auth status enum ──────────────────────────────────────────────────────────

enum AuthStatus {
  /// Initial state — checking secure storage for an existing token.
  checking,

  /// A valid, non-expired token exists in secure storage.
  authenticated,

  /// No token, or token was expired/invalid and has been cleared.
  unauthenticated,
}

// ── Auth state ────────────────────────────────────────────────────────────────

@immutable
class AuthState {
  const AuthState({
    this.status = AuthStatus.checking,
    this.isLoading = false,
    this.errorMessage,
  });

  final AuthStatus status;
  final bool isLoading;

  /// The error message to show (e.g., "Invalid Credentials" or connection error).
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ── Auth notifier ─────────────────────────────────────────────────────────────

/// Manages authentication state (Riverpod 3.x Notifier API).
///
/// Also mixes in [ChangeNotifier] so it can be passed to GoRouter as a
/// [refreshListenable] — GoRouter re-evaluates redirects whenever
/// [notifyListeners] is called (on login, logout, and init).
class AuthNotifier extends Notifier<AuthState> with ChangeNotifier {
  @override
  AuthState build() {
    // Kick off the async init; build() must return synchronously.
    Future.microtask(_init);
    return const AuthState();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// Checks secure storage on startup and sets initial auth status.
  Future<void> _init() async {
    final token = await _repository.getToken();
    bool authenticated = false;
    if (token != null) {
      authenticated = !_repository.isTokenExpired(token);
      if (!authenticated) await _repository.clearToken();
    }
    state = state.copyWith(
      status: authenticated
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated,
      clearError: true,
    );
    // Notify GoRouter to re-evaluate its redirect.
    notifyListeners();
  }

  /// Attempts login.
  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final token = await _repository.login(username, password);
      await _repository.saveToken(token);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        isLoading: false,
        clearError: true,
      );
      notifyListeners(); // triggers GoRouter redirect → /home
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Clears the stored JWT and resets all state to unauthenticated.
  Future<void> logout() async {
    await _repository.clearToken();
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      isLoading: false,
      clearError: true,
    );
    notifyListeners(); // triggers GoRouter redirect → /login
  }
}

// ── Riverpod provider ─────────────────────────────────────────────────────────

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
