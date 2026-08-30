import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_shadow.dart';

/// 지수 카드(S&P/NASDAQ/DOW) 탭 → 트리맵 필터 동작을 알리는 1회성 안내 배너.
///
/// "확인"을 누르면 SharedPreferences에 dismiss 플래그 저장 → 이후 영구 숨김.
/// 로딩 동안은 SizedBox.shrink로 깜빡임 방지.
class IndexFilterHint extends StatefulWidget {
  const IndexFilterHint({super.key});

  static const String _kDismissedKey = 'dashboard_index_filter_hint_dismissed';

  /// QA·디버깅용: 안내 다시 보이게.
  static Future<void> resetHint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDismissedKey);
  }

  @override
  State<IndexFilterHint> createState() => _IndexFilterHintState();
}

class _IndexFilterHintState extends State<IndexFilterHint> {
  /// null = SharedPreferences 로딩 중, true = 표시, false = 숨김.
  bool? _visible;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool(IndexFilterHint._kDismissedKey) ?? false;
    if (!mounted) return;
    setState(() => _visible = !dismissed);
  }

  Future<void> _dismiss() async {
    setState(() => _visible = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(IndexFilterHint._kDismissedKey, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_visible != true) return const SizedBox.shrink();
    final mlc = context.mlColors;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: mlc.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadow.card(Colors.black),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 14,
            color: mlc.textSecondary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              l10n.dashboardIndexFilterHint,
              style: TextStyle(
                fontSize: AppTypography.bodySmall,
                color: mlc.textSecondary,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          TextButton(
            onPressed: _dismiss,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 28),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(
              l10n.confirm,
              style: TextStyle(
                fontSize: AppTypography.bodySmall,
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
