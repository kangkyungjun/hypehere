import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../models/chart_data.dart';
import '../../utils/multilingual.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'dividends_widget.dart';
import 'valuation_metrics_widget.dart';
import 'institutional_flow_widget.dart';
import 'short_interest_widget.dart';
import '../common/modal_handle_bar.dart';
import '../common/ml_expandable_card.dart';

/// Company profile overview card
///
/// Card shows: company name, industry, country, employee count + chevron.
/// Tapping opens a modal bottom sheet with full profile details,
/// dividends, valuation, institutional flow, and short interest.
class CompanyProfileCard extends StatefulWidget {
  final CompanyProfile? profile;
  final List<DividendEntry>? dividends;
  final KeyMetrics? keyMetrics;
  final List<ChartDataPoint>? dataPoints;

  const CompanyProfileCard({
    super.key,
    required this.profile,
    this.dividends,
    this.keyMetrics,
    this.dataPoints,
  });

  @override
  State<CompanyProfileCard> createState() => _CompanyProfileCardState();
}

class _CompanyProfileCardState extends State<CompanyProfileCard> {
  @override
  Widget build(BuildContext context) {
    if (widget.profile == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final p = widget.profile!;

    // Hide if all fields are null
    if (p.longName == null &&
        p.industry == null &&
        p.country == null &&
        p.summary == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _showDetailModal(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with chevron
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.companyOverview,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Company name
            if (p.longName != null)
              Text(
                p.longName!,
                style: const TextStyle(
                  fontSize: AppTypography.headlineLarge,
                  fontWeight: AppTypography.semiBold,
                ),
              ),

            const SizedBox(height: AppSpacing.sm),

            // Industry · Country
            if (p.industry != null || p.country != null)
              Row(
                children: [
                  if (p.industry != null)
                    Text(
                      p.industry!,
                      style: TextStyle(fontSize: AppTypography.bodyMedium, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  if (p.industry != null && p.country != null)
                    Text(
                      '  ·  ',
                      style: TextStyle(fontSize: AppTypography.bodyMedium, color: Theme.of(context).colorScheme.outline),
                    ),
                  if (p.country != null)
                    Text(
                      p.country!,
                      style: TextStyle(fontSize: AppTypography.bodyMedium, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                ],
              ),

            // Employees
            if (p.employees != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.employeeCount(NumberFormat.compact().format(p.employees)),
                style: TextStyle(fontSize: AppTypography.bodySmall, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Modal
  // ---------------------------------------------------------------------------

  void _showDetailModal(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;
    final p = widget.profile!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.lg),
            children: [
              // Handle bar
              const ModalHandleBar(),
              const SizedBox(height: AppSpacing.xl),

              // Title
              Text(
                AppLocalizations.of(ctx).companyDetails,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: AppTypography.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Company name
              if (p.longName != null)
                Text(
                  p.longName!,
                  style: const TextStyle(fontSize: AppTypography.displayMedium, fontWeight: AppTypography.semiBold),
                ),
              const SizedBox(height: AppSpacing.sm),

              // Industry · Country
              if (p.industry != null || p.country != null)
                Row(
                  children: [
                    if (p.industry != null)
                      Text(
                        p.industry!,
                        style: TextStyle(fontSize: AppTypography.bodyLarge, color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                      ),
                    if (p.industry != null && p.country != null)
                      Text(
                        '  ·  ',
                        style: TextStyle(fontSize: AppTypography.bodyLarge, color: Theme.of(ctx).colorScheme.outline),
                      ),
                    if (p.country != null)
                      Text(
                        p.country!,
                        style: TextStyle(fontSize: AppTypography.bodyLarge, color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),

              // Employees
              if (p.employees != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  AppLocalizations.of(ctx).employeeCount(NumberFormat('#,###').format(p.employees)),
                  style: TextStyle(fontSize: AppTypography.bodyMedium, color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                ),
              ],

              // --- Summary ---
              if (p.summary != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _buildSectionLabel(ctx, AppLocalizations.of(ctx).companyIntro),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  p.summary!.localize(langCode),
                  style: TextStyle(
                    fontSize: AppTypography.bodyMedium,
                    color: Theme.of(ctx).colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
              ],

              // Website
              if (p.website != null) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Icon(Icons.link, size: 14, color: context.mlColors.accentBlue),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        p.website!.replaceFirst(RegExp(r'https?://'), ''),
                        style: TextStyle(
                          fontSize: AppTypography.bodySmall,
                          color: context.mlColors.accentBlue,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // --- Dividends ---
              if (widget.dividends != null && widget.dividends!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                DividendsWidget(
                  dividends: widget.dividends,
                  dividendYield: widget.keyMetrics?.dividendYield,
                  margin: EdgeInsets.zero,
                ),
              ],

              // --- Valuation ---
              if (widget.keyMetrics != null) ...[
                const SizedBox(height: AppSpacing.xs),
                ValuationMetricsWidget(
                  metrics: widget.keyMetrics,
                  margin: EdgeInsets.zero,
                ),
              ],

              // --- Institutional Flow ---
              if (widget.dataPoints != null && widget.dataPoints!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                InstitutionalFlowWidget(
                  dataPoints: widget.dataPoints!,
                  margin: EdgeInsets.zero,
                ),
              ],

              // --- Short Interest ---
              if (widget.dataPoints != null && widget.dataPoints!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                ShortInterestWidget(
                  dataPoints: widget.dataPoints!,
                  margin: EdgeInsets.zero,
                ),
              ],

              SizedBox(height: MediaQuery.of(ctx).padding.bottom + 48),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// 두 파일에 한 글자도 다르지 않게 복붙돼 있던 헬퍼 — 프리미티브로 수렴.
  Widget _buildSectionLabel(BuildContext ctx, String text) =>
      MlCardSectionLabel(text);
}
