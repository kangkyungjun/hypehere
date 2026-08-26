import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String purpose; // 'signup' or 'password_reset'
  final Future<void> Function()? onVerified;
  final Future<void> Function(String code)? onVerifiedWithCode;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.purpose,
    this.onVerified,
    this.onVerifiedWithCode,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _codeController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isVerified = false;
  bool _isResending = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  Timer? _expiryTimer;
  int _expirySeconds = 600; // 10 minutes

  @override
  void initState() {
    super.initState();
    _startExpiryTimer();
    _startCooldown(60); // 처음 발송 직후이므로 60초 쿨다운
  }

  @override
  void dispose() {
    _codeController.dispose();
    _cooldownTimer?.cancel();
    _expiryTimer?.cancel();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    setState(() => _cooldownSeconds = seconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => _cooldownSeconds = 0);
      } else {
        if (mounted) setState(() => _cooldownSeconds--);
      }
    });
  }

  void _startExpiryTimer() {
    _expirySeconds = 600;
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_expirySeconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => _expirySeconds = 0);
      } else {
        if (mounted) setState(() => _expirySeconds--);
      }
    });
  }

  String get _expiryText {
    final min = _expirySeconds ~/ 60;
    final sec = _expirySeconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  Future<void> _handleVerify() async {
    if (_isVerified) return;
    final code = _codeController.text.trim();
    if (code.length != 6) return;

    setState(() => _isLoading = true);

    try {
      if (widget.onVerifiedWithCode != null) {
        // 코드를 콜백에 전달 (signup: 통합 endpoint / password_reset: confirm에서 처리)
        await widget.onVerifiedWithCode!(code);
        _isVerified = true;
        return;
      }

      await _authService.verifyCode(
        email: widget.email,
        code: code,
        purpose: widget.purpose,
      );

      _isVerified = true;

      if (mounted) {
        await widget.onVerified?.call();
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

  Future<void> _handleResend() async {
    if (_cooldownSeconds > 0 || _isResending) return;

    setState(() => _isResending = true);

    try {
      await _authService.sendVerificationCode(
        email: widget.email,
        purpose: widget.purpose,
      );

      if (mounted) {
        _startCooldown(60);
        _startExpiryTimer();
        _codeController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).verificationCodeResent),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            margin: const EdgeInsets.all(AppSpacing.xl),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        if (e is ApiException && e.code == ApiErrorCode.rateLimited) {
          final cooldown = int.tryParse(e.debugMessage ?? '60') ?? 60;
          _startCooldown(cooldown);
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            margin: const EdgeInsets.all(AppSpacing.xl),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mlc = context.mlColors;

    return Scaffold(
      backgroundColor: mlc.sectionBackground,
      appBar: AppBar(
        title: Text(l10n.verificationTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
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
                        Icons.mark_email_read_outlined,
                        size: 30,
                        color: mlc.accentBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.verificationTitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.screenTitle.copyWith(
                      color: mlc.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.verificationSubtitle(widget.email),
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(color: mlc.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // 만료 타이머 — 방향성 없는 상태값이므로 라벨은 secondary, 임박 시 danger
                  Text(
                    l10n.verificationExpiry(_expiryText),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTypography.bodyMedium,
                      fontWeight: AppTypography.medium,
                      color: _expirySeconds < 120
                          ? mlc.dangerColor
                          : mlc.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  // 6자리 코드 입력
                  BentoCard(
                    child: TextFormField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: TextStyle(
                        fontSize: AppTypography.heroSmall,
                        fontWeight: AppTypography.bold,
                        letterSpacing: 12,
                        color: mlc.textPrimary,
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: '000000',
                        hintStyle: TextStyle(
                          color: mlc.textTertiary,
                          fontSize: AppTypography.heroSmall,
                          letterSpacing: 12,
                        ),
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xl,
                        ),
                      ),
                      onChanged: (value) {
                        if (value.length == 6) _handleVerify();
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // 인증 버튼
                  FilledButton(
                    onPressed: _isLoading ? null : _handleVerify,
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
                            l10n.verifyButton,
                            style: const TextStyle(
                              fontSize: AppTypography.headlineMedium,
                              fontWeight: AppTypography.semiBold,
                            ),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // 재발송 버튼 — 링크성 액션이므로 accentBlue
                  TextButton(
                    onPressed: (_cooldownSeconds > 0 || _isResending)
                        ? null
                        : _handleResend,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _cooldownSeconds > 0
                            ? l10n.resendCodeCooldown(_cooldownSeconds)
                            : l10n.resendCode,
                        style: TextStyle(
                          color: _cooldownSeconds > 0
                              ? mlc.textTertiary
                              : mlc.accentBlue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
