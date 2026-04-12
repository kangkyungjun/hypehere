import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/error_localizer.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.resetPassword),
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
                Icon(
                  Icons.lock_open_outlined,
                  size: 64,
                  color: theme.primaryColor,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.resetPassword,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: AppTypography.displayLarge, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.resetPasswordSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: AppTypography.bodyLarge, color: context.mlColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                // 새 비밀번호
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.newPassword,
                    hintText: l10n.newPasswordHint,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    border: const OutlineInputBorder(),
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
                const SizedBox(height: AppSpacing.xl),
                // 새 비밀번호 확인
                TextFormField(
                  controller: _passwordConfirmController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.newPasswordConfirm,
                    hintText: l10n.newPasswordConfirmHint,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    border: const OutlineInputBorder(),
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
                const SizedBox(height: AppSpacing.xxl),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleReset,
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
                      : Text(l10n.resetPassword, style: const TextStyle(fontSize: AppTypography.headlineMedium)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
