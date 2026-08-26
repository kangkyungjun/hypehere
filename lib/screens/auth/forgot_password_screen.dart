import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../exceptions/api_error_codes.dart';
import '../../exceptions/api_exception.dart';
import '../../utils/error_localizer.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_stroke.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/bento_card.dart';
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
              onVerifiedWithCode: (code) async {
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
    final mlc = context.mlColors;

    return Scaffold(
      backgroundColor: mlc.sectionBackground,
      appBar: AppBar(
        title: Text(l10n.forgotPassword),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xxl),
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: mlc.infoBg,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Icon(
                          Icons.lock_reset_outlined,
                          size: 30,
                          color: mlc.accentBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.forgotPassword,
                      textAlign: TextAlign.center,
                      style: AppTypography.screenTitle.copyWith(
                        color: mlc.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.forgotPasswordSubtitle,
                      textAlign: TextAlign.center,
                      style:
                          AppTypography.body.copyWith(color: mlc.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    BentoCard(
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: l10n.email,
                          hintText: l10n.emailHint,
                          prefixIcon: const Icon(Icons.email_outlined),
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
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: AppStroke.medium,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  mlc.onPrimary,
                                ),
                              ),
                            )
                          : Text(
                              l10n.sendVerificationCode,
                              style: const TextStyle(
                                fontSize: AppTypography.headlineMedium,
                                fontWeight: AppTypography.semiBold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
