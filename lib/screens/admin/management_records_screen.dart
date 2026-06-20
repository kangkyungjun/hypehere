import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/management_record.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/bento_card.dart';
import 'record_detail_screen.dart';
import 'record_form_sheet.dart';

/// 경영·운영 관리 — **Master 전용**.
/// 월별 P&L(수익/지출/순익) + 카테고리·종류 필터 + 기록 목록.
/// 목록 항목 탭 → 상세 페이지(`RecordDetailScreen`)로 이동.
/// `+` FAB → 추가 폼(`showRecordFormSheet`).
class ManagementRecordsScreen extends StatefulWidget {
  const ManagementRecordsScreen({super.key});

  @override
  State<ManagementRecordsScreen> createState() =>
      _ManagementRecordsScreenState();
}

class _ManagementRecordsScreenState extends State<ManagementRecordsScreen> {
  final AdminApiClient _api = AdminApiClient();

  bool _loading = true;
  String? _error;
  String? _kindFilter; // null=전체
  OpsSummary? _summary;
  List<OpsMonthlyPoint> _monthly = const [];
  List<ManagementRecord> _records = const [];
  CategoryBreakdown? _breakdown;

  static const _kinds = <(String?, String)>[
    (null, '전체'),
    ('finance', '재무'),
    ('asset', '자산'),
    ('plan', '계획'),
    ('note', '메모'),
  ];

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
      final summary = await _api.getOpsSummary();
      final monthly = await _api.getOpsMonthly(months: 6);
      final breakdown = await _api.getOpsCategoryBreakdown();
      final records = await _api.getOpsRecords(kind: _kindFilter);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _monthly = monthly;
        _breakdown = breakdown;
        _records = records;
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

  Future<void> _reloadRecords() async {
    try {
      final records = await _api.getOpsRecords(kind: _kindFilter);
      final summary = await _api.getOpsSummary();
      final monthly = await _api.getOpsMonthly(months: 6);
      final breakdown = await _api.getOpsCategoryBreakdown();
      if (!mounted) return;
      setState(() {
        _records = records;
        _summary = summary;
        _monthly = monthly;
        _breakdown = breakdown;
      });
    } catch (_) {}
  }

  Future<void> _openAddForm() async {
    final result = await showRecordFormSheet(context, api: _api);
    if (!mounted) return;
    if (result is ManagementRecord || result == false) {
      _reloadRecords();
    }
  }

  Future<void> _openDetail(ManagementRecord r) async {
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => RecordDetailScreen(record: r),
      ),
    );
    if (!mounted) return;
    if (result == true || result == false) {
      _reloadRecords();
      if (result == false) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('삭제되었습니다')));
      }
    }
  }

  static String won(double v) {
    final neg = v < 0;
    final s = v.abs().round().toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return '${neg ? '-' : ''}₩$b';
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AuthProvider>().isMaster) {
      return Scaffold(
        appBar: AppBar(title: const Text('경영·운영 관리')),
        body: const Center(child: Text('접근 권한이 없습니다.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('경영·운영 관리')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddForm,
        child: const Icon(Icons.add),
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

  Widget _buildBody(BuildContext context) {
    final mlc = context.mlColors;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        MediaQuery.of(context).viewPadding.bottom + 88,
      ),
      children: [
        _summaryCard(context),
        const SizedBox(height: AppSpacing.md),
        if (_breakdown != null &&
            (_breakdown!.expense.isNotEmpty ||
                _breakdown!.income.isNotEmpty)) ...[
          _breakdownCard(context, _breakdown!),
          const SizedBox(height: AppSpacing.md),
        ],
        _monthlyCard(context),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _kinds.map((k) {
              final selected = _kindFilter == k.$1;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: ChoiceChip(
                  label: Text(k.$2),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) {
                    setState(() => _kindFilter = k.$1);
                    _reloadRecords();
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_records.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Center(
              child: Text(
                '기록이 없습니다. + 로 추가하세요.',
                style: TextStyle(color: mlc.textTertiary),
              ),
            ),
          )
        else
          ..._records.map(_recordTile),
      ],
    );
  }

  Widget _summaryCard(BuildContext context) {
    final mlc = context.mlColors;
    final s = _summary;
    Widget cell(String label, double v, Color c) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.label.copyWith(color: mlc.textTertiary),
              ),
              const SizedBox(height: 2),
              Text(
                won(v),
                style: AppTypography.bodyStrong.copyWith(color: c),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${s?.month ?? ''} 손익',
            style: AppTypography.cardTitle.copyWith(color: mlc.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              cell('수익', s?.income ?? 0, mlc.gainColor),
              cell('지출', s?.expense ?? 0, mlc.lossColor),
              cell(
                '순익',
                s?.net ?? 0,
                (s?.net ?? 0) >= 0 ? mlc.gainColor : mlc.lossColor,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '배당 ${won(s?.dividend ?? 0)}',
            style: AppTypography.label.copyWith(color: mlc.textSecondary),
          ),
        ],
      ),
    );
  }

  /// 월별 카테고리 분포 카드 — 지출 위주, 상위 N개 표시. 수익은 한 줄 요약.
  Widget _breakdownCard(BuildContext context, CategoryBreakdown b) {
    final mlc = context.mlColors;
    final expenseTotal = b.expense.fold<double>(0, (a, e) => a + e.amount);
    final incomeTotal = b.income.fold<double>(0, (a, e) => a + e.amount);
    final maxAbs = b.expense
        .map((e) => e.amount)
        .fold<double>(1, (a, x) => x > a ? x : a);

    Widget row(CategoryAmount e) {
      final frac = (e.amount / maxAbs).clamp(0.0, 1.0);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 76,
              child: Text(
                e.category,
                style: AppTypography.label.copyWith(color: mlc.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: mlc.overlayDim,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: frac,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: mlc.lossColor,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 80,
              child: Text(
                won(e.amount),
                textAlign: TextAlign.right,
                style: AppTypography.label.copyWith(color: mlc.lossColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 38,
              child: Text(
                '${(e.share * 100).round()}%',
                textAlign: TextAlign.right,
                style: AppTypography.label.copyWith(color: mlc.textTertiary),
              ),
            ),
          ],
        ),
      );
    }

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '카테고리별 ${b.month}',
                style:
                    AppTypography.cardTitle.copyWith(color: mlc.textPrimary),
              ),
              const Spacer(),
              if (incomeTotal > 0)
                Text(
                  '수익 ${won(incomeTotal)}',
                  style: AppTypography.label.copyWith(color: mlc.gainColor),
                ),
            ],
          ),
          if (b.expense.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                '이번 달 지출 기록 없음',
                style: TextStyle(
                  fontSize: AppTypography.bodySmall,
                  color: mlc.textTertiary,
                ),
              ),
            )
          else ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '지출 ${won(expenseTotal)}',
              style: AppTypography.label.copyWith(color: mlc.lossColor),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...b.expense.take(8).map(row),
            if (b.expense.length > 8) ...[
              const SizedBox(height: 2),
              Text(
                '외 ${b.expense.length - 8}건',
                style: AppTypography.label.copyWith(color: mlc.textTertiary),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _monthlyCard(BuildContext context) {
    final mlc = context.mlColors;
    if (_monthly.isEmpty) return const SizedBox.shrink();
    final maxAbs = _monthly
        .map((m) => m.net.abs())
        .fold<double>(1, (a, b) => b > a ? b : a);
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '월별 순익 (최근 6개월)',
            style: AppTypography.cardTitle.copyWith(color: mlc.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._monthly.map((m) {
            final pos = m.net >= 0;
            final frac = (m.net.abs() / maxAbs).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      m.month.substring(2),
                      style: AppTypography.label.copyWith(
                        color: mlc.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: mlc.overlayDim,
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: frac,
                          child: Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: pos ? mlc.gainColor : mlc.lossColor,
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 92,
                    child: Text(
                      won(m.net),
                      textAlign: TextAlign.right,
                      style: AppTypography.label.copyWith(
                        color: pos ? mlc.gainColor : mlc.lossColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _recordTile(ManagementRecord r) {
    final mlc = context.mlColors;
    final isFinanceLike = r.kind == 'finance' || r.kind == 'asset';
    final amtColor = r.direction == 'in' ? mlc.gainColor : mlc.lossColor;
    final sub = <String>[
      r.category,
      if (r.occurredOn != null) r.occurredOn!,
      if (r.assetNo != null) r.assetNo!,
      if (r.vendor != null) r.vendor!,
      if (r.status != null) r.status!,
    ].join('  ·  ');
    return InkWell(
      onTap: () => _openDetail(r),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: mlc.subtleBorder, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            _kindBadge(r.kind, mlc),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.title,
                    style: AppTypography.body.copyWith(
                      color: mlc.textPrimary,
                      fontWeight: AppTypography.semiBold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: AppTypography.label.copyWith(
                      color: mlc.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isFinanceLike && r.amount != null)
              Text(
                '${r.direction == 'in' ? '+' : '-'}${won(r.amount!)}',
                style: AppTypography.body.copyWith(
                  color: amtColor,
                  fontWeight: AppTypography.bold,
                ),
              ),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right, size: 18, color: mlc.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _kindBadge(String kind, MarketLensColors mlc) {
    final map = {
      'finance': ('재무', mlc.accentBlue),
      'asset': ('자산', mlc.eventConferenceColor),
      'plan': ('계획', mlc.warningColor),
      'note': ('메모', mlc.neutralColor),
    };
    final (label, color) = map[kind] ?? ('기타', mlc.neutralColor);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppTypography.micro,
          fontWeight: AppTypography.bold,
          color: color,
        ),
      ),
    );
  }
}
