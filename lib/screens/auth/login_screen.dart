import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../exceptions/api_error_codes.dart';
import '../../exceptions/api_exception.dart';
import '../../services/auth_service.dart';
import '../../utils/error_localizer.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'email_verification_screen.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        // Return true to indicate successful login
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        // 이메일 미인증 → 인증 화면으로 리다이렉트
        if (e is ApiException && e.code == ApiErrorCode.emailNotVerified) {
          final email = _emailController.text.trim();
          try {
            await AuthService().sendVerificationCode(email: email, purpose: 'signup');
          } catch (e) {
            debugPrint('sendVerificationCode error: $e');
          }
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmailVerificationScreen(
                  email: email,
                  purpose: 'signup',
                  onVerified: () {
                    if (context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                ),
              ),
            );
          }
          return;
        }

        final message = ErrorLocalizer.getMessage(context, e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: context.mlColors.onPrimary, size: 20),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: context.mlColors.dangerColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            margin: const EdgeInsets.all(AppSpacing.xl),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.login),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxxl),
                // Logo or Title
                Icon(
                  Icons.trending_up,
                  size: 64,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: AppSpacing.xl),
                const Text(
                  'MarketLens',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppTypography.displayLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 48),
                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    hintText: l10n.emailHint,
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.emailRequired;
                    }
                    if (!value.contains('@')) {
                      return l10n.emailInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    hintText: l10n.passwordHint,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.passwordRequired;
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _handleLogin(),
                ),
                const SizedBox(height: AppSpacing.xxl),
                // Login button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: context.mlColors.onPrimary,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(context.mlColors.onPrimary),
                          ),
                        )
                      : Text(
                          l10n.login,
                          style: const TextStyle(fontSize: AppTypography.headlineMedium),
                        ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Sign up & Forgot password row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupScreen(),
                          ),
                        );
                      },
                      child: Text(
                        l10n.signup,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    Text(
                      '|',
                      style: TextStyle(color: context.mlColors.textTertiary),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: Text(
                        l10n.forgotPassword,
                        style: TextStyle(
                          color: context.mlColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
