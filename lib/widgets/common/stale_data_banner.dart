import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/chart_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// 이 종목의 분석이 시장보다 뒤처졌다는 안내 (서버 `freshness`, S2).
///
/// ## 판정은 서버가 한다
///
/// 앱은 시장의 최신 거래일을 모른다. 앱이 쓸 수 있는 유일한 비교 대상(다른
/// 종목의 날짜)은 공급원 장애로 일부만 하루 늦으면 무너진다 — 2026-10-01이
/// 그런 날이었다. 그때 앱이 추측하면 **멀쩡한 종목에 경고가 붙는데**, 그건
/// 아무 말도 안 하는 것보다 나쁘다.
///
/// 그래서 `stale` 여부도, 임계값도 서버가 정한다. 앱은 그릴 뿐이다.
///
/// ## 왜 경고색이 아닌가
///
/// 오래된 데이터는 **고장이 아니다.** 상장폐지된 종목은 영원히 stale이고,
/// 그건 정상이다. 빨간색을 쓰면 사용자가 앱이 깨진 줄 안다. 중립 톤으로
/// 사실만 말한다.
class StaleDataBanner extends StatelessWidget {
  const StaleDataBanner({super.key, required this.freshness});

  /// null이거나 `stale`이 아니면 **아무것도 그리지 않는다.**
  ///
  /// 호출부가 조건문 없이 끼워 넣을 수 있게 하려는 것이다. 조건을 호출부에
  /// 두면 화면이 늘 때마다 같은 분기를 복사하게 되고, 한 곳만 빠뜨린다.
  final Freshness? freshness;

  @override
  Widget build(BuildContext context) {
    final f = freshness;
    if (f == null || !f.stale) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final mlc = context.mlColors;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: mlc.sectionBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: mlc.subtleBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.history_rounded, size: 16, color: mlc.textTertiary),
          const SizedBox(width: AppSpacing.sm),
          // Expanded가 없으면 긴 문장이 1.3배에서 가로로 넘친다.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.staleDataBadge(f.tradingDaysBehind),
                  style: AppTypography.label.copyWith(
                    color: mlc.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  l10n.staleDataExplain(_fmt(f.asOf), _fmt(f.marketAsOf)),
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: mlc.textTertiary,
                    // 행간을 고정한다. 안 주면 Material의 bodyMedium에서
                    // 1.43을 상속해 계산과 렌더가 어긋난다.
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
