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

/// 경영·운영 관리 — **Master 전용**.
/// 월별 P&L(수익/지출/순익) + 카테고리·종류 필터 + 기록 CRUD + 자산 등록번호.
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
      final records = await _api.getOpsRecords(kind: _kindFilter);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _monthly = monthly;
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
      if (!mounted) return;
      setState(() {
        _records = records;
        _summary = summary;
        _monthly = monthly;
      });
    } catch (_) {}
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
        onPressed: () => _openForm(),
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
        _monthlyCard(context),
        const SizedBox(height: AppSpacing.md),
        // 종류 필터
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
      onTap: () => _openForm(record: r),
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

  // ── 추가/수정 폼 (바텀시트) ──
  void _openForm({ManagementRecord? record}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => _RecordForm(
        api: _api,
        record: record,
        onSaved: () {
          Navigator.pop(context);
          _reloadRecords();
        },
        onDeleted: () {
          Navigator.pop(context);
          _reloadRecords();
        },
      ),
    );
  }
}

/// 기록 추가/수정 폼. kind에 따라 필드가 바뀐다.
class _RecordForm extends StatefulWidget {
  const _RecordForm({
    required this.api,
    required this.onSaved,
    required this.onDeleted,
    this.record,
  });
  final AdminApiClient api;
  final ManagementRecord? record;
  final VoidCallback onSaved;
  final VoidCallback onDeleted;

  @override
  State<_RecordForm> createState() => _RecordFormState();
}

class _RecordFormState extends State<_RecordForm> {
  late String _kind;
  late String _category;
  late String _status; // '' = 미지정
  String? _assetType;
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _quantity = TextEditingController();
  final _vendor = TextEditingController();
  final _content = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  static const _catByKind = {
    'finance': ['지출', '수익', '배당'],
    'asset': ['비품', '소모품', '장비', 'SW', '기타'],
    'plan': ['경영', '운영', '개발', '기타'],
    'note': ['경영', '운영', '개발', '기타'],
  };

  // 종류별 상태(자산은 폐기·불용 처분 가능 — 등록 후 나중에 수정).
  static const _statusByKind = {
    'finance': {'': '미지정', '결제완료': '결제완료', '대기': '대기', '예정': '예정'},
    'asset': {'': '미지정', '사용중': '사용중', '폐기': '폐기', '불용': '불용 처분'},
    'plan': {'': '미지정', '계획': '계획', '진행중': '진행중', '완료': '완료'},
    'note': {'': '미지정'},
  };

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _kind = r?.kind ?? 'finance';
    _category = r?.category ?? _catByKind[_kind]!.first;
    _status = r?.status ?? '';
    _assetType = r?.assetType ?? (_kind == 'asset' ? 'fixed' : null);
    _title.text = r?.title ?? '';
    _amount.text = r?.amount != null ? r!.amount!.round().toString() : '';
    _quantity.text = r?.quantity?.toString() ?? '';
    _vendor.text = r?.vendor ?? '';
    _content.text = r?.content ?? '';
    if (r?.occurredOn != null) {
      _date = DateTime.tryParse(r!.occurredOn!) ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _amount, _quantity, _vendor, _content]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _direction() {
    if (_kind == 'finance') return _category == '수익' ? 'in' : 'out';
    if (_kind == 'asset') return 'out';
    return null;
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final body = <String, dynamic>{
      'kind': _kind,
      'category': _category,
      'title': _title.text.trim(),
      'content': _content.text.trim().isEmpty ? null : _content.text.trim(),
      'occurred_on':
          '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
      'direction': _direction(),
      'currency': 'KRW',
      'status': _status.isEmpty ? null : _status,
    };
    if (_kind == 'finance' || _kind == 'asset') {
      final a = double.tryParse(_amount.text.replaceAll(',', ''));
      if (a != null) body['amount'] = a;
    }
    if (_kind == 'asset') {
      body['asset_type'] = _assetType;
      final q = int.tryParse(_quantity.text);
      if (q != null) body['quantity'] = q;
      if (_vendor.text.trim().isNotEmpty) body['vendor'] = _vendor.text.trim();
    }
    try {
      if (widget.record == null) {
        await widget.api.createOpsRecord(body);
      } else {
        await widget.api.updateOpsRecord(widget.record!.id, body);
      }
      widget.onSaved();
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    setState(() => _saving = true);
    try {
      await widget.api.deleteOpsRecord(widget.record!.id);
      widget.onDeleted();
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mlc = context.mlColors;
    final isAsset = _kind == 'asset';
    final isFinance = _kind == 'finance';
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.record == null ? '기록 추가' : '기록 수정',
              style: AppTypography.sectionTitle.copyWith(
                color: mlc.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // 종류
            _dropdown(
              '종류',
              _kind,
              const {
                'finance': '재무',
                'asset': '자산',
                'plan': '계획',
                'note': '메모',
              },
              (v) => setState(() {
                _kind = v;
                _category = _catByKind[_kind]!.first;
                _assetType = v == 'asset' ? 'fixed' : null;
                _status = '';
              }),
            ),
            const SizedBox(height: AppSpacing.md),
            // 카테고리
            _dropdown('카테고리', _category, {
              for (final c in _catByKind[_kind]!) c: c,
            }, (v) => setState(() => _category = v)),
            const SizedBox(height: AppSpacing.md),
            _field(isAsset ? '품명' : '제목', _title),
            if (isAsset) ...[
              const SizedBox(height: AppSpacing.md),
              _dropdown('유형', _assetType ?? 'fixed', const {
                'fixed': '고정자산',
                'consumable': '소모품',
              }, (v) => setState(() => _assetType = v)),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      '수량',
                      _quantity,
                      keyboard: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _field('구매처', _vendor)),
                ],
              ),
            ],
            if (isFinance || isAsset) ...[
              const SizedBox(height: AppSpacing.md),
              _field(
                isAsset ? '구매가(원)' : '금액(원)',
                _amount,
                keyboard: TextInputType.number,
              ),
            ],
            if (_statusByKind[_kind]!.length > 1) ...[
              const SizedBox(height: AppSpacing.md),
              // 자산: 사용중/폐기/불용 처분 (등록번호 유지한 채 나중에 수정)
              _dropdown(
                '상태',
                _status,
                _statusByKind[_kind]!,
                (v) => setState(() => _status = v),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            // 날짜
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (d != null) setState(() => _date = d);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '날짜',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _field('내용(선택)', _content, maxLines: 3),
            if (isAsset && widget.record?.assetNo != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '등록번호: ${widget.record!.assetNo}',
                style: AppTypography.label.copyWith(color: mlc.accentBlue),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                if (widget.record != null)
                  TextButton.icon(
                    onPressed: _saving ? null : _delete,
                    icon: Icon(Icons.delete_outline, color: mlc.lossColor),
                    label: Text('삭제', style: TextStyle(color: mlc.lossColor)),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? '저장 중…' : '저장'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController c, {
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    Map<String, String> items,
    ValueChanged<String> onChanged,
  ) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.containsKey(value) ? value : items.keys.first,
          isExpanded: true,
          items: items.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      ),
    );
  }
}
