import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/analytics_api_client.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

/// Bottom sheet for editing holding info (date, price, shares).
class EditHoldingSheet extends StatefulWidget {
  final String ticker;
  final String? name;
  final double currentShares;
  final double avgPrice;
  final DateTime? purchaseDate;

  const EditHoldingSheet({
    super.key,
    required this.ticker,
    this.name,
    required this.currentShares,
    required this.avgPrice,
    this.purchaseDate,
  });

  static Future<({double shares, double avgPrice})?> show(
    BuildContext context, {
    required String ticker,
    String? name,
    required double currentShares,
    required double avgPrice,
    DateTime? purchaseDate,
  }) {
    return showModalBottomSheet<({double shares, double avgPrice})>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (_) => EditHoldingSheet(
        ticker: ticker,
        name: name,
        currentShares: currentShares,
        avgPrice: avgPrice,
        purchaseDate: purchaseDate,
      ),
    );
  }

  @override
  State<EditHoldingSheet> createState() => _EditHoldingSheetState();
}

class _EditHoldingSheetState extends State<EditHoldingSheet> {
  final _sharesController = TextEditingController();
  final _priceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _apiClient = AnalyticsApiClient();

  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.purchaseDate ?? DateTime.now();
    _priceController.text = widget.avgPrice.toStringAsFixed(2);
    _sharesController.text = widget.currentShares.toStringAsFixed(
        widget.currentShares == widget.currentShares.truncateToDouble() ? 0 : 2);
    _sharesController.addListener(_onChanged);
    _priceController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _sharesController.dispose();
    _priceController.dispose();
    _apiClient.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      // Auto-fetch close price for new date
      _fetchClosePrice();
    }
  }

  Future<void> _fetchClosePrice() async {
    try {
      final result = await _apiClient.getClosePrice(widget.ticker, _selectedDate);
      if (mounted && result.close != null) {
        setState(() {
          _priceController.text = result.close!.toStringAsFixed(2);
        });
      }
    } catch (_) {}
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xxl + bottomInset + bottomPadding),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadius.xxs),
                ),
              ),
            ),

            Text(
              l10n.editHoldingTitle(widget.ticker),
              style: const TextStyle(fontSize: AppTypography.headlineLarge, fontWeight: FontWeight.bold),
            ),
            if (widget.name != null)
              Text(widget.name!, style: TextStyle(fontSize: AppTypography.bodyMedium, color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.xl),

            // Date
            Text(l10n.purchaseDate, style: const TextStyle(fontSize: AppTypography.bodyMedium, fontWeight: AppTypography.medium)),
            const SizedBox(height: AppSpacing.xs),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: AppSpacing.md),
                    Text(_formatDate(_selectedDate), style: const TextStyle(fontSize: AppTypography.headlineSmall)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Avg price
            Text(l10n.avgPriceLabel, style: const TextStyle(fontSize: AppTypography.bodyMedium, fontWeight: AppTypography.medium)),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              decoration: InputDecoration(
                prefixText: '\$ ',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return l10n.invalidPrice;
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Shares
            Text(l10n.shares, style: const TextStyle(fontSize: AppTypography.bodyMedium, fontWeight: AppTypography.medium)),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: _sharesController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              decoration: InputDecoration(
                prefixText: '# ',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return l10n.invalidShares;
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  final shares = double.parse(_sharesController.text);
                  final avgPrice = double.parse(_priceController.text);
                  Navigator.pop(context, (shares: shares, avgPrice: avgPrice));
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                ),
                child: Text(l10n.saveChanges, style: const TextStyle(fontSize: AppTypography.headlineSmall)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
