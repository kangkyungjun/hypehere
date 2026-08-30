import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/ticker_score.dart';
import '../../models/stock_classification.dart';
import '../../services/analytics_api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/app_page_route.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../widgets/common/error_state_view.dart';
import '../ticker_detail/ticker_detail_screen.dart';

/// AI섹터 탭 — AI 점수 순으로 종목을 전체부터 나열.
///
/// - 상단 필터: 전체 + Peter Lynch 분류(고성장주/턴어라운드 등)
/// - 20개씩 노출 + '더 보기'로 추가 로드, 10개마다 배너 광고
class AiSectorScreen extends StatefulWidget {
  const AiSectorScreen({super.key});

  @override
  State<AiSectorScreen> createState() => _AiSectorScreenState();
}

class _AiSectorScreenState extends State<AiSectorScreen> {
  final AnalyticsApiClient _api = AnalyticsApiClient();

  /// 선택된 분류 코드(null = 전체).
  String? _classification;

  List<TickerScore> _items = [];
  bool _loading = true;
  String? _error;

  /// 현재 화면에 노출 중인 개수(20씩 증가).
  static const int _pageSize = 20;
  int _visible = _pageSize;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      List<TickerScore> items;
      if (_classification == null) {
        // 전체: top/bottom 무버를 합쳐 중복 제거 후 점수순
        final insights = await _api.getMarketInsights(top: 500, bottom: 500);
        final seen = <String>{};
        items = <TickerScore>[];
        for (final s in [...insights.topMovers, ...insights.bottomMovers]) {
          if (seen.add(s.ticker)) items.add(s);
        }
      } else {
        final raw = await _api.getStocksByClassification(
          _classification!,
          limit: 100,
        );
        items = raw
            .map(
              (m) => TickerScore(
                ticker: m['ticker'] as String,
                score: ((m['score'] as num?) ?? 0).toDouble(),
                name: m['name'] as String?,
                nameKo: m['name_ko'] as String?,
                changePct: (m['change_pct'] as num?)?.toDouble(),
                close: (m['close'] as num?)?.toDouble(),
              ),
            )
            .toList();
      }
      items.sort((a, b) => b.score.compareTo(a.score));
      if (!mounted) return;
      setState(() {
        _items = items;
        _visible = _pageSize;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onFilter(String? code) {
    if (_classification == code) return;
    setState(() => _classification = code);
    _load();
  }

  void _loadMore() {
    setState(() => _visible = (_visible + _pageSize).clamp(0, _items.length));
  }

  void _onTickerTap(String ticker) {
    Navigator.push(
      context,
      appPageRoute(builder: (_) => TickerDetailScreen(ticker: ticker)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: RefreshIndicator(onRefresh: _load, child: _buildList()),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final l10n = AppLocalizations.of(context);
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final filters = <({String? code, String label})>[
      (code: null, label: l10n.filterAll),
      ...StockClassification.allCategories.map(
        (c) => (code: c['code'], label: isKo ? c['ko']! : c['en']!),
      ),
    ];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final f = filters[i];
          final selected = _classification == f.code;
          return FilterChip(
            label: Text(f.label),
            selected: selected,
            onSelected: (_) => _onFilter(f.code),
            showCheckmark: false,
            selectedColor: context.mlColors.infoBg.withValues(alpha: 0.72),
            backgroundColor: Colors.transparent,
            side: BorderSide(
              color: selected
                  ? context.mlColors.accentBlue.withValues(alpha: 0.28)
                  : context.mlColors.subtleBorder,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.badge),
            ),
            labelStyle: TextStyle(
              fontSize: AppTypography.chipLabel.fontSize,
              fontWeight: AppTypography.semiBold,
              color: selected
                  ? context.mlColors.accentBlue
                  : context.mlColors.textSecondary,
            ),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }

  Widget _buildList() {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ErrorStateView(
        message: l10n.signalLoadFailed,
        detail: _error!,
        onRetry: _load,
        retryLabel: l10n.tryAgain,
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Text(
          l10n.aiNoStocksInSegment,
          style: AppTypography.body.copyWith(
            color: context.mlColors.textSecondary,
          ),
        ),
      );
    }

    final rows = _buildRows(l10n);
    return ListView.builder(
      key: const PageStorageKey('ai_sector_list'),
      padding: EdgeInsets.only(
        top: AppSpacing.xs,
        bottom: MediaQuery.of(context).viewPadding.bottom + 64,
      ),
      itemCount: rows.length,
      itemBuilder: (context, i) => rows[i],
    );
  }

  /// 종목 행 + 10개마다 배너 + 마지막에 '더 보기'.
  List<Widget> _buildRows(AppLocalizations l10n) {
    final shown = _visible.clamp(0, _items.length);
    final widgets = <Widget>[];
    for (int i = 0; i < shown; i++) {
      widgets.add(_buildItem(_items[i], i + 1));
      // 10개마다 배너(섹션 끝 직전 제외)
      if ((i + 1) % 10 == 0 && i != shown - 1) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.lg,
            ),
            child: BannerAdWidget(),
          ),
        );
      }
    }

    if (_visible < _items.length) {
      widgets.add(_buildLoadMore(l10n));
    }

    // 하단 배너
    widgets.add(
      const Padding(
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.lg,
        ),
        child: BannerAdWidget(),
      ),
    );
    return widgets;
  }

  Widget _buildLoadMore(AppLocalizations l10n) {
    final remaining = _items.length - _visible;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: OutlinedButton(
        onPressed: _loadMore,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          side: BorderSide(color: context.mlColors.subtleBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
        child: Text(
          '${l10n.seeMore} (+$remaining)',
          style: TextStyle(
            fontSize: AppTypography.chipLabel.fontSize,
            fontWeight: AppTypography.semiBold,
            color: context.mlColors.accentBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildItem(TickerScore t, int rank) {
    final mlc = context.mlColors;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final scoreColor = t.scoreColor(mlc);
    final primaryName = isKo ? (t.nameKo ?? t.name) : t.name;
    final pct = t.changePct;

    return InkWell(
      onTap: () => _onTickerTap(t.ticker),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: mlc.subtleBorder, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // 순위
            SizedBox(
              width: 26,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: AppTypography.bodySmall,
                  fontWeight: AppTypography.semiBold,
                  color: mlc.textTertiary,
                ),
              ),
            ),
            // 점수 배지
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    t.score.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: AppTypography.headlineSmall,
                      fontWeight: AppTypography.bold,
                      color: scoreColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // 티커 + 이름
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.ticker,
                    style: TextStyle(
                      fontSize: AppTypography.headlineSmall,
                      fontWeight: AppTypography.bold,
                      color: mlc.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (primaryName != null)
                    Text(
                      primaryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppTypography.bodySmall,
                        color: mlc.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            // 변동률
            if (pct != null)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: AppTypography.bodyLarge,
                    fontWeight: AppTypography.bold,
                    color: pct >= 0 ? mlc.gainColor : mlc.lossColor,
                    fontFeatures: AppTypography.tabularFigures,
                  ),
                ),
              ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right, size: 18, color: mlc.textTertiary),
          ],
        ),
      ),
    );
  }
}
