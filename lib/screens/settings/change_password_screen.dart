import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_stroke.dart';
import '../../theme/app_typography.dart';
import '../../utils/error_localizer.dart';
import '../../theme/app_colors.dart';

/// 비밀번호 변경 화면
///
/// 사용자가 기존 비밀번호를 입력하고 새 비밀번호로 변경할 수 있습니다.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// 비밀번호 변경 처리
  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
        newPasswordConfirm: _confirmPasswordController.text,
      );

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        // 변경 성공 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.passwordChanged),
            backgroundColor: context.mlColors.gainColor,
          ),
        );

        // 이전 화면으로 돌아가기
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.passwordChangeFailed(ErrorLocalizer.getMessage(context, e))),
            backgroundColor: context.mlColors.dangerColor,
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
        title: Text(l10n.changePassword),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            // 안내 카드
            Card(
              color: context.mlColors.infoBg,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: context.mlColors.accentBlue),
                        const SizedBox(width: AppSpacing.md),
                        Flexible(
                          child: Text(
                            l10n.changePasswordGuide,
                            style: AppTypography.bodyStrong.copyWith(
                              color: context.mlColors.accentBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      AppLocalizations.of(context).passwordChangeInstructions,
                      style: AppTypography.body.copyWith(
                        color: context.mlColors.accentBlue,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // 기존 비밀번호 입력
            TextFormField(
              controller: _oldPasswordController,
              obscureText: _obscureOldPassword,
              decoration: InputDecoration(
                labelText: l10n.oldPassword,
                hintText: l10n.oldPasswordHint,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _obscureOldPassword ? l10n.tooltipShowPassword : l10n.tooltipHidePassword,
                  icon: Icon(
                    _obscureOldPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _obscureOldPassword = !_obscureOldPassword);
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.oldPasswordRequired;
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // 새 비밀번호 입력
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              decoration: InputDecoration(
                labelText: l10n.newPassword,
                hintText: l10n.newPasswordHint,
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  tooltip: _obscureNewPassword ? l10n.tooltipShowPassword : l10n.tooltipHidePassword,
                  icon: Icon(
                    _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _obscureNewPassword = !_obscureNewPassword);
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.newPasswordRequired;
                }
                if (value.length < 8) {
                  return l10n.passwordTooShort;
                }
                if (value == _oldPasswordController.text) {
                  return l10n.newPasswordMustDiffer;
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // 새 비밀번호 확인
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: l10n.newPasswordConfirm,
                hintText: l10n.newPasswordConfirmHint,
                prefixIcon: const Icon(Icons.lock_clock),
                suffixIcon: IconButton(
                  tooltip: _obscureConfirmPassword ? l10n.tooltipShowPassword : l10n.tooltipHidePassword,
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.newPasswordConfirmRequired;
                }
                if (value != _newPasswordController.text) {
                  return l10n.passwordMismatch;
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // 변경 버튼
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: AppStroke.medium,
                          color: context.mlColors.onPrimary,
                        ),
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          l10n.changePassword,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: AppTypography.headlineMedium,
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
