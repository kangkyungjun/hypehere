import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/analytics_api_client.dart';
import '../../exceptions/api_exception.dart';
import '../../models/chart_data.dart';
import '../../utils/score_mapper.dart';
import '../../models/ticker_info.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadow.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_stroke.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../theme/app_typography.dart';

/// 종목 비교 화면
///
/// ⚠️ Flutter는 비교 로직을 구현하지 않음
/// - 서버에서 받은 데이터를 나란히 표시만
/// - 우열 판단, 점수 비교 로직 없음
/// - 사용자가 직접 비교하여 판단
class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  final AnalyticsApiClient _apiClient = AnalyticsApiClient();
  final TextEditingController _searchController = TextEditingController();

  // 선택된 종목 리스트 (최대 3개)
  final List<String> _selectedTickers = [];

  // 종목별 차트 데이터 (ticker → CompleteChartData)
  final Map<String, CompleteChartData> _tickerDataMap = {};

  // 로딩 상태
  bool _isLoading = false;
  String? _errorMessage;

  // 검색 자동완성 상태
  Timer? _debounce;
  List<TickerInfo> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// 종목 추가
  Future<void> _addTicker(String ticker) async {
    final l10n = AppLocalizations.of(context);
    if (_selectedTickers.length >= 3) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errMaxCompare)));
      return;
    }

    if (_selectedTickers.contains(ticker.toUpperCase())) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errMaxCompare)));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 서버에서 종목 데이터 조회
      final chartData = await _apiClient.getChartData(ticker.toUpperCase());

      if (mounted) {
        setState(() {
          _selectedTickers.add(ticker.toUpperCase());
          _tickerDataMap[ticker.toUpperCase()] = chartData;
          _searchController.clear();
        });
      }
    } on TickerNotFoundException catch (_) {
      // 존재하지 않는 종목
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.noSearchResults),
            backgroundColor: context.mlColors.warningColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on TimeoutException {
      // 타임아웃
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.serverTimeout),
            backgroundColor: context.mlColors.dangerColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on SocketException {
      // 네트워크 에러
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.networkError),
            backgroundColor: context.mlColors.dangerColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {
      // 기타 에러
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.cannotLoadData),
            backgroundColor: context.mlColors.dangerColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      // 모든 경로에서 로딩 상태 해제
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
      }
    }
  }

  /// 종목 제거
  void _removeTicker(String ticker) {
    setState(() {
      _selectedTickers.remove(ticker);
      _tickerDataMap.remove(ticker);
    });
  }

  /// 종목 검색 (자동완성)
  void _performSearch(String query) {
    // 디바운스: 300ms 후 검색 실행
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // 2자 미만이면 검색 결과 초기화
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() {
        _isSearching = true;
      });

      try {
        final results = await _apiClient.searchTickers(query.trim());
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
        }
      }
    });
  }

  /// 검색 결과에서 종목 선택
  Future<void> _addTickerFromSearch(TickerInfo tickerInfo) async {
    // 검색 결과 초기화
    setState(() {
      _searchResults = [];
      _searchController.clear();
    });

    // 기존 _addTicker 로직 재사용
    await _addTicker(tickerInfo.ticker);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.compareTickers),
        backgroundColor: context.mlColors.accentBlue,
        foregroundColor: context.mlColors.onPrimary,
      ),
      body: Column(
        children: [
          // 종목 검색 및 추가 UI
          _buildSearchBar(),

          // 에러 메시지
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              color: context.mlColors.dangerBg,
              child: Text(
                _errorMessage!,
                style: TextStyle(color: context.mlColors.dangerColor),
              ),
            ),

          // 선택된 종목 칩
          if (_selectedTickers.isNotEmpty) _buildSelectedTickersChips(),

          // 비교 컨텐츠
          Expanded(
            child: _selectedTickers.isEmpty
                ? _buildEmptyState()
                : _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildComparisonContent(),
          ),
        ],
      ),
    );
  }

  /// 검색 바
  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          color: context.mlColors.sectionBackground,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.tickerSearchHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.lg,
                    ),
                    suffixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(AppSpacing.lg),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: AppStroke.medium,
                              ),
                            ),
                          )
                        : null,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (value) => _performSearch(value),
                  onSubmitted: (value) {
                    // 검색 결과가 있으면 첫 번째 결과 선택
                    if (_searchResults.isNotEmpty) {
                      _addTickerFromSearch(_searchResults.first);
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              ElevatedButton(
                onPressed: _isLoading
                    ? null // 로딩 중에는 버튼 비활성화
                    : () {
                        if (_searchController.text.isNotEmpty) {
                          _addTicker(_searchController.text);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.mlColors.accentBlue,
                  foregroundColor: context.mlColors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                    vertical: AppSpacing.lg,
                  ),
                ),
                child: Text(l10n.add),
              ),
            ],
          ),
        ),

        // 자동완성 드롭다운
        if (_searchResults.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: context.mlColors.cardBackground,
              border: Border(
                left: BorderSide(
                  color: context.mlColors.subtleBorder.withValues(alpha: 0.7),
                ),
                right: BorderSide(
                  color: context.mlColors.subtleBorder.withValues(alpha: 0.7),
                ),
                bottom: BorderSide(
                  color: context.mlColors.subtleBorder.withValues(alpha: 0.7),
                ),
              ),
              boxShadow: AppShadow.sm(context.mlColors.overlayDim),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final ticker = _searchResults[index];
                return ListTile(
                  title: Text(
                    ticker.searchDisplayText,
                    style: TextStyle(fontSize: AppTypography.bodyLarge),
                  ),
                  onTap: () => _addTickerFromSearch(ticker),
                  dense: true,
                );
              },
            ),
          ),
      ],
    );
  }

  /// 선택된 종목 칩
  Widget _buildSelectedTickersChips() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Wrap(
        spacing: 8,
        children: _selectedTickers.map((ticker) {
          return Chip(
            label: Text(ticker),
            deleteIcon: const Icon(Icons.close, size: 18),
            onDeleted: () => _removeTicker(ticker),
            backgroundColor: context.mlColors.accentBlue.withValues(alpha: 0.2),
          );
        }).toList(),
      ),
    );
  }

  /// 빈 상태
  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    return EmptyStateView(
      icon: Icons.compare_arrows,
      iconSize: 64,
      message: l10n.compareTickers,
      subtitle: l10n.errMaxCompare,
    );
  }

  /// 비교 컨텐츠
  Widget _buildComparisonContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),

          // 주요 지표 비교 테이블
          _buildComparisonTable(),

          const SizedBox(height: AppSpacing.xxl),

          // 가격 차트 비교
          _buildPriceChartsComparison(),

          const SizedBox(height: AppSpacing.xxl),

          // RSI 비교
          _buildRsiComparison(),

          const SizedBox(height: AppSpacing.xxl),

          // 배너 광고
          const BannerAdWidget(),

          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  /// 주요 지표 비교 테이블
  Widget _buildComparisonTable() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.mlColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: context.mlColors.subtleBorder.withValues(alpha: 0.62),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              AppLocalizations.of(context).keyMetricsComparison,
              style: TextStyle(
                fontSize: AppTypography.headlineMedium,
                fontWeight: AppTypography.bold,
              ),
            ),
          ),

          // 테이블
          Table(
            border: TableBorder.all(
              color: context.mlColors.subtleBorder.withValues(alpha: 0.58),
              width: 0.6,
            ),
            columnWidths: const {
              0: FlexColumnWidth(1.5),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
            },
            children: [
              // 헤더
              TableRow(
                decoration: BoxDecoration(
                  color: context.mlColors.infoBg.withValues(alpha: 0.42),
                ),
                children: [
                  _buildTableCell(
                    AppLocalizations.of(context).metric,
                    isHeader: true,
                  ),
                  ..._selectedTickers.map(
                    (ticker) => _buildTableCell(ticker, isHeader: true),
                  ),
                ],
              ),

              // AI Score (서버 계산 값)
              _buildMetricRow(
                'AI Score',
                _selectedTickers
                    .map((t) => _tickerDataMap[t]?.lastOrNull?.score)
                    .toList(),
              ),

              // Signal (score-based localized label)
              _buildMetricRow(
                'Signal',
                _selectedTickers.map((t) {
                  final d = _tickerDataMap[t]?.lastOrNull;
                  if (d?.signal == null || d?.score == null) return null;
                  return ScoreMapper.getScoreLabelLocalized(
                    d!.score!,
                    AppLocalizations.of(context),
                  );
                }).toList(),
                isString: true,
              ),

              // 현재가 (서버 제공 값)
              _buildMetricRow(
                'Price',
                _selectedTickers
                    .map((t) => _tickerDataMap[t]?.lastOrNull?.close)
                    .toList(),
              ),

              // RSI (서버 계산 값)
              _buildMetricRow(
                'RSI',
                _selectedTickers
                    .map((t) => _tickerDataMap[t]?.lastOrNull?.rsi)
                    .toList(),
              ),

              // MACD (서버 계산 값)
              _buildMetricRow(
                'MACD',
                _selectedTickers
                    .map((t) => _tickerDataMap[t]?.lastOrNull?.macd)
                    .toList(),
              ),

              // 목표가 (서버 계산 값)
              _buildMetricRow(
                'Target Price',
                _selectedTickers
                    .map((t) => _tickerDataMap[t]?.lastOrNull?.targetPrice)
                    .toList(),
              ),
            ],
          ),

          // 안내 문구
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              AppLocalizations.of(context).serverCalculatedNote,
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: context.mlColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 테이블 행 생성 (지표별)
  TableRow _buildMetricRow(
    String label,
    List<Object?> values, {
    bool isString = false,
  }) {
    return TableRow(
      children: [
        _buildTableCell(label),
        ...values.map((value) {
          if (value == null) {
            return _buildTableCell('N/A');
          }
          if (isString) {
            return _buildTableCell(value.toString());
          }
          return _buildTableCell((value as double).toStringAsFixed(2));
        }),
      ],
    );
  }

  /// 테이블 셀
  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isHeader
              ? AppTypography.bodySmall
              : AppTypography.bodyMedium,
          fontWeight: isHeader ? AppTypography.bold : AppTypography.regular,
          color: isHeader
              ? context.mlColors.textSecondary
              : context.mlColors.textPrimary,
          fontFeatures: isHeader ? null : AppTypography.tabularFigures,
        ),
        textAlign: isHeader ? TextAlign.center : TextAlign.left,
      ),
    );
  }

  /// 가격 차트 비교 (미니 차트)
  Widget _buildPriceChartsComparison() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.mlColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: context.mlColors.subtleBorder.withValues(alpha: 0.62),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).priceTrendComparison,
            style: TextStyle(
              fontSize: AppTypography.headlineMedium,
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          ..._selectedTickers.asMap().entries.map((entry) {
            final index = entry.key;
            final ticker = entry.value;
            final isLastChart = index == _selectedTickers.length - 1;

            final data = _tickerDataMap[ticker]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: _buildMiniPriceChart(
                ticker,
                data,
                showBottomTitles: isLastChart,
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 미니 가격 차트
  Widget _buildMiniPriceChart(
    String ticker,
    CompleteChartData data, {
    bool showBottomTitles = false,
  }) {
    final priceData = data.data
        .asMap()
        .entries
        .where((e) => e.value.close != null)
        .toList();

    if (priceData.isEmpty) return const SizedBox.shrink();

    final prices = priceData.map((e) => e.value.close!).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ticker,
          style: const TextStyle(
            fontSize: AppTypography.bodyLarge,
            fontWeight: AppTypography.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: showBottomTitles ? 120 : 80,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: showBottomTitles
                    ? AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: ((data.data.length / 0.6) / 4)
                              .ceilToDouble(),
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();

                            // 과거 데이터 영역
                            if (index >= 0 && index < data.data.length) {
                              final date = data.data[index].date;
                              return Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.md,
                                ),
                                child: Text(
                                  '${date.month}/${date.day}',
                                  style: TextStyle(
                                    fontSize: AppTypography.micro,
                                  ),
                                ),
                              );
                            }

                            // 미래 영역 (60:40 비율)
                            if (index >= data.data.length &&
                                data.data.isNotEmpty) {
                              final lastDate = data.data.last.date;
                              final daysSinceLastDate =
                                  index - (data.data.length - 1);
                              final futureDate = lastDate.add(
                                Duration(days: daysSinceLastDate),
                              );

                              return Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.md,
                                ),
                                child: Text(
                                  '${futureDate.month}/${futureDate.day}',
                                  style: TextStyle(
                                    fontSize: AppTypography.micro,
                                    color: context.mlColors.textTertiary,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      )
                    : const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
              ),
              borderData: FlBorderData(show: false),
              minY: minPrice * 0.95,
              maxY: maxPrice * 1.05,
              lineBarsData: [
                LineChartBarData(
                  spots: priceData
                      .map((e) => FlSpot(e.key.toDouble(), e.value.close!))
                      .toList(),
                  isCurved: true,
                  color: context.mlColors.accentBlue,
                  barWidth: 1.5,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// RSI 비교
  Widget _buildRsiComparison() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.mlColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: context.mlColors.subtleBorder.withValues(alpha: 0.62),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).rsiComparison,
            style: TextStyle(
              fontSize: AppTypography.headlineMedium,
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          ..._selectedTickers.map((ticker) {
            final latestRsi = _tickerDataMap[ticker]?.lastOrNull?.rsi;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      ticker,
                      style: const TextStyle(
                        fontSize: AppTypography.bodyLarge,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                  ),
                  Expanded(child: _buildRsiBar(latestRsi)),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 50,
                    child: Text(
                      latestRsi?.toStringAsFixed(1) ?? 'N/A',
                      style: TextStyle(fontSize: AppTypography.bodyLarge),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: AppSpacing.md),
          Text(
            AppLocalizations.of(context).rsiInterpretation,
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: context.mlColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// RSI 바 (시각화)
  Widget _buildRsiBar(double? rsi) {
    if (rsi == null) {
      return Container(
        height: 20,
        decoration: BoxDecoration(
          color: context.mlColors.subtleBorder,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
      );
    }

    Color barColor;
    if (rsi > 70) {
      barColor = context.mlColors.gainColor; // 과매수
    } else if (rsi < 30) {
      barColor = context.mlColors.lossColor; // 과매도
    } else {
      barColor = Theme.of(context).colorScheme.tertiary; // 중립
    }

    return Stack(
      children: [
        // 배경
        Container(
          height: 20,
          decoration: BoxDecoration(
            color: context.mlColors.subtleBorder,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
        ),
        // RSI 바
        FractionallySizedBox(
          widthFactor: rsi / 100,
          child: Container(
            height: 20,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
          ),
        ),
      ],
    );
  }
}
