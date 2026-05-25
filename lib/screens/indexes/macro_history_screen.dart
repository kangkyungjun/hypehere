import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/macro_data.dart';
import '../../services/analytics_api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_stroke.dart';
import '../../theme/app_typography.dart';
import '../../widgets/ads/banner_ad_widget.dart';

/// Macro indicator history screen with trend chart + history list + detail dialog.
class MacroHistoryScreen extends StatefulWidget {
  final String indicatorCode;
  final String title;
  final bool isSignal;

  const MacroHistoryScreen({
    super.key,
    required this.indicatorCode,
    required this.title,
    this.isSignal = false,
  });

  @override
  State<MacroHistoryScreen> createState() => _MacroHistoryScreenState();
}

class _MacroHistoryScreenState extends State<MacroHistoryScreen> {
  MacroHistoryData? _historyData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final data = await AnalyticsApiClient().getMacroHistory(
        widget.indicatorCode,
        limit: 15,
      );
      if (mounted) {
        setState(() {
          _historyData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mlc = context.mlColors;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(_error!, style: TextStyle(color: mlc.textTertiary)),
            )
          : _historyData == null || _historyData!.entries.isEmpty
          ? Center(
              child: Text(
                '\u2013',
                style: TextStyle(
                  fontSize: AppTypography.bodyLarge,
                  color: mlc.textTertiary,
                ),
              ),
            )
          : _buildContent(context, mlc),
    );
  }

  Widget _buildContent(BuildContext context, MarketLensColors mlc) {
    final entries = _historyData!.entries;

    // Build list: chart + data items interleaved with ads every 5
    final children = <Widget>[];

    // Trend chart at top
    children.add(_buildTrendChart(mlc));

    // History items with ads every 5
    int dataIndex = 0;
    for (int i = 0; i < entries.length; i++) {
      children.add(_buildHistoryRow(context, entries[i], mlc));
      dataIndex++;

      if (dataIndex % 5 == 0 && i < entries.length - 1) {
        children.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(child: BannerAdWidget()),
          ),
        );
      }
    }

    // Trailing ad after last group
    if (dataIndex > 0 && dataIndex % 5 != 0) {
      children.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Center(child: BannerAdWidget()),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: children,
    );
  }

  // ── Trend Chart ──────────────────────────────────────────

  Widget _buildTrendChart(MarketLensColors mlc) {
    final entries = _historyData!.entries.reversed.toList(); // oldest → newest
    if (entries.length < 2) return const SizedBox.shrink();

    final spots = <FlSpot>[];
    for (int i = 0; i < entries.length; i++) {
      spots.add(FlSpot(i.toDouble(), entries[i].value));
    }

    final values = entries.map((e) => e.value);
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final range = maxVal - minVal;
    final margin = range > 0 ? range * 0.05 : 0.1;
    final chartMinY = minVal - margin;
    final chartMaxY = maxVal + margin;

    // Trend color: last > first → gain, last < first → loss
    Color trendColor;
    if (entries.last.value > entries.first.value) {
      trendColor = mlc.gainColor;
    } else if (entries.last.value < entries.first.value) {
      trendColor = mlc.lossColor;
    } else {
      trendColor = mlc.accentBlue;
    }

    // Y-axis format
    String formatY(double v) {
      if (_showPercentSuffix) return '${v.toStringAsFixed(2)}%';
      if (widget.indicatorCode == 'CPIAUCSL') return v.toStringAsFixed(1);
      return v.toStringAsFixed(2);
    }

    // X-axis date labels — pick ~4-5 evenly spaced
    final totalPoints = entries.length;
    final interval = totalPoints > 5 ? (totalPoints - 1) / 4.0 : 1.0;

    return Container(
      height: 180,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: mlc.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: LineChart(
        LineChartData(
          minY: chartMinY,
          maxY: chartMaxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: trendColor,
              barWidth: 1,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    trendColor.withValues(alpha: 0.06),
                    trendColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: range > 0 ? range / 3 : 0.1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: mlc.chartGridLine.withValues(alpha: 0.72),
              strokeWidth: AppStroke.hairline,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                interval: range > 0 ? range / 2 : 0.1,
                getTitlesWidget: (value, meta) {
                  if (value == meta.min || value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: Text(
                      formatY(value),
                      style: TextStyle(
                        fontSize: AppTypography.micro,
                        color: mlc.textTertiary,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  final idx = value.round();
                  if (idx < 0 || idx >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  final dateStr = entries[idx].observationDate ?? '';
                  String label = '';
                  if (dateStr.length >= 10) {
                    try {
                      final d = DateTime.parse(dateStr);
                      label = DateFormat('MM/dd').format(d);
                    } catch (_) {
                      label = dateStr.substring(5, 10);
                    }
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: AppTypography.micro,
                        color: mlc.textTertiary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: mlc.chartTooltipBg,
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  final idx = spot.x.round();
                  final entry = entries[idx];
                  final dateStr = entry.observationDate ?? '';
                  return LineTooltipItem(
                    '$dateStr\n${formatY(entry.value)}',
                    TextStyle(
                      fontSize: AppTypography.caption,
                      color: mlc.textPrimary,
                      fontWeight: AppTypography.medium,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  bool get _showPercentSuffix {
    return const [
      'FEDFUNDS',
      'UNRATE',
      'DGS10',
      'DGS2',
      'T10Y2Y',
    ].contains(widget.indicatorCode);
  }

  // ── History Row ──────────────────────────────────────────

  Widget _buildHistoryRow(
    BuildContext context,
    MacroIndicator entry,
    MarketLensColors mlc,
  ) {
    final riskColor = entry.riskColor(mlc);
    final l10n = AppLocalizations.of(context);
    final riskLabel = _riskLabel(context, entry.riskLevel);

    // Format value
    final valueStr =
        '${entry.formattedValue}${entry.showPercentSuffix ? '%' : ''}';

    // Change display
    String changeStr = '\u2013';
    Color changeColor = mlc.neutralColor;
    if (entry.changePct != null && entry.changePct != 0) {
      changeStr =
          '${entry.changeArrow}${entry.changePct!.abs().toStringAsFixed(2)}%';
      changeColor = entry.changeColor(mlc);
    }

    // Date
    final dateStr = entry.observationDate ?? '';

    return GestureDetector(
      onTap: () => _showDetailDialog(context, entry, mlc, l10n),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: mlc.cardBackground,
            border: Border.all(color: mlc.subtleBorder),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: riskColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Date
              SizedBox(
                width: 82,
                child: Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: AppTypography.bodySmall,
                    color: mlc.textSecondary,
                  ),
                ),
              ),
              // Value
              SizedBox(
                width: 72,
                child: Text(
                  valueStr,
                  style: TextStyle(
                    fontSize: AppTypography.bodyMedium,
                    fontWeight: AppTypography.semiBold,
                    color: mlc.textPrimary,
                  ),
                ),
              ),
              // Change
              SizedBox(
                width: 70,
                child: Text(
                  changeStr,
                  style: TextStyle(
                    fontSize: AppTypography.bodySmall,
                    fontWeight: AppTypography.medium,
                    color: changeColor,
                  ),
                ),
              ),
              const Spacer(),
              // Risk badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  riskLabel,
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    fontWeight: AppTypography.medium,
                    color: riskColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Detail Dialog ────────────────────────────────────────

  void _showDetailDialog(
    BuildContext context,
    MacroIndicator entry,
    MarketLensColors mlc,
    AppLocalizations l10n,
  ) {
    final langCode = Localizations.localeOf(context).languageCode;
    final riskColor = entry.riskColor(mlc);
    final riskLabel = _riskLabel(context, entry.riskLevel);
    final message = entry.descriptionLocalized(l10n, langCode);
    final changeColor = entry.changeColor(mlc);
    final subColor = mlc.textTertiary;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title: ● [risk badge]  indicator name  date
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: riskColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (riskLabel != '\u2013') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: riskColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        riskLabel,
                        style: TextStyle(
                          fontSize: AppTypography.caption,
                          fontWeight: AppTypography.semiBold,
                          color: riskColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: AppTypography.bodyLarge,
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      Text(
                        entry.observationDate ?? '',
                        style: TextStyle(
                          fontSize: AppTypography.caption,
                          color: subColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              // Values Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.formattedValue}${entry.showPercentSuffix ? '%' : ''}',
                          style: const TextStyle(
                            fontSize: AppTypography.displayLarge,
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          l10n.macroCurrentLabel,
                          style: TextStyle(
                            fontSize: AppTypography.caption,
                            color: subColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (entry.changePct != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.changeArrow} ${entry.changePct!.abs().toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontSize: AppTypography.headlineMedium,
                              fontWeight: AppTypography.semiBold,
                              color: changeColor,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            l10n.macroChangeLabel,
                            style: TextStyle(
                              fontSize: AppTypography.caption,
                              color: subColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              // Signal message
              if (message != null && message.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: AppTypography.bodyMedium,
                    color: mlc.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Risk helpers ─────────────────────────────────────────

  String _riskLabel(BuildContext context, String? riskLevel) {
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
        return '\u2013';
    }
  }
}
