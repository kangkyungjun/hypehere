import 'package:flutter/material.dart';

import '../../models/management_record.dart';
import '../../services/admin_api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// 기록 추가/수정 바텀시트 헬퍼.
/// 반환값:
///  - `ManagementRecord`: 저장된(또는 새로 만들어진) 레코드
///  - `null`: 시트 취소
///  - `false`: 레코드가 삭제됨 (호출자는 상세 화면을 pop해야 함)
Future<Object?> showRecordFormSheet(
  BuildContext context, {
  required AdminApiClient api,
  ManagementRecord? record,
}) {
  return showModalBottomSheet<Object?>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => RecordFormSheet(api: api, record: record),
  );
}

/// 종류별 가변 폼. 재무·자산은 금액/구매처/등록번호, 계획·메모는 텍스트 중심.
class RecordFormSheet extends StatefulWidget {
  const RecordFormSheet({super.key, required this.api, this.record});
  final AdminApiClient api;
  final ManagementRecord? record;

  @override
  State<RecordFormSheet> createState() => _RecordFormSheetState();
}

class _RecordFormSheetState extends State<RecordFormSheet> {
  late String _kind;
  late String _category;
  late String _status;
  String? _assetType;
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _quantity = TextEditingController();
  final _vendor = TextEditingController();
  final _content = TextEditingController();
  // 계획(plan) 신규 작성 시 체크리스트를 함께 구성 — 줄바꿈으로 항목 N개.
  final _subtasks = TextEditingController();
  final _subAssignee = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  // 재무 카테고리 — 수익 4 / 배당 1 / 지출 20.
  //   '수익'/'지출'은 구버전 호환용(과거 데이터는 그대로 살아있고 편집도 가능).
  //   분류는 그룹 헤더 없이 의미 순서로 나열. P&L 집계는 direction + category 기반.
  static const _financeIncomeCats = ['광고', 'IAP', '기타수익', '수익'];
  static const _financeDividendCats = ['배당'];
  static const _financeExpenseCats = [
    '서버비', 'SaaS구독', '급여', '외주', '광고비', '콘텐츠',
    '교통비', '숙박', '식비(출장)', '일당',
    '식비(일상)', '비품', '통신비',
    '수수료', '이자',
    '부가세', '법인세', '원천세',
    '기타지출', '지출',
  ];
  static final _financeCats = [
    ..._financeIncomeCats,
    ..._financeDividendCats,
    ..._financeExpenseCats,
  ];
  static final _financeIncomeSet = _financeIncomeCats.toSet();

  static final _catByKind = <String, List<String>>{
    'finance': _financeCats,
    'asset': const ['비품', '소모품', '장비', 'SW', '기타'],
    'plan': const ['경영', '운영', '개발', '기타'],
    'note': const ['경영', '운영', '개발', '기타'],
  };

  static const _statusByKind = {
    // 결제완료=정기/계약성, 구매=1회성/단기 구독·일회성 결제, 대기=결제 진행 중, 예정=예약/예산
    'finance': {
      '': '미지정',
      '결제완료': '결제완료',
      '구매': '구매',
      '대기': '대기',
      '예정': '예정',
    },
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
    for (final c in [
      _title,
      _amount,
      _quantity,
      _vendor,
      _content,
      _subtasks,
      _subAssignee,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _direction() {
    if (_kind == 'finance') {
      return _financeIncomeSet.contains(_category) ? 'in' : 'out';
    }
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
      var saved = widget.record == null
          ? await widget.api.createOpsRecord(body)
          : await widget.api.updateOpsRecord(widget.record!.id, body);
      // 계획 신규 작성 시 입력한 체크리스트를 함께 생성.
      if (widget.record == null && _kind == 'plan') {
        final lines = _subtasks.text
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (lines.isNotEmpty) {
          final assignee = _subAssignee.text.trim();
          saved = await widget.api.addSubTasksBulk(
            saved.id,
            titles: lines,
            assignee: assignee.isEmpty ? null : assignee,
          );
        }
      }
      if (!mounted) return;
      Navigator.pop(context, saved);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('이 기록을 삭제할까요? (소프트삭제)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: context.mlColors.dangerColor,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      await widget.api.deleteOpsRecord(widget.record!.id);
      if (!mounted) return;
      Navigator.pop(context, false); // 호출자는 false=삭제됨
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
              style:
                  AppTypography.sectionTitle.copyWith(color: mlc.textPrimary),
            ),
            const SizedBox(height: AppSpacing.lg),
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
            _dropdown(
              '카테고리',
              _category,
              {for (final c in _catByKind[_kind]!) c: c},
              (v) => setState(() => _category = v),
            ),
            const SizedBox(height: AppSpacing.md),
            _field(isAsset ? '품명' : '제목', _title),
            if (isAsset) ...[
              const SizedBox(height: AppSpacing.md),
              _dropdown(
                '유형',
                _assetType ?? 'fixed',
                const {'fixed': '고정자산', 'consumable': '소모품'},
                (v) => setState(() => _assetType = v),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _field('수량', _quantity,
                        keyboard: TextInputType.number),
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
              _dropdown(
                '상태',
                _status,
                _statusByKind[_kind]!,
                (v) => setState(() => _status = v),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
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
            // 계획 신규 작성 — 체크리스트를 처음부터 구성.
            if (_kind == 'plan' && widget.record == null) ...[
              const SizedBox(height: AppSpacing.md),
              _field(
                '체크리스트(선택 · 줄바꿈으로 여러 개)',
                _subtasks,
                maxLines: 5,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '예) 로고 시안 3종 / App Store 스크린샷 / 약관 검토',
                style: AppTypography.label.copyWith(color: mlc.textTertiary),
              ),
              const SizedBox(height: AppSpacing.md),
              _field('공통 담당자(선택)', _subAssignee),
            ],
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
  }) =>
      TextField(
        controller: c,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      );

  Widget _dropdown(
    String label,
    String value,
    Map<String, String> items,
    ValueChanged<String> onChanged,
  ) =>
      InputDecorator(
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
                .map((e) =>
                    DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => v != null ? onChanged(v) : null,
          ),
        ),
      );
}
