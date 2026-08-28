import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../exceptions/api_exception.dart';
import '../../exceptions/api_error_codes.dart';
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
  // 서버가 비밀번호를 거부했을 때 폼으로 돌아와 이 필드에 포커스를 준다.
  final _passwordFocusNode = FocusNode();
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
    _passwordFocusNode.dispose();
    super.dispose();
  }

  /// 빨간 플로팅 에러 SnackBar (가입 화면 공용).
  void _showErrorSnack(String message) {
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

  /// 실시간 비밀번호 규칙 상태 — 입력 즉시 각 항목 충족 여부를 보여준다.
  /// _validatePassword와 동일 기준/상수를 공유해 안내와 실제 검증이 어긋나지 않게 한다.
  List<({String label, bool ok})> _passwordRules(AppLocalizations l10n) {
    final v = _passwordController.text;
    final lower = v.toLowerCase();
    final emailLocal =
        _emailController.text.trim().split('@').first.toLowerCase();
    final nickname = _nicknameController.text.trim().toLowerCase();
    final notSimilar = v.isNotEmpty &&
        !(emailLocal.length >= 3 && lower.contains(emailLocal)) &&
        !(nickname.length >= 3 && lower.contains(nickname));
    return [
      (label: l10n.passwordRuleLength, ok: v.length >= 8),
      (
        label: l10n.passwordRuleNotNumeric,
        ok: v.isNotEmpty && !RegExp(r'^\d+$').hasMatch(v),
      ),
      (
        label: l10n.passwordRuleNotCommon,
        ok: v.isNotEmpty && !_commonPasswords.contains(lower),
      ),
      (label: l10n.passwordRuleNotSimilar, ok: notSimilar),
    ];
  }

  /// 비밀번호 필드 아래 실시간 규칙 체크리스트(✓ 녹색 / ○ 회색).
  Widget _buildPasswordChecklist(AppLocalizations l10n, MarketLensColors mlc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _passwordRules(l10n).map((r) {
        final color = r.ok ? mlc.gainColor : mlc.textSecondary;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                r.ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                size: 15,
                color: color,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(r.label,
                    style: AppTypography.label
                        .copyWith(fontSize: AppTypography.bodyMedium, color: color)),
              ),
            ],
          ),
        );
      }).toList(),
    );
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
                try {
                  await auth.registerWithVerification(
                    email: email,
                    nickname: nickname,
                    password: password,
                    passwordConfirm: passwordConfirm,
                    code: code,
                  );
                } on ApiException catch (e) {
                  // 서버가 비밀번호 정책으로 거부 → 인증 화면을 닫고 가입 폼으로 돌아가
                  // 비밀번호를 고치게 한다(인증 화면에 갇혀 못 고치는 상황 방지).
                  if (e.code == ApiErrorCode.weakPassword) {
                    navigator.pop();
                    if (mounted) {
                      _showErrorSnack(
                          AppLocalizations.of(context).passwordPolicyFailed);
                      _passwordFocusNode.requestFocus();
                    }
                    return;
                  }
                  rethrow; // 그 외(인증코드 오류 등)는 인증 화면이 안내
                }

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
        _showErrorSnack(ErrorLocalizer.getMessage(context, e));
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
                            focusNode: _passwordFocusNode,
                            obscureText: true,
                            // 입력 즉시 규칙 체크리스트를 갱신 + 닉네임/이메일 유사도 반영
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: l10n.password,
                              hintText: l10n.passwordHint,
                              prefixIcon: const Icon(Icons.lock_outlined),
                            ),
                            validator: (value) =>
                                _validatePassword(value, l10n),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          // 규칙을 항상 보이게 + 타이핑 중 충족 여부 실시간 안내
                          _buildPasswordChecklist(l10n, context.mlColors),
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
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                l10n.signup,
                                maxLines: 1,
                                softWrap: false,
                                style: const TextStyle(
                                  fontSize: AppTypography.headlineMedium,
                                  fontWeight: AppTypography.bold,
                                ),
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
