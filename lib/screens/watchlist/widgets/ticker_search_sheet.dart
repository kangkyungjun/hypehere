import 'dart:async';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/ticker_info.dart';
import '../../../services/analytics_api_client.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

/// Bottom sheet with ticker search for direct holding addition.
///
/// Returns the selected [TickerInfo] or null if dismissed.
class TickerSearchSheet extends StatefulWidget {
  const TickerSearchSheet({super.key});

  static Future<TickerInfo?> show(BuildContext context) {
    return showModalBottomSheet<TickerInfo>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (_) => const TickerSearchSheet(),
    );
  }

  @override
  State<TickerSearchSheet> createState() => _TickerSearchSheetState();
}

class _TickerSearchSheetState extends State<TickerSearchSheet> {
  final _controller = TextEditingController();
  final _apiClient = AnalyticsApiClient();
  Timer? _debounce;

  List<TickerInfo> _results = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    _apiClient.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _search(query.trim());
    });
  }

  Future<void> _search(String query) async {
    setState(() => _isSearching = true);
    try {
      final results = await _apiClient.searchTickers(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isKo = Localizations.localeOf(context).languageCode == 'ko';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppRadius.xxs),
                  ),
                ),
              ),

              // Search field
              TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: l10n.searchTickerHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _controller.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Results
              Expanded(
                child: _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : _results.isEmpty
                        ? Center(
                            child: _controller.text.isEmpty
                                ? Text(
                                    l10n.searchTickerHint,
                                    style: TextStyle(
                                      fontSize: AppTypography.bodyMedium,
                                      color: theme.colorScheme.outline,
                                    ),
                                  )
                                : Text(
                                    l10n.noData,
                                    style: TextStyle(
                                      fontSize: AppTypography.bodyMedium,
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final ticker = _results[index];
                              final displayName = isKo && ticker.nameKo != null
                                  ? ticker.nameKo!
                                  : ticker.name ?? ticker.ticker;
                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: theme.colorScheme.primaryContainer,
                                  child: Text(
                                    ticker.ticker.substring(0, ticker.ticker.length > 2 ? 2 : ticker.ticker.length),
                                    style: TextStyle(
                                      fontSize: AppTypography.bodySmall,
                                      fontWeight: AppTypography.bold,
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  ticker.ticker,
                                  style: const TextStyle(
                                    fontWeight: AppTypography.semiBold,
                                    fontSize: AppTypography.bodyLarge,
                                  ),
                                ),
                                subtitle: Text(
                                  displayName,
                                  style: TextStyle(
                                    fontSize: AppTypography.bodySmall,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => Navigator.pop(context, ticker),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
