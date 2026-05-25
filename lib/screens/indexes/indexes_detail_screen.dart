import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/macro_data.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../theme/app_spacing.dart';
import '../dashboard/widgets/indexes_tab.dart';

/// Standalone screen wrapping [IndexesTab] for navigation from macro modal.
class IndexesDetailScreen extends StatelessWidget {
  final MacroIndicatorsData? data;
  final MacroSignalsData? signals;

  const IndexesDetailScreen({
    super.key,
    this.data,
    this.signals,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabIndexes)),
      body: Column(
        children: [
          Expanded(child: IndexesTab(data: data, signals: signals)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: BannerAdWidget(),
          ),
        ],
      ),
    );
  }
}
