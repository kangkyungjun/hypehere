import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_stroke.dart';
import '../../theme/app_typography.dart';
import '../../utils/app_page_route.dart';
import '../../utils/error_localizer.dart';
import '../../widgets/common/bento_card.dart';
import 'email_verification_screen.dart';
import 'login_screen.dart';

// Django CommonPasswordValidator top entries
const _commonPasswords = <String>{
  'password',
  'password1',
  'password123',
  '12345678',
  '123456789',
  '1234567890',
  'qwerty123',
  'qwertyuiop',
  'abcdefgh',
  'abcd1234',
  'abc12345',
  'iloveyou',
  'sunshine',
  'princess',
  'football',
  'charlie',
  'shadow',
  'michael',
  'qwerty',
  'baseball',
  'dragon',
  'master',
  'monkey',
  'letmein',
  'mustang',
  'access',
  'trustno1',
  'superman',
  'batman',
  'passw0rd',
};

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

  /// EULA(이용약관) 동의 여부 — Apple Guideline 1.2 (a): 가입 전 필수 동의
  bool _agreedToTerms = false;

  Future<void> _openUrl(String path) async {
    final lang = Localizations.localeOf(context).languageCode;
    final uri = Uri.parse('https://www.hypehere.net/marketlens/$path/?lang=$lang');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nicknameController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.passwordHint;
    }
    if (value.length < 8) {
      return l10n.passwordTooShort;
    }
    if (RegExp(r'^\d+$').hasMatch(value)) {
      return l10n.passwordAllNumeric;
    }
    if (_commonPasswords.contains(value.toLowerCase())) {
      return l10n.passwordTooCommon;
    }
    final emailLocal = _emailController.text
        .trim()
        .split('@')
        .first
        .toLowerCase();
    final nickname = _nicknameController.text.trim().toLowerCase();
    final lower = value.toLowerCase();
    if (emailLocal.length >= 3 && lower.contains(emailLocal)) {
      return l10n.passwordTooSimilar;
    }
    if (nickname.length >= 3 && lower.contains(nickname)) {
      return l10n.passwordTooSimilar;
    }
    return null;
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // EULA 미동의 시 가입 차단 (Apple Guideline 1.2 (a))
    if (!_agreedToTerms) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.termsAgreementRequired)),
      );
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
      await authService.sendVerificationCode(email: email, purpose: 'signup');

      if (mounted) {
        // 2. 인증 화면으로 이동 (통합 endpoint 사용)
        Navigator.push(
          context,
          appPageRoute(
            builder: (_) => EmailVerificationScreen(
              email: email,
              purpose: 'signup',
              onVerifiedWithCode: (code) async {
                final auth = context.read<AuthProvider>();
                final navigator = Navigator.of(context);
                // 3. 인증코드 + 가입을 한 번에 처리
                await auth.registerWithVerification(
                  email: email,
                  nickname: nickname,
                  password: password,
                  passwordConfirm: passwordConfirm,
                  code: code,
                );

                if (navigator.mounted) {
                  navigator.popUntil((route) => route.isFirst);
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
                Icon(
                  Icons.error_outline,
                  color: context.mlColors.onPrimary,
                  size: 20,
                ),
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

  /// EULA 동의 영역 — 무관용 정책 명시 + 약관/개인정보 링크 + 필수 체크박스
  Widget _buildTermsAgreement(AppLocalizations l10n) {
    final mlc = context.mlColors;
    final linkStyle = TextStyle(
      color: mlc.accentBlue,
      decoration: TextDecoration.underline,
      decorationColor: mlc.accentBlue,
      fontWeight: AppTypography.semiBold,
    );
    final baseStyle = TextStyle(
      color: mlc.textSecondary,
      fontSize: AppTypography.bodySmall,
      height: 1.45,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: mlc.cardBackground,
        border: Border.all(
          color: _agreedToTerms
              ? mlc.accentBlue.withValues(alpha: 0.5)
              : mlc.subtleBorder,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _agreedToTerms,
              onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
              child: Text.rich(
                TextSpan(
                  style: baseStyle,
                  children: [
                    TextSpan(text: '${l10n.eulaZeroTolerance}\n'),
                    TextSpan(text: l10n.eulaAgreePrefix),
                    TextSpan(
                      text: l10n.termsOfService,
                      style: linkStyle,
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _openUrl('terms'),
                    ),
                    TextSpan(text: l10n.eulaAgreeAnd),
                    TextSpan(
                      text: l10n.privacyPolicy,
                      style: linkStyle,
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _openUrl('privacy'),
                    ),
                    TextSpan(text: l10n.eulaAgreeSuffix),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.mlColors.sectionBackground,
      appBar: AppBar(title: Text(l10n.signupTitle)),
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
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: context.mlColors.infoBg,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 30,
                        color: context.mlColors.accentBlue,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.signupTitle,
                      style: AppTypography.screenTitle.copyWith(
                        color: context.mlColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.signupSubtitle,
                      style: AppTypography.body.copyWith(
                        color: context.mlColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    BentoCard(
                      child: Column(
                        children: [
                          TextFormField(
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
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          TextFormField(
                            controller: _nicknameController,
                            decoration: InputDecoration(
                              labelText: l10n.nickname,
                              hintText: l10n.nicknameHint,
                              prefixIcon: const Icon(Icons.person_outlined),
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
                          const SizedBox(height: AppSpacing.lg),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: l10n.password,
                              hintText: l10n.passwordHint,
                              prefixIcon: const Icon(Icons.lock_outlined),
                              helperText: l10n.passwordRequirements,
                              helperMaxLines: 2,
                            ),
                            validator: (value) =>
                                _validatePassword(value, l10n),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          TextFormField(
                            controller: _passwordConfirmController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: l10n.passwordConfirm,
                              hintText: l10n.passwordConfirmHint,
                              prefixIcon: const Icon(Icons.lock_outlined),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // EULA 동의 — Apple Guideline 1.2 (a): 무관용 정책 명시 + 필수 동의
                    _buildTermsAgreement(l10n),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: (_isLoading || !_agreedToTerms)
                          ? null
                          : _handleSignup,
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
                                  context.mlColors.onPrimary,
                                ),
                              ),
                            )
                          : Text(
                              l10n.signup,
                              style: const TextStyle(
                                fontSize: AppTypography.headlineMedium,
                                fontWeight: AppTypography.semiBold,
                              ),
                            ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          appPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: Text(l10n.hasAccountLogin),
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
