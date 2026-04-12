import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/error_localizer.dart';
import 'email_verification_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nicknameController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final nickname = _nicknameController.text.trim();
    final password = _passwordController.text;
    final passwordConfirm = _passwordConfirmController.text;

    try {
      // 1. 이메일 인증코드 발송
      final authService = AuthService();
      await authService.sendVerificationCode(
        email: email,
        purpose: 'signup',
      );

      if (mounted) {
        // 2. 인증 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(
              email: email,
              purpose: 'signup',
              onVerified: () async {
                // 3. 인증 완료 후 실제 가입
                try {
                  await context.read<AuthProvider>().register(
                    email: email,
                    nickname: nickname,
                    password: password,
                    passwordConfirm: passwordConfirm,
                  );

                  if (context.mounted) {
                    // 가입 성공 → 루트까지 pop
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                } catch (e) {
                  if (context.mounted) {
                    final message = ErrorLocalizer.getMessage(context, e);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: context.mlColors.dangerColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        margin: const EdgeInsets.all(AppSpacing.xl),
                      ),
                    );
                  }
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
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
        title: Text(l10n.signupTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                // Logo or Title
                Icon(
                  Icons.trending_up,
                  size: 64,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'MarketLens ${l10n.signupTitle}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
                // Nickname field
                TextFormField(
                  controller: _nicknameController,
                  decoration: InputDecoration(
                    labelText: l10n.nickname,
                    hintText: l10n.nicknameHint,
                    prefixIcon: const Icon(Icons.person_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.nicknameRequired;
                    }
                    if (value.length < 2) {
                      return l10n.nicknameTooShort;
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
                      return l10n.passwordHint;
                    }
                    if (value.length < 8) {
                      return l10n.passwordTooShort;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                // Password confirm field
                TextFormField(
                  controller: _passwordConfirmController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.passwordConfirm,
                    hintText: l10n.passwordConfirmHint,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.passwordConfirmRequired;
                    }
                    if (value != _passwordController.text) {
                      return l10n.passwordMismatch;
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _handleSignup(),
                ),
                const SizedBox(height: AppSpacing.xxl),
                // Signup button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignup,
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
                          l10n.signup,
                          style: const TextStyle(fontSize: AppTypography.headlineMedium),
                        ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Login link
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: Text(
                    l10n.hasAccountLogin,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
