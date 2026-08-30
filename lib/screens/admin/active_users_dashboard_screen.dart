import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/admin_dashboard.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/bento_card.dart';
import '../../widgets/common/ml_key_value_row.dart';

/// 활성 사용자 대시보드 — **Master 전용**.
///
/// 메뉴는 설정에서 isMaster일 때만 노출(숨김)되고, 이 화면도 진입 시 재확인하며,
/// 서버 /admin/dashboard/* 가 Master 외 403으로 최종 게이트한다(삼중 방어).
class ActiveUsersDashboardScreen extends StatefulWidget {
  const ActiveUsersDashboardScreen({super.key});

  @override
  State<ActiveUsersDashboardScreen> createState() =>
      _ActiveUsersDashboardScreenState();
}

class _ActiveUsersDashboardScreenState
    extends State<ActiveUsersDashboardScreen> {
  final AdminApiClient _api = AdminApiClient();

  bool _loading = true;
  String? _error;
  AdminSummary? _summary;
  List<AdminUserPoint> _series = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await _api.getSummary();
      final series = await _api.getUsersSeries(range: '30d');
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _series = series;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 방어: Master 아니면 내용 자체를 렌더하지 않음(메뉴 숨김의 2차 방어).
    final isMaster = context.watch<AuthProvider>().isMaster;
    if (!isMaster) {
      return Scaffold(
        appBar: AppBar(title: const Text('활성 사용자')),
        body: const Center(child: Text('접근 권한이 없습니다.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('활성 사용자'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: '용어 설명',
            onPressed: () => _showGlossary(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Text(
                      '불러오지 못했습니다\n$_error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              )
            : _buildBody(context),
      ),
    );
  }

  void _showGlossary(BuildContext context) {
    final mlc = context.mlColors;
    Widget item(String t, String d) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t,
            style: AppTypography.bodyStrong.copyWith(color: mlc.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            d,
            style: AppTypography.body.copyWith(
              color: mlc.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('용어 설명'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              item('일간 활성 (DAU)', '오늘 앱을 연 로그인 사용자 수. 누적 가입자(total)와 다른 지표.'),
              item('주간 활성 (WAU)', '최근 7일 내 접속한 사용자 수.'),
              item('월간 활성 (MAU)', '최근 30일 내 접속한 사용자 수.'),
              item('고착도 (Stickiness)', 'DAU ÷ WAU. 높을수록 자주 재방문(점성↑).'),
              item('eCPM', '광고 1,000회 노출당 수익(USD).'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final u = _summary?.users;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        if (_summary != null)
          Text(
            '기준일 ${_summary!.asOf}',
            style: AppTypography.label.copyWith(
              color: context.mlColors.textTertiary,
            ),
          ),
        const SizedBox(height: AppSpacing.sm),

        // 핵심 카드 3개
        Row(
          children: [
            _metricCard('일간 활성', '${u?.dau ?? 0}', context, sub: 'DAU'),
            const SizedBox(width: AppSpacing.sm),
            _metricCard('주간 활성', '${u?.wau ?? 0}', context, sub: 'WAU'),
            const SizedBox(width: AppSpacing.sm),
            _metricCard(
              '고착도',
              '${((u?.stickiness ?? 0) * 100).toStringAsFixed(0)}%',
              context,
              sub: '재방문',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // 보조 카드
        Row(
          children: [
            _metricCard('월간 활성', '${u?.mau ?? 0}', context, sub: 'MAU'),
            const SizedBox(width: AppSpacing.sm),
            _metricCard('누적 가입', '${u?.total ?? 0}', context),
            const SizedBox(width: AppSpacing.sm),
            _metricCard('오늘 신규', '${u?.newToday ?? 0}', context),
          ],
        ),

        const SizedBox(height: AppSpacing.md),
        _buildChartCard(context),

        const SizedBox(height: AppSpacing.md),
        _buildPlatformSplit(context, u),

        const SizedBox(height: AppSpacing.md),
        _buildRevenueCard(context),

        const SizedBox(height: AppSpacing.md),
        Text(
          '* DAU/WAU/MAU는 로그인 사용자 기준(앱 포그라운드 핑). '
          '플랫폼 분리는 당일 첫 기기(first-touch)라 합이 총량과 다를 수 있음. '
          'DAU는 누적가입자(total)와 다른 지표.',
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: context.mlColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _metricCard(
    String label,
    String value,
    BuildContext context, {
    String? sub,
  }) {
    final mlc = context.mlColors;
    return Expanded(
      child: BentoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label.copyWith(color: mlc.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            // 히어로 숫자 — 확 띄게 displayMedium20 bold. 큰 값이 3분할 카드에서
            // 넘치지 않게 scaleDown 방어(값 숨김 금지).
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: AppTypography.sectionTitle.copyWith(
                  fontSize: AppTypography.displayMedium,
                  color: mlc.textPrimary,
                  fontFeatures: AppTypography.tabularFigures,
                ),
              ),
            ),
            if (sub != null)
              Text(
                sub,
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: mlc.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(BuildContext context) {
    final mlc = context.mlColors;
    if (_series.isEmpty) {
      return BentoCard(
        child: SizedBox(
          height: 120,
          child: Center(
            child: Text(
              '데이터가 아직 없습니다',
              style: TextStyle(color: mlc.textTertiary),
            ),
          ),
        ),
      );
    }

    final dau = <FlSpot>[];
    final wau = <FlSpot>[];
    double maxY = 1;
    for (int i = 0; i < _series.length; i++) {
      dau.add(FlSpot(i.toDouble(), _series[i].dau.toDouble()));
      wau.add(FlSpot(i.toDouble(), _series[i].wau.toDouble()));
      if (_series[i].wau > maxY) maxY = _series[i].wau.toDouble();
    }

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '최근 30일',
                style: AppTypography.cardTitle.copyWith(
                  color: mlc.textPrimary,
                ),
              ),
              const Spacer(),
              _legendDot(mlc.accentBlue, '일간(DAU)'),
              const SizedBox(width: AppSpacing.sm),
              _legendDot(mlc.gainColor, '주간(WAU)'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY * 1.15,
                lineBarsData: [
                  LineChartBarData(
                    spots: wau,
                    isCurved: true,
                    color: mlc.gainColor,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: dau,
                    isCurved: true,
                    color: mlc.accentBlue,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                ],
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: mlc.subtleBorder.withValues(alpha: 0.5),
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 36),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.label),
      ],
    );
  }

  Widget _buildPlatformSplit(BuildContext context, AdminUsers? u) {
    final mlc = context.mlColors;
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '플랫폼 분리',
            style: AppTypography.cardTitle.copyWith(
              color: mlc.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _splitRow('DAU', u?.dauAndroid ?? 0, u?.dauIos ?? 0, context),
          const SizedBox(height: AppSpacing.xs),
          _splitRow('WAU', u?.wauAndroid ?? 0, u?.wauIos ?? 0, context),
        ],
      ),
    );
  }

  Widget _splitRow(String label, int android, int ios, BuildContext context) {
    final mlc = context.mlColors;
    final total = (android + ios) == 0 ? 1 : (android + ios);
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: AppTypography.label.copyWith(color: mlc.textSecondary),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: Row(
              children: [
                Expanded(
                  flex: (android / total * 1000).round().clamp(0, 1000),
                  child: Container(height: 14, color: mlc.gainColor),
                ),
                Expanded(
                  flex: (ios / total * 1000).round().clamp(0, 1000),
                  child: Container(height: 14, color: mlc.accentBlue),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'A $android · i $ios',
          style: AppTypography.label.copyWith(
            color: mlc.textSecondary,
            fontFeatures: AppTypography.tabularFigures,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueCard(BuildContext context) {
    final mlc = context.mlColors;
    final ad = _summary?.admob;
    final dl = _summary?.downloads;
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '수익 · 설치',
            style: AppTypography.cardTitle.copyWith(
              color: mlc.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _kv(
            'AdMob 오늘',
            '\$${(ad?.revenueTodayUsd ?? 0).toStringAsFixed(2)}',
            context,
            accent: true,
          ),
          _kv(
            'AdMob 이번달',
            '\$${(ad?.revenueMtdUsd ?? 0).toStringAsFixed(2)}',
            context,
            accent: true,
          ),
          _kv(
            'eCPM (1천노출당 수익)',
            '\$${(ad?.ecpm ?? 0).toStringAsFixed(2)}',
            context,
            accent: true,
          ),
          _kv('설치 오늘', '${dl?.today ?? 0}', context),
          _kv('설치 누적', '${dl?.total ?? 0}', context),
        ],
      ),
    );
  }

  /// 라벨=뮤트, 값=진한 semiBold. [accent]=true면 비방향성 집계(수익/eCPM)를
  /// accentBlue로 강조. 값은 넘치지 않게 Flexible+scaleDown로 방어.
  /// 관리자 통계 카드의 라벨+값 한 행.
  Widget _kv(String k, String v, BuildContext context, {bool accent = false}) {
    return MlKeyValueRow(
      label: k,
      value: v,
      emphasis: accent ? MlKvEmphasis.blue : MlKvEmphasis.normal,
      dense: true,
    );
  }
}
