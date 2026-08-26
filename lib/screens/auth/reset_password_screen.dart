import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_stroke.dart';
import '../../theme/app_typography.dart';
import '../../utils/error_localizer.dart';
import '../../widgets/common/bento_card.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String code;

  const ResetPasswordScreen({super.key, required this.email, required this.code});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.confirmPasswordReset(
        email: widget.email,
        code: widget.code,
        newPassword: _passwordController.text,
        newPasswordConfirm: _passwordConfirmController.text,
      );

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.resetPasswordSuccess),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            margin: const EdgeInsets.all(AppSpacing.xl),
          ),
        );
        // 로그인 화면까지 pop
        Navigator.of(context).popUntil((route) => route.isFirst);
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            margin: const EdgeInsets.all(AppSpacing.xl),
          ),
        );
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
        title: Text(l10n.resetPassword),
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
                          Icons.lock_open_outlined,
                          size: 30,
                          color: mlc.accentBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.resetPassword,
                      textAlign: TextAlign.center,
                      style: AppTypography.screenTitle.copyWith(
                        color: mlc.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.resetPasswordSubtitle,
                      textAlign: TextAlign.center,
                      style:
                          AppTypography.body.copyWith(color: mlc.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    BentoCard(
                      child: Column(
                        children: [
                          // 새 비밀번호
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: l10n.newPassword,
                              hintText: l10n.newPasswordHint,
                              prefixIcon: const Icon(Icons.lock_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.newPasswordRequired;
                              }
                              if (value.length < 8) {
                                return l10n.passwordTooShort;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // 새 비밀번호 확인
                          TextFormField(
                            controller: _passwordConfirmController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: l10n.newPasswordConfirm,
                              hintText: l10n.newPasswordConfirmHint,
                              prefixIcon: const Icon(Icons.lock_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.newPasswordConfirmRequired;
                              }
                              if (value != _passwordController.text) {
                                return l10n.passwordMismatch;
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _handleReset(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: _isLoading ? null : _handleReset,
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
                              l10n.resetPassword,
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
