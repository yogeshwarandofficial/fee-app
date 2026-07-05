import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_fee_manager/core/theme/app_theme.dart';
import 'auth_provider.dart';

/// Login screen — the sole entry point to the application.
///
/// Security requirements:
/// - Password field is ALWAYS obscured (obscureText: true, no show/hide toggle).
/// - No "Forgot Password", "Sign Up", or any other link exists on this screen.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(authProvider.notifier).login(
          _usernameController.text.trim(),
          _passwordController.text,
        );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // React to failed attempts: clear password field and trigger shake.
    ref.listen<AuthState>(authProvider, (previous, next) {
      final hadError = previous?.errorMessage;
      final hasNewError = next.errorMessage;
      if (hadError != hasNewError && hasNewError != null) {
        _passwordController.clear();
        _shakeController.forward(from: 0);
      }
    });

    final isLoading = authState.isLoading;
    final isInteractive = !isLoading;

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48),
                      _buildHeader(),
                      const SizedBox(height: 40),
                      _buildCard(
                        authState: authState,
                        isLoading: isLoading,
                        isInteractive: isInteractive,
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(30),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(60), width: 1.5),
          ),
          child: const Icon(
            Icons.account_balance_rounded,
            size: 44,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'MJR School',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Fee Management System',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.white.withAlpha(180),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required AuthState authState,
    required bool isLoading,
    required bool isInteractive,
  }) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final offset = (12 * (_shakeAnimation.value * 2 - 1).abs() *
            (1 - _shakeAnimation.value));
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Card heading ──────────────────────────────────────────────
              const Text(
                'Administrator Login',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sign in to manage school fees',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 28),

              // ── Username ──────────────────────────────────────────────────
              _buildLabel('Username'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _usernameController,
                enabled: isInteractive,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textPrimary,
                ),
                decoration: _fieldDecoration(
                  hint: 'Enter your username',
                  icon: Icons.person_outline_rounded,
                  enabled: isInteractive,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Username is required' : null,
              ),
              const SizedBox(height: 18),

              // ── Password — ALWAYS obscured, no show/hide toggle ───────────
              _buildLabel('Password'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passwordController,
                enabled: isInteractive,
                obscureText: true, // ALWAYS true — no eye icon, by design
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => isInteractive ? _submit() : null,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textPrimary,
                ),
                decoration: _fieldDecoration(
                  hint: 'Enter your password',
                  icon: Icons.lock_outline_rounded,
                  enabled: isInteractive,
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Password is required' : null,
              ),
              const SizedBox(height: 24),

              // ── Error banner ────────────────────────────────────
              if (authState.errorMessage != null)
                _buildStatusBanner(authState.errorMessage!),

              if (authState.errorMessage != null)
                const SizedBox(height: 20),

              // ── Login button ──────────────────────────────────────────────
              _buildLoginButton(
                isLoading: isLoading,
                isInteractive: isInteractive,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
        letterSpacing: 0.2,
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    required bool enabled,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        icon,
        size: 20,
        color: enabled ? AppTheme.textSecondary : AppTheme.dividerColor,
      ),
      filled: true,
      fillColor: enabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.dividerColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: AppTheme.accentColor, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: AppTheme.dividerColor, width: 0.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: AppTheme.errorColor, width: 1.5),
      ),
    );
  }

  Widget _buildStatusBanner(String error) {
    final isConnectionError = error.contains('Connection');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.errorColor.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(
            isConnectionError ? Icons.cloud_off_rounded : Icons.warning_amber_rounded,
            size: 18,
            color: isConnectionError ? AppTheme.warningColor : AppTheme.errorColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton({
    required bool isLoading,
    required bool isInteractive,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isInteractive ? _submit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.dividerColor,
          disabledForegroundColor: AppTheme.textSecondary,
          elevation: isInteractive ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Login',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}
