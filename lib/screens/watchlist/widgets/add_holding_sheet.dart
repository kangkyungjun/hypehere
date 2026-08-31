import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/analytics_api_client.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_stroke.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/common/modal_handle_bar.dart';

/// Bottom sheet for adding a holding with date picker + auto close price.
///
/// Returns (shares, avgPrice, date) on confirm, null on cancel.
class AddHoldingSheet extends StatefulWidget {
  final String ticker;
  final String? name;

  const AddHoldingSheet({super.key, required this.ticker, this.name});

  static Future<({double shares, double avgPrice, DateTime date})?> show(
    BuildContext context, {
    required String ticker,
    String? name,
  }) {
    return showModalBottomSheet<
      ({double shares, double avgPrice, DateTime date})
    >(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.mlColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      builder: (_) => AddHoldingSheet(ticker: ticker, name: name),
    );
  }

  @override
  State<AddHoldingSheet> createState() => _AddHoldingSheetState();
}

class _AddHoldingSheetState extends State<AddHoldingSheet> {
  final _sharesController = TextEditingController();
  final _priceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _apiClient = AnalyticsApiClient();

  DateTime _selectedDate = DateTime.now();
  String? _actualPriceDate;
  bool _loadingPrice = false;
  bool _priceError = false;
  double? _totalCost;

  @override
  void initState() {
    super.initState();
    _sharesController.addListener(_updateTotal);
    _priceController.addListener(_updateTotal);
    _fetchClosePrice();
  }

  @override
  void dispose() {
    _sharesController.dispose();
    _priceController.dispose();
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _fetchClosePrice() async {
    setState(() => _loadingPrice = true);
    try {
      final result = await _apiClient.getClosePrice(
        widget.ticker,
        _selectedDate,
      );
      if (mounted) {
        setState(() {
          _loadingPrice = false;
          _actualPriceDate = result.date;
          if (result.close != null) {
            _priceController.text = result.close!.toStringAsFixed(2);
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingPrice = false;
          _priceError = true;
        });
      }
    }
  }

  void _updateTotal() {
    final shares = double.tryParse(_sharesController.text);
    final price = double.tryParse(_priceController.text);
    setState(() {
      _totalCost = (shares != null && price != null) ? shares * price : null;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      _fetchClosePrice();
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mlc = context.mlColors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    final dateStr = _formatDate(_selectedDate);
    final isDifferentDate =
        _actualPriceDate != null && _actualPriceDate != dateStr;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xxl + bottomInset + bottomPadding,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: ModalHandleBar()),

            // Title
            Text(
              l10n.addHoldingTitle(widget.ticker),
              style: TextStyle(
                fontSize: AppTypography.headlineLarge,
                fontWeight: AppTypography.bold,
                color: mlc.textPrimary,
              ),
            ),
            if (widget.name != null)
              Text(
                widget.name!,
                style: TextStyle(
                  fontSize: AppTypography.bodyMedium,
                  color: mlc.textSecondary,
                ),
              ),
            const SizedBox(height: AppSpacing.xl),

            // Purchase date
            Text(
              l10n.purchaseDate,
              style: const TextStyle(
                fontSize: AppTypography.bodyMedium,
                fontWeight: AppTypography.medium,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.lg,
                ),
                decoration: BoxDecoration(
                  color: mlc.infoBg.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: mlc.accentBlue),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: AppTypography.headlineSmall,
                        fontWeight: AppTypography.semiBold,
                        color: mlc.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Price input
            Text(
              l10n.avgPrice,
              style: const TextStyle(
                fontSize: AppTypography.bodyMedium,
                fontWeight: AppTypography.medium,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                prefixText: '\$ ',
                suffixIcon: _loadingPrice
                    ? const Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: AppStroke.medium,
                          ),
                        ),
                      )
                    : _priceError && _priceController.text.isEmpty
                    ? IconButton(
                        tooltip: l10n.refresh,
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: () {
                          setState(() => _priceError = false);
                          _fetchClosePrice();
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.lg,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return l10n.invalidPrice;
                return null;
              },
            ),
            if (isDifferentDate)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  l10n.holidayPriceNotice(_actualPriceDate!),
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: mlc.accentBlue,
                  ),
                ),
              )
            else if (!_loadingPrice && _priceController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  l10n.closingPriceAuto,
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: mlc.textSecondary,
                  ),
                ),
              ),
            if (_priceError && _priceController.text.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  Localizations.localeOf(context).languageCode == 'ko'
                      ? AppLocalizations.of(context).closePriceUnavailable
                      : 'Could not load close price. Please enter manually.',
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: context.mlColors.dangerColor,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),

            // Shares input
            Text(
              l10n.shares,
              style: const TextStyle(
                fontSize: AppTypography.bodyMedium,
                fontWeight: AppTypography.medium,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: _sharesController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                prefixText: '# ',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.lg,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return l10n.invalidShares;
                return null;
              },
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Total cost
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: mlc.sectionBackground,
                border: Border.all(color: mlc.subtleBorder),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.totalCost,
                    style: TextStyle(
                      fontSize: AppTypography.bodyMedium,
                      color: mlc.textSecondary,
                    ),
                  ),
                  Text(
                    _totalCost != null
                        ? '\$${_totalCost!.toStringAsFixed(2)}'
                        : '—',
                    style: const TextStyle(
                      fontSize: AppTypography.headlineSmall,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  final shares = double.parse(_sharesController.text);
                  final avgPrice = double.parse(_priceController.text);
                  Navigator.pop(context, (
                    shares: shares,
                    avgPrice: avgPrice,
                    date: _selectedDate,
                  ));
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                ),
                child: Text(
                  l10n.addToHoldings,
                  style: const TextStyle(fontSize: AppTypography.headlineSmall),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
