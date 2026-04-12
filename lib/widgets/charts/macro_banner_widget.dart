import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/macro_data.dart';
import '../../utils/multilingual.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_duration.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'macro_gauge_painter.dart';

/// Unified gauge item for both MacroIndicator and MacroSignal
class _GaugeItem {
  final String label;
  final String formattedValue;
  final String? riskLevel;
  final bool showPercent;
  final double? high3m;
  final double? avg3m;
  final double? low3m;
  final VoidCallback onTap;

  _GaugeItem({
    required this.label,
    required this.formattedValue,
    required this.riskLevel,
    required this.showPercent,
    this.high3m,
    this.avg3m,
    this.low3m,
    required this.onTap,
  });
}

/// Macro economic banner with overall status header + auto-sliding gauge cards
///
/// Layout:
/// ┌──────────────────────────────────────────┐
/// │ ● 거시경제: 양호              [ⓘ legend] │  ← fixed header
/// │ 전반적으로 안정적. 정상 투자 유지.         │
/// │ [기준금리] [시장심리] [실업률] [수익률곡선] │  ← synced tabs
/// │ ┌──────────────────────────────────────┐  │
/// │ │  ╭─────╮   3M H  4.25%             │  │  ← PageView gauge card
/// │ │  │ ↗   │   3M A  3.85%             │  │
/// │ │  ╰─────╯   3M L  3.50%             │  │
/// │ │   3.64%    기준금리                 │  │
/// │ └──────────────────────────────────────┘  │
/// └──────────────────────────────────────────┘
class MacroBannerWidget extends StatefulWidget {
  final MacroIndicatorsData? data;
  final MacroSignalsData? signals;

  const MacroBannerWidget({super.key, this.data, this.signals});

  @override
  State<MacroBannerWidget> createState() => _MacroBannerWidgetState();
}

class _MacroBannerWidgetState extends State<MacroBannerWidget> {
  late PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentPage = 0;
  bool _isTouching = false;
  bool _showLegend = false;

  static const Duration _pauseDuration = Duration(seconds: 3);
  static const Duration _slideDuration = AppDuration.slow;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoSlide();
    });
  }

  @override
  void didUpdateWidget(MacroBannerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _stopAutoSlide();
    _currentPage = 0;
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoSlide();
    });
  }

  @override
  void dispose() {
    _stopAutoSlide();
    _pageController.dispose();
    super.dispose();
  }

  // ── Auto-slide logic ─────────────────────────────────────────

  void _startAutoSlide() {
    _stopAutoSlide();
    final items = _buildGaugeItems();
    if (items.length <= 1) return;

    _autoSlideTimer = Timer.periodic(_pauseDuration, (_) {
      if (!mounted || _isTouching) return;
      final next = (_currentPage + 1) % items.length;
      _pageController.animateToPage(
        next,
        duration: _slideDuration,
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = null;
  }

  void _onTouchDown() {
    _isTouching = true;
    _stopAutoSlide();
  }

  void _onTouchUp() {
    _isTouching = false;
    _startAutoSlide();
  }

  // ── Helpers ────────────────────────────────────────────────────

  MacroSignal? get _overallMacro {
    if (widget.signals == null) return null;
    try {
      return widget.signals!.signals
          .firstWhere((s) => s.signalCode == 'overall_macro');
    } catch (_) {
      return null;
    }
  }

  List<MacroSignal> get _chipSignals {
    if (widget.signals == null) return [];
    return widget.signals!.signals
        .where((s) => s.signalCode != 'overall_macro')
        .toList();
  }

  String _effectiveRiskLevel(MacroSignal signal) {
    return signal.effectiveRiskLevel ?? 'NEUTRAL';
  }

  List<_GaugeItem> _buildGaugeItems() {
    final l10n = AppLocalizations.of(context);
    final indicators = widget.data?.indicators ?? [];
    final signals = _chipSignals;
    final items = <_GaugeItem>[];

    for (final i in indicators) {
      items.add(_GaugeItem(
        label: i.shortLabelLocalized(l10n),
        formattedValue: '${i.formattedValue}${i.showPercentSuffix ? '%' : ''}',
        riskLevel: i.riskLevel,
        showPercent: i.showPercentSuffix,
        high3m: i.high3m,
        avg3m: i.avg3m,
        low3m: i.low3m,
        onTap: () => _showIndicatorDetail(context, i),
      ));
    }

    for (final s in signals) {
      items.add(_GaugeItem(
        label: s.shortLabelLocalized(l10n),
        formattedValue: s.formattedValue,
        riskLevel: _effectiveRiskLevel(s),
        showPercent: false,
        high3m: s.high3m,
        avg3m: s.avg3m,
        low3m: s.low3m,
        onTap: () => _showSignalDetail(context, s),
      ));
    }

    return items;
  }

  Color _riskDotColor(String? riskLevel) {
    final mlc = context.mlColors;
    switch (riskLevel) {
      case 'BEARISH':
      case 'CRITICAL':
        return mlc.lossColor;
      case 'CAUTIOUS':
      case 'WARNING':
        return mlc.warningColor;
      case 'NEUTRAL':
      case 'NORMAL':
        return mlc.neutralColor;
      case 'POSITIVE':
        return mlc.gainColor;
      case 'BULLISH':
        return mlc.accentBlue;
      default:
        return mlc.neutralColor;
    }
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasIndicators =
        widget.data != null && widget.data!.indicators.isNotEmpty;
    final hasSignals =
        widget.signals != null && widget.signals!.signals.isNotEmpty;

    if (!hasIndicators && !hasSignals) {
      return const SizedBox.shrink();
    }

    final items = _buildGaugeItems();

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: context.mlColors.subtleBorder, width: 1),
          bottom: BorderSide(color: context.mlColors.subtleBorder, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOverallHeader(),
          if (items.isNotEmpty) ...[
            _buildIndicatorTabs(items),
            _buildGaugePageView(items),
          ],
          if (_showLegend) _buildLegend(),
        ],
      ),
    );
  }

  /// Fixed header: ● 거시경제: 양호 + message + legend toggle
  Widget _buildOverallHeader() {
    final langCode = Localizations.localeOf(context).languageCode;
    final overall = _overallMacro;

    String summary = '';
    String? keyDrivers;
    if (overall?.cleanMessage != null) {
      final lines = overall!.cleanMessage!.localize(langCode).split('\n');
      summary = lines.first;
      if (summary.contains(': ')) {
        summary = summary.substring(summary.indexOf(': ') + 2);
      }
      if (lines.length > 1) {
        keyDrivers = lines.sublist(1).join(' ').trim();
      }
    }

    final l10n = AppLocalizations.of(context);
    final riskLabel = overall?.riskLabelLocalized(l10n) ?? '–';
    final dotColor = overall?.riskColor(context.mlColors) ?? context.mlColors.textTertiary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.md, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${l10n.macroOverall}: $riskLabel',
                style: const TextStyle(
                  fontSize: AppTypography.bodyLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _showLegend = !_showLegend),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              summary,
              style: TextStyle(
                fontSize: AppTypography.bodySmall,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (keyDrivers != null && keyDrivers.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(
              keyDrivers,
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: Theme.of(context).colorScheme.outline,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  /// Horizontally scrollable indicator name tabs synced with PageView
  Widget _buildIndicatorTabs(List<_GaugeItem> items) {
    return SizedBox(
      height: 26,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final isSelected = _currentPage == index;
          final item = items[index];
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: _slideDuration,
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: AppSpacing.xs),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? _riskDotColor(item.riskLevel).withValues(alpha: 0.15)
                    : context.mlColors.sectionBackground,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: isSelected
                      ? _riskDotColor(item.riskLevel).withValues(alpha: 0.5)
                      : context.mlColors.subtleBorder,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    fontWeight: isSelected ? FontWeight.bold : AppTypography.medium,
                    color: isSelected
                        ? _riskDotColor(item.riskLevel)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// PageView with gauge cards (auto-slide + manual swipe)
  Widget _buildGaugePageView(List<_GaugeItem> items) {
    return SizedBox(
      height: 116,
      child: GestureDetector(
        onPanDown: (_) => _onTouchDown(),
        onPanEnd: (_) => _onTouchUp(),
        onPanCancel: () => _onTouchUp(),
        child: PageView.builder(
          controller: _pageController,
          itemCount: items.length,
          onPageChanged: (index) {
            setState(() => _currentPage = index);
          },
          itemBuilder: (context, index) {
            final item = items[index];
            return GestureDetector(
              onTap: item.onTap,
              child: _buildGaugeCard(item),
            );
          },
        ),
      ),
    );
  }

  /// Single gauge card: [65% gauge | 35% 3M stats]
  Widget _buildGaugeCard(_GaugeItem item) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.xs, AppSpacing.lg, AppSpacing.xs),
      decoration: BoxDecoration(
        color: context.mlColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.mlColors.subtleBorder),
      ),
      child: Row(
        children: [
          // Left 65%: Gauge
          Expanded(
            flex: 65,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 68,
                  child: CustomPaint(
                    size: const Size(double.infinity, 68),
                    painter: MacroGaugePainter(
                      riskLevel: item.riskLevel,
                      needleColor: context.mlColors.textPrimary,
                      innerDotColor: context.mlColors.cardBackground,
                    ),
                  ),
                ),
                Text(
                  item.formattedValue,
                  style: TextStyle(
                    fontSize: AppTypography.headlineMedium,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1.2,
                  ),
                ),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: subColor,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          // Right 35%: 3M stats
          Expanded(
            flex: 35,
            child: _build3mStats(item, subColor),
          ),
        ],
      ),
    );
  }

  /// 3-month stats column (최고 / 평균 / 최저)
  Widget _build3mStats(_GaugeItem item, Color subColor) {
    final l10n = AppLocalizations.of(context);
    final textColor = Theme.of(context).colorScheme.onSurface;

    String formatVal(double? val) {
      if (val == null) return '–';
      if (val.abs() >= 100) return val.toStringAsFixed(1);
      return val.toStringAsFixed(2);
    }

    String suffix = item.showPercent ? '%' : '';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.macro3mTitle,
          style: TextStyle(
            fontSize: AppTypography.micro,
            fontWeight: FontWeight.bold,
            color: subColor,
            height: 1.0,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        _stat3mRow(l10n.macro3mHigh, formatVal(item.high3m), suffix, context.mlColors.lossColor, textColor),
        const SizedBox(height: 3),
        _stat3mRow(l10n.macro3mAvg, formatVal(item.avg3m), suffix, subColor, textColor),
        const SizedBox(height: 3),
        _stat3mRow(l10n.macro3mLow, formatVal(item.low3m), suffix, context.mlColors.accentBlue, textColor),
      ],
    );
  }

  Widget _stat3mRow(String label, String value, String suffix, Color labelColor, Color valueColor) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.micro,
              fontWeight: FontWeight.bold,
              color: labelColor,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Expanded(
          child: Text(
            '$value$suffix',
            style: TextStyle(
              fontSize: AppTypography.bodyMedium,
              fontWeight: AppTypography.semiBold,
              color: valueColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Detail dialogs ────────────────────────────────────────

  String _riskLabel(String? riskLevel) {
    final l10n = AppLocalizations.of(context);
    switch (riskLevel) {
      case 'BEARISH':
      case 'CRITICAL':
        return l10n.riskBearish;
      case 'CAUTIOUS':
      case 'WARNING':
        return l10n.riskCautious;
      case 'NEUTRAL':
      case 'NORMAL':
        return l10n.riskNeutral;
      case 'POSITIVE':
        return l10n.riskPositive;
      case 'BULLISH':
        return l10n.riskBullish;
      default:
        return '–';
    }
  }

  void _showIndicatorDetail(BuildContext context, MacroIndicator indicator) {
    final langCode = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context);
    final dotColor = _riskDotColor(indicator.riskLevel);
    final label = _riskLabel(indicator.riskLevel);
    final message = indicator.descriptionLocalized(l10n, langCode);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    indicator.shortLabelLocalized(l10n),
                    style: const TextStyle(
                      fontSize: AppTypography.headlineMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Text(
                l10n.macroCurrentValue('${indicator.formattedValue}${indicator.showPercentSuffix ? '%' : ''}'),
                style: const TextStyle(fontSize: AppTypography.bodyLarge),
              ),
              if (indicator.changePct != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.macroChange('${indicator.changeArrow}${indicator.changePct!.abs().toStringAsFixed(2)}%'),
                  style: TextStyle(fontSize: AppTypography.bodyLarge, color: indicator.changeColor(context.mlColors)),
                ),
              ],
              if (label != '–') ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: dotColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: AppTypography.bodyMedium,
                      fontWeight: AppTypography.semiBold,
                      color: dotColor,
                    ),
                  ),
                ),
              ],
              if (message != null && message.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: AppTypography.bodyMedium,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showSignalDetail(BuildContext context, MacroSignal signal) {
    final langCode = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context);
    final dotColor = signal.riskColor(context.mlColors);
    final label = signal.riskLabelLocalized(l10n);
    final message = signal.cleanMessage?.localize(langCode);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    signal.shortLabelLocalized(l10n),
                    style: const TextStyle(
                      fontSize: AppTypography.headlineMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Text(
                l10n.macroCurrentValue(signal.formattedValue),
                style: const TextStyle(fontSize: AppTypography.bodyLarge),
              ),
              if (label != '–') ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: dotColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: AppTypography.bodyMedium,
                      fontWeight: AppTypography.semiBold,
                      color: dotColor,
                    ),
                  ),
                ),
              ],
              if (message != null && message.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: AppTypography.bodyMedium,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Toggleable legend showing risk level color meanings
  Widget _buildLegend() {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      ('BEARISH', l10n.riskBearish, context.mlColors.lossColor),
      ('CAUTIOUS', l10n.riskCautious, context.mlColors.warningColor),
      ('NEUTRAL', l10n.riskNeutral, context.mlColors.neutralColor),
      ('POSITIVE', l10n.riskPositive, context.mlColors.gainColor),
      ('BULLISH', l10n.riskBullish, context.mlColors.accentBlue),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xxs, AppSpacing.lg, AppSpacing.sm),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: items.map((item) {
          final (_, label, color) = item;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isDark ? color.withValues(alpha: 0.8) : color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
