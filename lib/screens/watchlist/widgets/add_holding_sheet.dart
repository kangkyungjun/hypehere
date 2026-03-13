import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/analytics_api_client.dart';

/// Bottom sheet for adding a holding with date picker + auto close price.
///
/// Returns (shares, avgPrice, date) on confirm, null on cancel.
class AddHoldingSheet extends StatefulWidget {
  final String ticker;
  final String? name;

  const AddHoldingSheet({
    super.key,
    required this.ticker,
    this.name,
  });

  static Future<({double shares, double avgPrice, DateTime date})?> show(
    BuildContext context, {
    required String ticker,
    String? name,
  }) {
    return showModalBottomSheet<({double shares, double avgPrice, DateTime date})>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
      if (mounted) setState(() => _loadingPrice = false);
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
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final dateStr = _formatDate(_selectedDate);
    final isDifferentDate = _actualPriceDate != null && _actualPriceDate != dateStr;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Text(
              l10n.addHoldingTitle(widget.ticker),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (widget.name != null)
              Text(
                widget.name!,
                style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
              ),
            const SizedBox(height: 16),

            // Purchase date
            Text(l10n.purchaseDate, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(dateStr, style: const TextStyle(fontSize: 15)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Price input
            Text(l10n.avgPrice, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              decoration: InputDecoration(
                prefixText: '\$ ',
                suffixIcon: _loadingPrice
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return l10n.invalidPrice;
                return null;
              },
            ),
            if (isDifferentDate)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n.holidayPriceNotice(_actualPriceDate!),
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.primary),
                ),
              )
            else if (!_loadingPrice && _priceController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n.closingPriceAuto,
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            const SizedBox(height: 12),

            // Shares input
            Text(l10n.shares, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            TextFormField(
              controller: _sharesController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              decoration: InputDecoration(
                prefixText: '# ',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return l10n.invalidShares;
                return null;
              },
              autofocus: true,
            ),
            const SizedBox(height: 12),

            // Total cost
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.totalCost, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                  Text(
                    _totalCost != null ? '\$${_totalCost!.toStringAsFixed(2)}' : '—',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  final shares = double.parse(_sharesController.text);
                  final avgPrice = double.parse(_priceController.text);
                  Navigator.pop(context, (shares: shares, avgPrice: avgPrice, date: _selectedDate));
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(l10n.addToHoldings, style: const TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
