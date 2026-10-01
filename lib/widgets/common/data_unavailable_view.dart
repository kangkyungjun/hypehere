import 'package:flutter/material.dart';

import '../../exceptions/api_error_codes.dart';
import '../../exceptions/api_exception.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// 데이터를 못 보여주는 **이유**. 상황마다 사용자가 할 수 있는 일이 다르다.
enum UnavailableKind {
  /// 기기가 서버에 못 닿는다. 사용자가 고칠 수 있다 → 다시 시도.
  offline,

  /// 서버가 깨졌다. 사용자가 할 수 있는 게 없다 → 다시 시도 + 알리기.
  serverError,

  /// **앱은 정상인데 이 항목만 데이터가 없다.** 종목이 커버리지 밖이거나
  /// 수집이 아직 안 됐다 → 알리기 + 돌아가기.
  ///
  /// ⚠️ 이 경우를 "오류"라고 쓰면 안 된다. 멀쩡한 앱을 고장난 것으로
  /// 오해시키는 손해가, 솔직하게 "준비 중"이라 쓰는 것보다 크다.
  notReady,
}

/// 실패 상태 단일 컴포넌트.
///
/// 개편 전에는 같은 화면 안에서도 경로마다 생김새가 달랐다 — 에러는
/// `ErrorStateView`(빨간 느낌표 + 재시도), 빈 상태는 손으로 만든 회색 아이콘
/// 컬럼. 게다가 빈 상태 문구가 `다른 티커를 검색해보세요`라서, **추천 카드를
/// 탭해 들어온 사용자**에게 검색 맥락의 안내가 떴다.
///
/// 여기서 세 상황을 구분하고 생김새를 하나로 묶는다.
class DataUnavailableView extends StatelessWidget {
  const DataUnavailableView({
    super.key,
    required this.kind,
    this.subject,
    this.detail,
    this.onRetry,
    this.onReport,
    this.onBack,
  });

  /// 예외로부터 상황을 판정한다. 분기 로직을 호출부마다 복사하지 않기 위함.
  factory DataUnavailableView.fromError(
    Object error, {
    String? subject,
    String? detail,
    VoidCallback? onRetry,
    VoidCallback? onReport,
    VoidCallback? onBack,
  }) {
    final kind = kindOf(error);
    return DataUnavailableView(
      kind: kind,
      subject: subject,
      detail: detail,
      // 데이터 부재는 다시 눌러도 결과가 같다 — 재시도를 주면 사용자가
      // 헛되이 반복한다.
      onRetry: kind == UnavailableKind.notReady ? null : onRetry,
      onReport: onReport,
      onBack: onBack,
    );
  }

  static UnavailableKind kindOf(Object error) {
    if (error is TickerNotFoundException) return UnavailableKind.notReady;
    if (error is ApiException) {
      switch (error.code) {
        // 기기가 서버에 못 닿는 경우 — 사용자가 고칠 수 있다.
        case ApiErrorCode.timeout10s:
        case ApiErrorCode.timeout15s:
        case ApiErrorCode.networkFailed:
        case ApiErrorCode.serverConnection:
        case ApiErrorCode.serverConnectionShort:
          return UnavailableKind.offline;
        // 404는 "그 항목이 없다"는 뜻이지 고장이 아니다.
        case ApiErrorCode.notFound:
        case ApiErrorCode.tickerNotFound:
          return UnavailableKind.notReady;
        default:
          return UnavailableKind.serverError;
      }
    }
    return UnavailableKind.serverError;
  }

  final UnavailableKind kind;

  /// 무엇이 없는지 (예: 티커). 문구에 끼워 넣는다.
  final String? subject;

  /// 개발자용 상세. 기본은 숨기고 길게 누르면 보인다.
  final String? detail;

  final VoidCallback? onRetry;
  final VoidCallback? onReport;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mlc = context.mlColors;

    final (icon, iconColor, title, body) = switch (kind) {
      UnavailableKind.offline => (
          Icons.wifi_off_rounded,
          mlc.textTertiary,
          l10n.unavailableOfflineTitle,
          l10n.unavailableOfflineBody,
        ),
      UnavailableKind.serverError => (
          Icons.cloud_off_rounded,
          mlc.warningColor,
          l10n.unavailableServerTitle,
          l10n.unavailableServerBody,
        ),
      UnavailableKind.notReady => (
          Icons.hourglass_empty_rounded,
          mlc.accentBlue,
          subject == null
              ? l10n.unavailableNotReadyTitle
              : l10n.unavailableNotReadyTitleFor(subject!),
          l10n.unavailableNotReadyBody,
        ),
    };

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: iconColor),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.cardTitle.copyWith(color: mlc.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            // 개발자용 상세는 길게 눌러야 보인다. 평소에 노출하면
            // 사용자에게 의미 없는 영문 스택이 "전문적이지 않게" 보인다.
            GestureDetector(
              onLongPress: detail == null
                  ? null
                  : () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(detail!)),
                      ),
              child: Text(
                body,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: mlc.textSecondary),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _actions(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _actions(BuildContext context, AppLocalizations l10n) {
    final buttons = <Widget>[
      if (onRetry != null)
        FilledButton(onPressed: onRetry, child: Text(l10n.tryAgain)),
      if (onReport != null)
        OutlinedButton.icon(
          onPressed: onReport,
          icon: const Icon(Icons.flag_outlined, size: 16),
          label: Text(l10n.unavailableReport),
        ),
      if (onBack != null)
        TextButton(onPressed: onBack, child: Text(l10n.unavailableGoBack)),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();

    // 세로로 쌓되 폭은 내용에 맞춘다. 가로로 늘어놓으면 1.3배에서 넘친다.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          buttons[i],
        ],
      ],
    );
  }
}
