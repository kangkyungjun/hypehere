import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../exceptions/api_error_codes.dart';
import '../../exceptions/api_exception.dart';
import '../../utils/error_localizer.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'email_verification_screen.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();

    try {
      await _authService.requestPasswordReset(email: email);

      if (mounted) {
        // 코드 입력 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(
              email: email,
              purpose: 'password_reset',
              onVerifiedWithCode: (code) {
                // 코드를 가지고 비밀번호 재설정 화면으로
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResetPasswordScreen(
                      email: email,
                      code: code,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        if (e is ApiException && e.code == ApiErrorCode.rateLimited) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ErrorLocalizer.getMessage(context, e)),
              backgroundColor: context.mlColors.warningColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              margin: const EdgeInsets.all(AppSpacing.xl),
            ),
          );
        } else {
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              margin: const EdgeInsets.all(AppSpacing.xl),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.forgotPassword),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxxl),
                Icon(
                  Icons.lock_reset_outlined,
                  size: 64,
                  color: theme.primaryColor,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.forgotPassword,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: AppTypography.displayLarge, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.forgotPasswordSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: AppTypography.bodyLarge, color: context.mlColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xxxl),
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
                  onFieldSubmitted: (_) => _handleSubmit(),
                ),
                const SizedBox(height: AppSpacing.xxl),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    backgroundColor: theme.primaryColor,
                    foregroundColor: context.mlColors.onPrimary,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(context.mlColors.onPrimary),
                          ),
                        )
                      : Text(l10n.sendVerificationCode, style: const TextStyle(fontSize: AppTypography.headlineMedium)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
