import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/analytics_api_client.dart';
import '../../models/chart_data.dart';
import '../../models/ticker_info.dart';
import '../../providers/watchlist_provider.dart';
import '../../widgets/charts/rsi_chart_widget.dart';
import '../../widgets/charts/macd_chart_widget.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../utils/score_mapper.dart';
import '../../services/community_api_client.dart';
import '../../models/community/post.dart';
import '../../widgets/community/post_card.dart';
import '../community/community_feed_screen.dart';
import '../community/post_detail_screen.dart';

/// Ticker Detail Screen - MarketLens 핵심 화면
///
/// ⚠️ HypeHere와 완전히 다른 UX:
/// - 순수 데이터 분석 도구
/// - 소셜 기능 없음 (좋아요/댓글/공유)
/// - 차트 중심 구조
class TickerDetailScreen extends StatefulWidget {
  final String ticker;

  const TickerDetailScreen({
    super.key,
    required this.ticker,
  });

  @override
  State<TickerDetailScreen> createState() => _TickerDetailScreenState();
}

class _TickerDetailScreenState extends State<TickerDetailScreen> {
  final AnalyticsApiClient _apiClient = AnalyticsApiClient();

  CompleteChartData? _chartData;
  TickerInfo? _tickerInfo;
  bool _isLoading = true;
  String? _error;

  // 범례 표시 여부
  bool _showLegend = false;

  // 기간 선택
  String _selectedPeriod = '3M';
  final Map<String, int> _periodDays = {
    '1M': 30,
    '3M': 90,
    '6M': 180,
    '1Y': 365,
  };

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _loadChartData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final days = _periodDays[_selectedPeriod] ?? 90;
      final toDate = DateTime.now();
      final fromDate = toDate.subtract(Duration(days: days));

      // Load chart data and ticker info in parallel
      final results = await Future.wait([
        _apiClient.getChartData(
          widget.ticker,
          fromDate: fromDate,
          toDate: toDate,
        ),
        _apiClient.getTickerInfo(widget.ticker),
      ]);

      setState(() {
        _chartData = results[0] as CompleteChartData;
        _tickerInfo = results[1] as TickerInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        // ApiException의 경우 message만 추출, 그 외는 toString()
        if (e is ApiException) {
          _error = e.message;
        } else {
          _error = e.toString();
        }
        _isLoading = false;
      });
    }
  }

  void _onPeriodChanged(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadChartData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ticker),
        actions: [
          // 관심종목 추가/삭제 버튼
          Consumer<WatchlistProvider>(
            builder: (context, watchlistProvider, child) {
              final isInWatchlist =
                  watchlistProvider.isInWatchlist(widget.ticker);
              return IconButton(
                icon: Icon(
                  isInWatchlist ? Icons.bookmark : Icons.bookmark_outline,
                ),
                tooltip:
                    isInWatchlist ? 'Remove from watchlist' : 'Add to watchlist',
                onPressed: () {
                  watchlistProvider.toggleWatchlist(widget.ticker);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isInWatchlist
                            ? 'Removed from watchlist'
                            : 'Added to watchlist',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // 로딩 상태
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // 에러 상태
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadChartData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // 데이터 없음
    if (_chartData == null || _chartData!.data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.data_usage_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No data available',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Try a different ticker or period',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // 데이터 표시
    return RefreshIndicator(
      onRefresh: _loadChartData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 섹션
            _buildHeader(),

            const SizedBox(height: 16),

            // 기간 선택 버튼
            _buildPeriodSelector(),

            const SizedBox(height: 16),

            // Ad: Between period filter and chart (mobile only)
            if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
              const BannerAdWidget(),
            if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
              const SizedBox(height: 16),

            // Price 차트
            _buildPriceChart(),

            const SizedBox(height: 16),

            // AI Insight 섹션 (가격 차트 직후 배치로 즉시 판단 근거 제공)
            _buildInsightSection(),

            const SizedBox(height: 16),

            // Score 차트 (독립 좌표계)
            _buildScoreChart(),

            const SizedBox(height: 16),

            // RSI 차트 (서버 계산 값 시각화)
            RsiChartWidget(dataPoints: _chartData!.data),

            const SizedBox(height: 16),

            // MACD 차트 (서버 계산 값 시각화) - 임시 숨김
            // MacdChartWidget(dataPoints: _chartData!.data),

            const SizedBox(height: 32),

            // 💬 실시간 토크 섹션 (커뮤니티 통합)
            _buildCommunitySection(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// 헤더 섹션: Ticker/Score/Signal
  Widget _buildHeader() {
    final latestData = _chartData!.data.last;
    final score = latestData.score ?? 0;

    // 반응형: 작은 화면에서는 폰트 크기 축소
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final titleFontSize = isSmallScreen ? 24.0 : 32.0;
    final scoreFontSize = isSmallScreen ? 24.0 : 32.0;

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 메인 Row: 종목명 + 점수 + 시그널 (한 줄)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 좌측: Ticker 심볼
              Flexible(
                child: Text(
                  widget.ticker,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 16),

              // 우측: Score + Signal
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // AI 점수 (색상 적용)
                  Text(
                    latestData.score?.toStringAsFixed(1) ?? '--',
                    style: TextStyle(
                      fontSize: scoreFontSize,
                      fontWeight: FontWeight.bold,
                      color: ScoreMapper.getScoreColor(score),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Signal Pill (한글 라벨 사용)
                  if (latestData.score != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ScoreMapper.getScoreColor(score),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        ScoreMapper.getScoreLabel(score),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Ticker 회사명 (Option 2: 헤더 내부, ticker/score/signal 아래)
          if (_tickerInfo?.name != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tickerInfo!.nameKo != null
                      ? '${_tickerInfo!.name} / ${_tickerInfo!.nameKo}'
                      : _tickerInfo!.name!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),

          // 최신 업데이트 날짜
          Text(
            'Updated: ${latestData.date.toString().split(' ')[0]}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 기간 선택 버튼
  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: _periodDays.keys.map((period) {
          final isSelected = period == _selectedPeriod;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(period),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _onPeriodChanged(period);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Price 차트 (독립 좌표계 - Auto-scale)
  Widget _buildPriceChart() {
    final dataPoints = _chartData!.data;
    final latestData = dataPoints.last;

    // 가격 범위 계산
    final prices = dataPoints
        .where((d) => d.close != null)
        .map((d) => d.close!)
        .toList()
        .cast<double>();
    double minPrice = 0;
    double maxPrice = 100;
    if (prices.isNotEmpty) {
      minPrice = prices.fold<double>(prices.first, (prev, curr) => prev < curr ? prev : curr);
      maxPrice = prices.fold<double>(prices.first, (prev, curr) => prev > curr ? prev : curr);
    }
    final priceRange = maxPrice - minPrice;
    final priceMargin = priceRange * 0.1;

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              // 범례 토글 버튼
              InkWell(
                onTap: () => setState(() => _showLegend = !_showLegend),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '범례',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 차트
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Stack(
              children: [
                // Price Chart
                LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: priceRange / 5,
                  verticalInterval: ((dataPoints.length / 0.6) / 5).ceilToDouble(),  // 60:40 비율에 맞춰 grid 간격 조정
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),

                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.black87,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        // barIndex: 0=BB Upper, 1=BB Middle, 2=BB Lower, 3=Price, 4/5=Trendlines
                        switch (spot.barIndex) {
                          case 0: // BB Upper
                            return LineTooltipItem(
                              'Upper\n\$${spot.y.toStringAsFixed(2)}',
                              TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.normal,
                              ),
                            );

                          case 1: // BB Middle
                            return LineTooltipItem(
                              'MA\n\$${spot.y.toStringAsFixed(2)}',
                              TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.normal,
                              ),
                            );

                          case 2: // BB Lower
                            return LineTooltipItem(
                              'Lower\n\$${spot.y.toStringAsFixed(2)}',
                              TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.normal,
                              ),
                            );

                          case 3: // Price (종가) - 기존 방식 유지
                            final date = dataPoints[spot.x.toInt()].date;
                            final dateStr = '${date.month}/${date.day}';
                            return LineTooltipItem(
                              '$dateStr\n\$${spot.y.toStringAsFixed(2)}',
                              const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );

                          default: // Trendlines - 툴팁 표시 안함
                            return null;
                        }
                      }).whereType<LineTooltipItem>().toList();
                    },
                  ),
                ),

                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${value.toInt()}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: ((dataPoints.length / 0.6) / 4).ceilToDouble(),  // 60:40 비율에 맞춰 간격 조정
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        // 과거 데이터 영역 (왼쪽 60%)
                        if (index >= 0 && index < dataPoints.length) {
                          final date = dataPoints[index].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              '${date.month}/${date.day}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }

                        // 미래 영역 (오른쪽 40%)
                        if (index >= dataPoints.length) {
                          final lastDate = dataPoints.last.date;
                          final daysSinceLastDate = index - (dataPoints.length - 1);
                          final futureDate = lastDate.add(Duration(days: daysSinceLastDate));

                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              '${futureDate.month}/${futureDate.day}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,  // 미래 날짜는 회색으로 구분
                              ),
                            ),
                          );
                        }

                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),

                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300),
                ),

                minY: minPrice - priceMargin,
                maxY: maxPrice + priceMargin,
                minX: 0,
                maxX: ((dataPoints.length - 1) / 0.6),  // 40% 미래 영역 확보 (60:40 비율)

                lineBarsData: [
                  // Bollinger Band Upper
                  if (dataPoints.any((d) => d.bbUpper != null))
                    LineChartBarData(
                      spots: dataPoints
                          .asMap()
                          .entries
                          .where((e) => e.value.bbUpper != null)
                          .map((e) => FlSpot(e.key.toDouble(), e.value.bbUpper!))
                          .toList(),
                      color: Colors.grey.withValues(alpha: 0.25),
                      barWidth: 1,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withValues(alpha: 0.1),
                      ),
                    ),

                  // Bollinger Band Middle
                  if (dataPoints.any((d) => d.bbMiddle != null))
                    LineChartBarData(
                      spots: dataPoints
                          .asMap()
                          .entries
                          .where((e) => e.value.bbMiddle != null)
                          .map((e) => FlSpot(e.key.toDouble(), e.value.bbMiddle!))
                          .toList(),
                      color: Colors.grey.withValues(alpha: 0.5),
                      barWidth: 1,
                      dashArray: [3, 3],
                      dotData: const FlDotData(show: false),
                    ),

                  // Bollinger Band Lower
                  if (dataPoints.any((d) => d.bbLower != null))
                    LineChartBarData(
                      spots: dataPoints
                          .asMap()
                          .entries
                          .where((e) => e.value.bbLower != null)
                          .map((e) => FlSpot(e.key.toDouble(), e.value.bbLower!))
                          .toList(),
                      color: Colors.grey.withValues(alpha: 0.25),
                      barWidth: 1,
                      dotData: const FlDotData(show: false),
                    ),

                  // Price Line
                  LineChartBarData(
                    spots: dataPoints
                        .asMap()
                        .entries
                        .where((e) => e.value.close != null)
                        .map((e) => FlSpot(e.key.toDouble(), e.value.close!))
                        .toList(),
                    isCurved: true,
                    color: Theme.of(context).colorScheme.onSurface,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                  ),

                  // 저항선 (High Trendline - 40% 미래 영역까지 동적 연장)
                  if (_chartData!.highSlope != null &&
                      _chartData!.highIntercept != null)
                    LineChartBarData(
                      spots: List.generate(
                        dataPoints.length + (dataPoints.length * 0.667).ceil(),  // 60:40 비율에 맞춰 동적 계산
                        (index) {
                          final y = _chartData!.calculateHighTrendline(index);
                          return FlSpot(index.toDouble(), y!);
                        },
                      ),
                      isCurved: false,
                      color: Colors.red.withValues(alpha: 0.6),
                      barWidth: 1.5,
                      dashArray: [5, 5],
                      dotData: const FlDotData(show: false),
                    ),

                  // 지지선 (Low Trendline - 40% 미래 영역까지 동적 연장)
                  if (_chartData!.lowSlope != null &&
                      _chartData!.lowIntercept != null)
                    LineChartBarData(
                      spots: List.generate(
                        dataPoints.length + (dataPoints.length * 0.667).ceil(),  // 60:40 비율에 맞춰 동적 계산
                        (index) {
                          final y = _chartData!.calculateLowTrendline(index);
                          return FlSpot(index.toDouble(), y!);
                        },
                      ),
                      isCurved: false,
                      color: Colors.green.withValues(alpha: 0.6),
                      barWidth: 1.5,
                      dashArray: [5, 5],
                      dotData: const FlDotData(show: false),
                    ),
                ],

                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    if (latestData.targetPrice != null)
                      HorizontalLine(
                        y: latestData.targetPrice!,
                        color: Colors.green,
                        strokeWidth: 2,
                        label: HorizontalLineLabel(
                          show: true,
                          labelResolver: (line) =>
                              'Target \$${line.y.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (latestData.stopLoss != null)
                      HorizontalLine(
                        y: latestData.stopLoss!,
                        color: Colors.red,
                        strokeWidth: 2,
                        label: HorizontalLineLabel(
                          show: true,
                          labelResolver: (line) =>
                              'Stop \$${line.y.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Legend (범례) - 토글 버튼으로 표시/숨김
            if (_showLegend)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 150),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildChartLegendItem('Price', Colors.black),
                      const SizedBox(height: 4),
                      _buildChartLegendItem('BB Upper', Colors.grey),
                      _buildChartLegendItem('BB MA', Colors.grey, dashed: true),
                      _buildChartLegendItem('BB Lower', Colors.grey),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
    ),
    );
  }

  /// 차트 범례 아이템 (Legend)
  Widget _buildChartLegendItem(String label, Color color, {bool dashed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 2,
            decoration: BoxDecoration(
              color: dashed ? null : color,
              border: dashed ? Border(
                top: BorderSide(color: color, width: 1),
              ) : null,
            ),
            child: dashed ? CustomPaint(
              painter: _DashedLinePainter(color),
            ) : null,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Score 차트 (독립 좌표계 - Fixed 0-100)
  Widget _buildScoreChart() {
    final dataPoints = _chartData!.data;

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI Score',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              _buildLegendItem('Score (0-100)', Colors.orange),
            ],
          ),
          const SizedBox(height: 16),

          // 차트
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16.0),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 20, // 0, 20, 40, 60, 80, 100
                  verticalInterval: ((dataPoints.length / 0.6) / 5).ceilToDouble(),  // 60:40 비율에 맞춰 grid 간격 조정
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),

                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.black87,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final date = dataPoints[spot.x.toInt()].date;
                        final dateStr = '${date.month}/${date.day}';
                        return LineTooltipItem(
                          '$dateStr\nScore: ${spot.y.toStringAsFixed(1)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),

                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 20,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.orange,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: ((dataPoints.length / 0.6) / 4).ceilToDouble(),  // 60:40 비율에 맞춰 간격 조정
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        // 과거 데이터 영역 (왼쪽 60%)
                        if (index >= 0 && index < dataPoints.length) {
                          final date = dataPoints[index].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              '${date.month}/${date.day}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }

                        // 미래 영역 (오른쪽 40%)
                        if (index >= dataPoints.length) {
                          final lastDate = dataPoints.last.date;
                          final daysSinceLastDate = index - (dataPoints.length - 1);
                          final futureDate = lastDate.add(Duration(days: daysSinceLastDate));

                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              '${futureDate.month}/${futureDate.day}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,  // 미래 날짜는 회색으로 구분
                              ),
                            ),
                          );
                        }

                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),

                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300),
                ),

                // ✅ 핵심: Score는 항상 0-100 고정
                minY: 0,
                maxY: 100,
                minX: 0,
                maxX: ((dataPoints.length - 1) / 0.6),  // 40% 미래 영역 확보 (60:40 비율)

                lineBarsData: [
                  // Score Line (0-100 범위 유지)
                  LineChartBarData(
                    spots: dataPoints
                        .asMap()
                        .entries
                        .where((e) => e.value.score != null)
                        .map((e) => FlSpot(e.key.toDouble(), e.value.score!))
                        .toList(),
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.orange.withValues(alpha: 0.1),
                    ),
                  ),
                ],

                // 수평 참조선 (Strong Buy/Sell 임계값)
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    // Strong Buy 라인 (70)
                    HorizontalLine(
                      y: 70,
                      color: Colors.green.withValues(alpha: 0.5),
                      strokeWidth: 1,
                      dashArray: [3, 3],
                      label: HorizontalLineLabel(
                        show: true,
                        labelResolver: (line) => 'Strong Buy (70)',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 9,
                        ),
                        alignment: Alignment.topRight,
                      ),
                    ),
                    // Strong Sell 라인 (30)
                    HorizontalLine(
                      y: 30,
                      color: Colors.red.withValues(alpha: 0.5),
                      strokeWidth: 1,
                      dashArray: [3, 3],
                      label: HorizontalLineLabel(
                        show: true,
                        labelResolver: (line) => 'Strong Sell (30)',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 9,
                        ),
                        alignment: Alignment.bottomRight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 범례 아이템
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 2,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Insight 섹션 (AI 분석 데이터 기반)
  Widget _buildInsightSection() {
    // 최신 AI 분석 데이터 찾기 (null이 아닌 마지막 데이터)
    final latestData = _chartData!.data.lastWhere(
      (d) => d.aiSummary != null,
      orElse: () => _chartData!.data.last,
    );

    // AI 데이터가 없으면 fallback 표시
    if (latestData.aiSummary == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Insight',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _generateInsightText(latestData),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      );
    }

    // AI 상승 확률 계산
    final probability = latestData.aiProbability ?? 0.5;
    final isUptrend = probability >= 0.5;
    final confidencePercent = (probability * 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI Insight',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isUptrend ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isUptrend ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isUptrend ? Icons.trending_up : Icons.trending_down,
                      size: 16,
                      color: isUptrend ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$confidencePercent%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isUptrend ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // AI Summary (한글 요약)
          Text(
            latestData.aiSummary!,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Bullish Reasons (강세 요인)
          if (latestData.aiBullishReasons != null && latestData.aiBullishReasons!.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.thumb_up_outlined, size: 16, color: Colors.green.shade700),
                const SizedBox(width: 6),
                Text(
                  'Bullish Factors',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...latestData.aiBullishReasons!.map((reason) => Padding(
                  padding: const EdgeInsets.only(left: 22, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: Colors.green.shade700)),
                      Expanded(
                        child: Text(
                          reason,
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
          ],

          // Bearish Reasons (약세 요인)
          if (latestData.aiBearishReasons != null && latestData.aiBearishReasons!.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.thumb_down_outlined, size: 16, color: Colors.red.shade700),
                const SizedBox(width: 6),
                Text(
                  'Bearish Factors',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...latestData.aiBearishReasons!.map((reason) => Padding(
                  padding: const EdgeInsets.only(left: 22, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: Colors.red.shade700)),
                      Expanded(
                        child: Text(
                          reason,
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
          ],

          // Final Comment (최종 의견)
          if (latestData.aiFinalComment != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 18, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      latestData.aiFinalComment!,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 💬 실시간 토크 섹션 (커뮤니티 통합)
  ///
  /// 현재 종목의 최신 게시글 3개를 미리보기로 표시
  /// [전체보기] 버튼 클릭 시 종목 전용 게시판으로 이동 (필터 ON)
  Widget _buildCommunitySection() {
    final communityApiClient = CommunityApiClient();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 (타이틀 + 전체보기 버튼)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '💬 실시간 토크',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _navigateToCommunity,
                child: const Row(
                  children: [
                    Text(
                      '전체보기',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 게시글 미리보기 (최신 3개)
          FutureBuilder<List<Post>>(
            future: communityApiClient.getPosts(ticker: widget.ticker),
            builder: (context, snapshot) {
              // 로딩 중
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // 에러 발생
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      '게시글을 불러올 수 없습니다',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                );
              }

              // 데이터 없음
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '아직 게시글이 없습니다',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '첫 번째 게시글을 작성해보세요!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // 최신 3개만 표시
              final posts = snapshot.data!.take(3).toList();

              return Column(
                children: posts.map((post) {
                  return PostCard(
                    post: post,
                    onTap: () => _navigateToPostDetail(post.id),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 종목 전용 게시판으로 이동
  void _navigateToCommunity() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityFeedScreen(
          initialTicker: widget.ticker, // 🎯 현재 종목 자동 필터
        ),
      ),
    );
  }

  /// 게시글 상세로 이동
  void _navigateToPostDetail(int postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(postId: postId),
      ),
    );
  }

  /// 수급 변화 배지
  Widget _buildChangeBadge(String label, double change) {
    final isPositive = change > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPositive ? Colors.green : Colors.red,
        ),
      ),
      child: Text(
        '$label: ${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%',
        style: TextStyle(
          color: isPositive ? Colors.green.shade900 : Colors.red.shade900,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 인사이트 텍스트 생성
  String _generateInsightText(ChartDataPoint data) {
    final score = data.score ?? 0;
    final signal = data.signal ?? 'NEUTRAL';

    if (signal == 'BUY' && score >= 70) {
      return 'Strong buy signal detected. AI score indicates positive momentum with favorable technical indicators.';
    } else if (signal == 'BUY') {
      return 'Moderate buy signal. Consider monitoring price action and volume for confirmation.';
    } else if (signal == 'SELL' && score <= 30) {
      return 'Strong sell signal detected. AI score indicates negative momentum with concerning technical indicators.';
    } else if (signal == 'SELL') {
      return 'Moderate sell signal. Risk management recommended.';
    } else {
      return 'Neutral signal. Market conditions suggest waiting for clearer direction.';
    }
  }
}

/// 점선 Painter (Legend용)
class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const dashWidth = 2.0;
    const dashSpace = 2.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
