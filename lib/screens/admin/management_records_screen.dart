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
import 'trend_modal.dart';

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
  String? _categoryFilter; // null=전체 (plan/note 한정 노출)
  SubTaskStatus? _statusFilter; // null=전체 (plan 한정 노출)
  late String _selectedMonth; // YYYY-MM
  OpsSummary? _summary;
  OpsSummary? _prevSummary; // 전월 대비용
  List<OpsMonthlyPoint> _monthly = const []; // 선택 연도 12개월
  List<ManagementRecord> _records = const [];
  CategoryBreakdown? _breakdown;

  static const _kinds = <(String?, String)>[
    (null, '전체'),
    ('finance', '재무'),
    ('asset', '자산'),
    ('plan', '계획'),
    ('note', '메모'),
  ];

  // plan/note 공통 카테고리 — 추가 필터칩에 노출.
  static const _planNoteCats = <String?>[null, '경영', '운영', '개발', '기타'];
  // plan 상태 필터칩 — SubTask 상태 5종.
  static const _planStatuses = <SubTaskStatus?>[
    null,
    SubTaskStatus.todo,
    SubTaskStatus.inProgress,
    SubTaskStatus.done,
    SubTaskStatus.failed,
    SubTaskStatus.blocked,
  ];

  static String _ymOf(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  static String _prevMonth(String ym) {
    final p = ym.split('-');
    int y = int.parse(p[0]);
    int m = int.parse(p[1]) - 1;
    if (m == 0) {
      y -= 1;
      m = 12;
    }
    return '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}';
  }

  static int _yearOf(String ym) => int.parse(ym.split('-')[0]);

  static List<String> _monthsOfYear(int year) => List.generate(
        12,
        (i) =>
            '${year.toString().padLeft(4, '0')}-${(i + 1).toString().padLeft(2, '0')}',
      );

  @override
  void initState() {
    super.initState();
    _selectedMonth = _ymOf(DateTime.now());
    _load();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  /// 선택 연도 전체 12개월 시계열을 채워서 반환(서버는 과거→현재까지만 반환하므로 미래 월은 0으로 채움).
  Future<List<OpsMonthlyPoint>> _fetchMonthsOfYear(int year) async {
    final now = DateTime.now();
    final monthsBack = (now.year - year) * 12 + now.month;
    if (monthsBack <= 0) {
      // 미래 연도 — 빈 12개월
      return _monthsOfYear(year)
          .map(
            (ym) => OpsMonthlyPoint(
              month: ym, income: 0, expense: 0, dividend: 0, net: 0,
            ),
          )
          .toList();
    }
    final all = await _api.getOpsMonthly(months: monthsBack);
    final byMonth = {for (final m in all) m.month: m};
    return _monthsOfYear(year)
        .map(
          (ym) =>
              byMonth[ym] ??
              OpsMonthlyPoint(
                month: ym, income: 0, expense: 0, dividend: 0, net: 0,
              ),
        )
        .toList();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ym = _selectedMonth;
      final summary = await _api.getOpsSummary(month: ym);
      final prevSummary = await _api.getOpsSummary(month: _prevMonth(ym));
      final monthly = await _fetchMonthsOfYear(_yearOf(ym));
      final breakdown = await _api.getOpsCategoryBreakdown(month: ym);
      final records = await _api.getOpsRecords(kind: _kindFilter);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _prevSummary = prevSummary;
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
      final ym = _selectedMonth;
      final records = await _api.getOpsRecords(kind: _kindFilter);
      final summary = await _api.getOpsSummary(month: ym);
      final prevSummary = await _api.getOpsSummary(month: _prevMonth(ym));
      final monthly = await _fetchMonthsOfYear(_yearOf(ym));
      final breakdown = await _api.getOpsCategoryBreakdown(month: ym);
      if (!mounted) return;
      setState(() {
        _records = records;
        _summary = summary;
        _prevSummary = prevSummary;
        _monthly = monthly;
        _breakdown = breakdown;
      });
    } catch (_) {}
  }

  Future<void> _onMonthSelected(String ym) async {
    if (ym == _selectedMonth) return;
    setState(() => _selectedMonth = ym);
    await _reloadRecords();
  }

  /// 연도 이동(월 번호 유지). 재무·자산 월별 뷰를 과거/미래 연도로 전환.
  Future<void> _changeYear(int delta) async {
    final p = _selectedMonth.split('-');
    final y = int.parse(p[0]) + delta;
    await _onMonthSelected('${y.toString().padLeft(4, '0')}-${p[1]}');
  }

  Future<void> _openTrend() async {
    final picked = await showTrendModal(
      context,
      api: _api,
      selectedMonth: _selectedMonth,
    );
    if (!mounted || picked == null) return;
    await _onMonthSelected(picked);
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
      appBar: AppBar(
        title: const Text('경영·운영 관리'),
        actions: [
          TextButton.icon(
            onPressed: _openTrend,
            icon: const Icon(Icons.show_chart, size: 18),
            label: const Text('추이'),
            style: TextButton.styleFrom(
              foregroundColor: context.mlColors.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
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
    final showExtraFilters =
        _kindFilter == 'plan' || _kindFilter == 'note';
    final showStatusFilter = _kindFilter == 'plan';
    // 1) 월 + 카테고리(plan/note) + 상태(plan) 필터 적용 — kind는 서버 응답이 이미 필터.
    final filteredRecords = _records.where((r) {
      // 발생일(월) 필터는 재무·자산(월별 손익 성격)에만 적용.
      // 계획·메모는 업무목록 성격 — 여러 달/해에 걸쳐 진행되므로 월에 묶지 않고 항상 노출.
      final monthBound = r.kind == 'finance' || r.kind == 'asset';
      if (monthBound && r.occurredOn != null && r.occurredOn!.isNotEmpty) {
        if (!r.occurredOn!.startsWith(_selectedMonth)) return false;
      }
      if (showExtraFilters && _categoryFilter != null) {
        if (r.category != _categoryFilter) return false;
      }
      if (showStatusFilter && _statusFilter != null) {
        // SubTask가 하나라도 해당 상태이면 통과(가장 직관적).
        // SubTask가 없는 글은 statusFilter가 있으면 제외.
        if (r.subTasks.isEmpty) return false;
        if (!r.subTasks.any((t) => t.status == _statusFilter)) return false;
      }
      return true;
    }).toList();
    return SelectionArea(
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          MediaQuery.of(context).viewPadding.bottom + 88,
        ),
        children: [
        _monthChipsRow(context),
        const SizedBox(height: AppSpacing.sm),
        _tasksProgressCard(context),
        const SizedBox(height: AppSpacing.md),
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
                    setState(() {
                      _kindFilter = k.$1;
                      _categoryFilter = null;
                      _statusFilter = null;
                    });
                    _reloadRecords();
                  },
                ),
              );
            }).toList(),
          ),
        ),
        if (showExtraFilters) ...[
          const SizedBox(height: 4),
          _categoryFilterRow(mlc),
        ],
        if (showStatusFilter) ...[
          const SizedBox(height: 4),
          _statusFilterRow(mlc),
        ],
        const SizedBox(height: AppSpacing.sm),
        if (filteredRecords.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Center(
              child: Text(
                // 계획·메모는 월에 묶이지 않으므로 월 표기를 뺀다.
                showExtraFilters ? '기록 없음' : '$_selectedMonth 기록 없음',
                style: TextStyle(color: mlc.textTertiary),
              ),
            ),
          )
        else
          ...filteredRecords.map(_recordTile),
      ],
      ),
    );
  }

  Widget _categoryFilterRow(MarketLensColors mlc) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _planNoteCats.map((c) {
          final selected = _categoryFilter == c;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: ChoiceChip(
              label: Text(c ?? '전체'),
              selected: selected,
              showCheckmark: false,
              labelStyle: AppTypography.label.copyWith(
                color: selected ? mlc.textPrimary : mlc.textSecondary,
                fontWeight: selected
                    ? AppTypography.bold
                    : AppTypography.regular,
              ),
              onSelected: (_) => setState(() => _categoryFilter = c),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _statusFilterRow(MarketLensColors mlc) {
    Color colorOf(SubTaskStatus? s) {
      if (s == null) return mlc.textSecondary;
      switch (s) {
        case SubTaskStatus.todo:
          return mlc.neutralColor;
        case SubTaskStatus.inProgress:
          return mlc.accentBlue;
        case SubTaskStatus.done:
          return mlc.gainColor;
        case SubTaskStatus.failed:
          return mlc.dangerColor;
        case SubTaskStatus.blocked:
          return mlc.warningColor;
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _planStatuses.map((s) {
          final selected = _statusFilter == s;
          final color = colorOf(s);
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: ChoiceChip(
              label: Text(s == null ? '전체 상태' : s.label),
              selected: selected,
              showCheckmark: false,
              labelStyle: TextStyle(
                fontSize: AppTypography.bodySmall,
                fontWeight: selected
                    ? AppTypography.bold
                    : AppTypography.regular,
                color: selected ? color : mlc.textSecondary,
              ),
              selectedColor: color.withValues(alpha: 0.14),
              onSelected: (_) => setState(() => _statusFilter = s),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _monthChipsRow(BuildContext context) {
    final mlc = context.mlColors;
    final year = _yearOf(_selectedMonth);
    final months = _monthsOfYear(year);
    final curYear = DateTime.now().year;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 연도 이동 — 재무·자산 월별 뷰를 과거/미래 연도로 전환.
        Row(
          children: [
            IconButton(
              tooltip: '이전 해',
              onPressed: () => _changeYear(-1),
              icon: const Icon(Icons.chevron_left, size: 20),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            Text(
              '$year년',
              style: AppTypography.body.copyWith(
                color: mlc.textPrimary,
                fontWeight: AppTypography.bold,
              ),
            ),
            IconButton(
              tooltip: '다음 해',
              onPressed: () => _changeYear(1),
              icon: const Icon(Icons.chevron_right, size: 20),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            if (year != curYear) ...[
              const SizedBox(width: AppSpacing.xs),
              TextButton(
                onPressed: () => _onMonthSelected(_ymOf(DateTime.now())),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('올해'),
              ),
            ],
          ],
        ),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: months.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final ym = months[i];
              final selected = ym == _selectedMonth;
              final label = '${i + 1}월';
              return ChoiceChip(
                label: Text(label),
                selected: selected,
                showCheckmark: false,
                labelStyle: AppTypography.label.copyWith(
                  color: selected ? mlc.textPrimary : mlc.textSecondary,
                  fontWeight: selected
                      ? AppTypography.bold
                      : AppTypography.regular,
                ),
                onSelected: (_) => _onMonthSelected(ym),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 전체 plan 글의 SubTask를 합산해 진척률을 보여주는 카드.
  /// 완료만 분자(% = done/total). 실패·보류·진행중은 본문 메타에 별도 표시.
  /// 탭하면 plan 필터로 전환.
  Widget _tasksProgressCard(BuildContext context) {
    final mlc = context.mlColors;
    int total = 0;
    int done = 0;
    int inProgress = 0;
    int failed = 0;
    int blocked = 0;
    int projects = 0;
    for (final r in _records) {
      if (r.kind != 'plan' || r.subTasks.isEmpty) continue;
      // 카테고리 필터가 활성화돼 있고(plan/note 한정), 일치하지 않으면 제외.
      if (_categoryFilter != null && r.category != _categoryFilter) continue;
      projects++;
      total += r.subTasks.length;
      for (final t in r.subTasks) {
        switch (t.status) {
          case SubTaskStatus.done:
            done++;
            break;
          case SubTaskStatus.inProgress:
            inProgress++;
            break;
          case SubTaskStatus.failed:
            failed++;
            break;
          case SubTaskStatus.blocked:
            blocked++;
            break;
          case SubTaskStatus.todo:
            break;
        }
      }
    }
    if (total == 0) {
      return BentoCard(
        child: Row(
          children: [
            Icon(Icons.task_alt, size: 16, color: mlc.textTertiary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '업무 진척률 — 등록된 체크리스트 없음',
              style: AppTypography.label.copyWith(color: mlc.textTertiary),
            ),
          ],
        ),
      );
    }
    final todo = total - done - inProgress - failed - blocked;
    final ratio = done / total;
    final barColor = ratio >= 1.0
        ? mlc.gainColor
        : (done > 0 || inProgress > 0 ? mlc.accentBlue : mlc.warningColor);

    // 한 줄에 '대기 · 진행중 · 완료 · 실패 · 보류' 중 0 아닌 것만 표시.
    final parts = <(int, String, Color)>[
      (todo, '대기', mlc.neutralColor),
      (inProgress, '진행중', mlc.accentBlue),
      (done, '완료', mlc.gainColor),
      (failed, '실패', mlc.dangerColor),
      (blocked, '보류', mlc.warningColor),
    ].where((e) => e.$1 > 0).toList();

    return InkWell(
      onTap: () {
        if (_kindFilter == 'plan') return;
        setState(() {
          _kindFilter = 'plan';
          _categoryFilter = null;
          _statusFilter = null;
        });
        _reloadRecords();
      },
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: BentoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '업무 진척률',
                  style: AppTypography.cardTitle.copyWith(
                    color: mlc.textPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '· 프로젝트 $projects개',
                  style: AppTypography.label.copyWith(color: mlc.textTertiary),
                ),
                const Spacer(),
                Text(
                  '${(ratio * 100).round()}%',
                  style: AppTypography.bodyStrong.copyWith(color: barColor),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 2,
              children: [
                Text(
                  '총 $total',
                  style: AppTypography.label
                      .copyWith(color: mlc.textSecondary),
                ),
                for (final p in parts)
                  RichText(
                    text: TextSpan(
                      style: AppTypography.label
                          .copyWith(color: mlc.textSecondary),
                      children: [
                        TextSpan(text: '${p.$2} '),
                        TextSpan(
                          text: '${p.$1}',
                          style: TextStyle(
                            color: p.$3,
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: mlc.overlayDim,
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
          ],
        ),
      ),
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
                style: AppTypography.label.copyWith(color: mlc.textSecondary),
              ),
              const SizedBox(height: 2),
              // P&L 금액을 확 띄게 headlineMedium16 bold로 키움. 3분할 셀에서
              // 넘칠 수 있어 ellipsis 대신 scaleDown으로 방어(값 숨김 금지).
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  won(v),
                  maxLines: 1,
                  style: AppTypography.bodyStrong.copyWith(
                    fontSize: AppTypography.headlineMedium,
                    fontWeight: AppTypography.bold,
                    color: c,
                    fontFeatures: AppTypography.tabularFigures,
                  ),
                ),
              ),
            ],
          ),
        );
    // 전월 대비 인디케이터 — 순익 차이 + 퍼센트
    final curNet = s?.net ?? 0;
    final prevNet = _prevSummary?.net ?? 0;
    final delta = curNet - prevNet;
    String? deltaLine;
    Color deltaColor = mlc.textSecondary;
    if (s != null && _prevSummary != null) {
      final up = delta >= 0;
      deltaColor = up ? mlc.gainColor : mlc.lossColor;
      final pct = prevNet.abs() > 0
          ? '${(delta / prevNet.abs() * 100).toStringAsFixed(1)}%'
          : null;
      final arrow = up ? '↑' : '↓';
      final pctStr = pct != null ? ' (${up ? '+' : ''}$pct)' : '';
      deltaLine =
          '$arrow 전월 대비 ${up ? '+' : ''}${won(delta)}$pctStr';
    }
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${s?.month ?? ''} 손익',
            style: AppTypography.cardTitle.copyWith(
              color: mlc.textPrimary,
            ),
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
          if (deltaLine != null) ...[
            const SizedBox(height: 2),
            Text(
              deltaLine,
              style: AppTypography.label.copyWith(color: deltaColor),
            ),
          ],
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
                style: AppTypography.cardTitle.copyWith(
                  color: mlc.textPrimary,
                ),
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
    final year = _yearOf(_selectedMonth);
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '월별 순익 ($year년)',
            style: AppTypography.cardTitle.copyWith(
              color: mlc.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._monthly.map((m) {
            final pos = m.net >= 0;
            final frac = (m.net.abs() / maxAbs).clamp(0.0, 1.0);
            final selected = m.month == _selectedMonth;
            return InkWell(
              onTap: () => _onMonthSelected(m.month),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 52,
                      child: Text(
                        m.month.substring(2),
                        style: AppTypography.label.copyWith(
                          color: selected ? mlc.textPrimary : mlc.textSecondary,
                          fontWeight: selected
                              ? AppTypography.bold
                              : AppTypography.regular,
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
                                borderRadius:
                                    BorderRadius.circular(AppRadius.xs),
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
                          fontWeight: selected
                              ? AppTypography.bold
                              : AppTypography.regular,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
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
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          r.title,
                          style: AppTypography.body.copyWith(
                            color: mlc.textPrimary,
                            fontWeight: AppTypography.semiBold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (r.kind == 'plan' && r.subTasks.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _planProgressBadge(r, mlc),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  // 계획+체크리스트: 제목 아래에 완료/미완료/실패 분포를 색으로 노출.
                  if (r.kind == 'plan' && r.subTasks.isNotEmpty)
                    _planBreakdownLine(r, mlc)
                  else
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

  /// 계획 타일 제목 아래 줄 — 몇 개 중 완료·진행중·대기·실패·보류 몇 개인지 색으로.
  /// 0건인 상태는 숨긴다. 예) "총 8 · 완료 3 · 진행중 2 · 대기 2 · 실패 1"
  Widget _planBreakdownLine(ManagementRecord r, MarketLensColors mlc) {
    final total = r.subTasks.length;
    int done = 0, inProgress = 0, failed = 0, blocked = 0;
    for (final t in r.subTasks) {
      switch (t.status) {
        case SubTaskStatus.done:
          done++;
          break;
        case SubTaskStatus.inProgress:
          inProgress++;
          break;
        case SubTaskStatus.failed:
          failed++;
          break;
        case SubTaskStatus.blocked:
          blocked++;
          break;
        case SubTaskStatus.todo:
          break;
      }
    }
    final todo = total - done - inProgress - failed - blocked;
    final parts = <(int, String, Color)>[
      (todo, '대기', mlc.neutralColor),
      (inProgress, '진행중', mlc.accentBlue),
      (done, '완료', mlc.gainColor),
      (failed, '실패', mlc.dangerColor),
      (blocked, '보류', mlc.warningColor),
    ].where((e) => e.$1 > 0).toList();
    return Wrap(
      spacing: 6,
      runSpacing: 1,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '총 $total',
          style: AppTypography.label.copyWith(color: mlc.textTertiary),
        ),
        for (final p in parts)
          RichText(
            text: TextSpan(
              style: AppTypography.label.copyWith(color: mlc.textTertiary),
              children: [
                TextSpan(text: '${p.$2} '),
                TextSpan(
                  text: '${p.$1}',
                  style: TextStyle(
                    color: p.$3,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _planProgressBadge(ManagementRecord r, MarketLensColors mlc) {
    final total = r.subTasks.length;
    final done = r.subTasks.where((t) => t.done).length;
    final ratio = total == 0 ? 0.0 : done / total;
    final color = ratio >= 1.0
        ? mlc.gainColor
        : (done > 0 ? mlc.accentBlue : mlc.warningColor);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        '$done/$total · ${(ratio * 100).round()}%',
        style: TextStyle(
          fontSize: AppTypography.micro,
          fontWeight: AppTypography.bold,
          color: color,
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
          fontSize: AppTypography.caption,
          fontWeight: AppTypography.bold,
          color: color,
        ),
      ),
    );
  }
}
