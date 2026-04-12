import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/analytics_api_client.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

/// Bottom sheet for selling shares with date picker + auto close price.
class SellHoldingSheet extends StatefulWidget {
  final String ticker;
  final String? name;
  final double currentShares;
  final double avgPrice;
  final double? currentPrice;

  const SellHoldingSheet({
    super.key,
    required this.ticker,
    this.name,
    required this.currentShares,
    required this.avgPrice,
    this.currentPrice,
  });

  static Future<({double shares, double price, DateTime date})?> show(
    BuildContext context, {
    required String ticker,
    String? name,
    required double currentShares,
    required double avgPrice,
    double? currentPrice,
  }) {
    return showModalBottomSheet<({double shares, double price, DateTime date})>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (_) => SellHoldingSheet(
        ticker: ticker,
        name: name,
        currentShares: currentShares,
        avgPrice: avgPrice,
        currentPrice: currentPrice,
      ),
    );
  }

  @override
  State<SellHoldingSheet> createState() => _SellHoldingSheetState();
}

class _SellHoldingSheetState extends State<SellHoldingSheet> {
  final _sharesController = TextEditingController();
  final _priceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _apiClient = AnalyticsApiClient();

  DateTime _selectedDate = DateTime.now();
  String? _actualPriceDate;
  bool _loadingPrice = false;
  bool _priceError = false;

  @override
  void initState() {
    super.initState();
    _sharesController.addListener(_onChanged);
    _priceController.addListener(_onChanged);
    _fetchClosePrice();
  }

  @override
  void dispose() {
    _sharesController.dispose();
    _priceController.dispose();
    _apiClient.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  Future<void> _fetchClosePrice() async {
    setState(() => _loadingPrice = true);
    try {
      final result = await _apiClient.getClosePrice(widget.ticker, _selectedDate);
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
          if (_priceController.text.isEmpty && widget.currentPrice != null) {
            _priceController.text = widget.currentPrice!.toStringAsFixed(2);
            _priceError = false;
          }
        });
      }
    }
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

  double? get _sellAmount {
    final shares = double.tryParse(_sharesController.text);
    final price = double.tryParse(_priceController.text);
    return (shares != null && price != null) ? shares * price : null;
  }

  double? get _realizedPnl {
    final shares = double.tryParse(_sharesController.text);
    final price = double.tryParse(_priceController.text);
    if (shares == null || price == null) return null;
    return (price - widget.avgPrice) * shares;
  }

  double? get _realizedPnlPct {
    final pnl = _realizedPnl;
    if (pnl == null || widget.avgPrice == 0) return null;
    return (pnl / (widget.avgPrice * (double.tryParse(_sharesController.text) ?? 0))) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final dateStr = _formatDate(_selectedDate);
    final isDifferentDate = _actualPriceDate != null && _actualPriceDate != dateStr;

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
              l10n.sellHoldingTitle(widget.ticker),
              style: const TextStyle(fontSize: AppTypography.headlineLarge, fontWeight: FontWeight.bold),
            ),
            Text(
              '${l10n.currentHoldings}: ${widget.currentShares.toStringAsFixed(widget.currentShares == widget.currentShares.truncateToDouble() ? 0 : 2)}${l10n.shares} (${l10n.avgPriceLabel} \$${widget.avgPrice.toStringAsFixed(2)})',
              style: TextStyle(fontSize: AppTypography.bodySmall, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Sell date
            Text(l10n.sellDate, style: const TextStyle(fontSize: AppTypography.bodyMedium, fontWeight: AppTypography.medium)),
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
                    Text(dateStr, style: const TextStyle(fontSize: AppTypography.headlineSmall)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Sell price
            Text(l10n.sellPrice, style: const TextStyle(fontSize: AppTypography.bodyMedium, fontWeight: AppTypography.medium)),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              decoration: InputDecoration(
                prefixText: '\$ ',
                suffixIcon: _loadingPrice
                    ? const Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
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
                  style: TextStyle(fontSize: AppTypography.caption, color: theme.colorScheme.primary),
                ),
              ),
            if (_priceError && _priceController.text.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  Localizations.localeOf(context).languageCode == 'ko'
                      ? '종가를 불러올 수 없습니다. 직접 입력해주세요.'
                      : 'Could not load close price. Please enter manually.',
                  style: TextStyle(fontSize: AppTypography.caption, color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),

            // Sell shares
            Text(l10n.sellShares, style: const TextStyle(fontSize: AppTypography.bodyMedium, fontWeight: AppTypography.medium)),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
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
                      if (n > widget.currentShares) return l10n.invalidShares;
                      return null;
                    },
                    autofocus: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                OutlinedButton(
                  onPressed: () {
                    _sharesController.text = widget.currentShares.toStringAsFixed(
                        widget.currentShares == widget.currentShares.truncateToDouble() ? 0 : 2);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
                  ),
                  child: Text(l10n.sellAll, style: const TextStyle(fontSize: AppTypography.bodySmall)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Summary: sell amount + realized P&L
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.sellAmount, style: TextStyle(fontSize: AppTypography.bodyMedium, color: theme.colorScheme.onSurfaceVariant)),
                      Text(
                        _sellAmount != null ? '\$${_sellAmount!.toStringAsFixed(2)}' : '—',
                        style: const TextStyle(fontSize: AppTypography.bodyLarge, fontWeight: AppTypography.semiBold),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.realizedPnlLabel, style: TextStyle(fontSize: AppTypography.bodyMedium, color: theme.colorScheme.onSurfaceVariant)),
                      if (_realizedPnl != null)
                        Text(
                          '${_realizedPnl! >= 0 ? '+' : ''}\$${_realizedPnl!.toStringAsFixed(2)} (${_realizedPnlPct != null ? '${_realizedPnlPct! >= 0 ? '+' : ''}${_realizedPnlPct!.toStringAsFixed(1)}%' : ''})',
                          style: TextStyle(
                            fontSize: AppTypography.bodyLarge,
                            fontWeight: FontWeight.bold,
                            color: _realizedPnl! >= 0 ? context.mlColors.gainColor : context.mlColors.lossColor,
                          ),
                        )
                      else
                        const Text('—', style: TextStyle(fontSize: AppTypography.bodyLarge, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  final shares = double.parse(_sharesController.text);
                  final price = double.parse(_priceController.text);
                  Navigator.pop(context, (shares: shares, price: price, date: _selectedDate));
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  backgroundColor: context.mlColors.dangerColor,
                ),
                child: Text(l10n.sellConfirm, style: TextStyle(fontSize: AppTypography.headlineSmall, color: context.mlColors.onPrimary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
