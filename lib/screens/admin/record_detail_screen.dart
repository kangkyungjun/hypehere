import 'package:flutter/material.dart';

import '../../models/management_record.dart';
import '../../services/admin_api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/bento_card.dart';
import 'record_form_sheet.dart';
import 'subtask_detail_sheet.dart';

/// 기록 상세 (Master 전용).
/// kind별 hero 영역 + 라벨/값 리스트 + 종류별 보조 액션.
///  - finance/asset/plan/note 모두 공통 편집/삭제 액션
///  - asset: 처분/상태변경 이력 누적 + 처분 기록 버튼
///  - plan : 체크리스트 (추가/완료토글/삭제) + 작성자/처리자 스냅샷
///
/// pop 반환값:
///  - `true`  : 변경됨 (호출자 새로고침 필요)
///  - `false` : 삭제됨 (호출자 새로고침 + 토스트)
///  - `null`  : 변경 없음
class RecordDetailScreen extends StatefulWidget {
  const RecordDetailScreen({super.key, required this.record});
  final ManagementRecord record;

  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
  final AdminApiClient _api = AdminApiClient();
  late ManagementRecord _record = widget.record;
  bool _dirty = false;
  bool _busy = false;

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  void _replaceRecord(ManagementRecord r) {
    setState(() {
      _record = r;
      _dirty = true;
    });
  }

  /// 체크리스트 상태에 따라 plan 글의 status를 자동 동기화.
  ///  - 모든 항목 done(100%)       → '완료'
  ///  - done>0 또는 in_progress>0  → '진행중'
  ///  - 그 외(전부 todo, 또는 실패/보류만) → '계획'
  /// 실패·보류가 있어도 done이 100%가 아니면 '완료'로 가지 않는다(분자=done만).
  /// 단, 현재 status가 plan 라이프사이클(계획/진행중/완료) 또는 미지정인 경우에만 갱신.
  /// 사용자가 다른 커스텀 상태를 둔 경우는 건드리지 않는다.
  Future<void> _maybeSyncPlanStatus(ManagementRecord r) async {
    if (r.kind != 'plan' || r.subTasks.isEmpty) return;
    const lifecycle = {'계획', '진행중', '완료'};
    final cur = r.status ?? '';
    if (cur.isNotEmpty && !lifecycle.contains(cur)) return;
    final total = r.subTasks.length;
    final done = r.subTasks.where((t) => t.status == SubTaskStatus.done).length;
    final inProg = r.subTasks
        .where((t) => t.status == SubTaskStatus.inProgress)
        .length;
    final next = done == total
        ? '완료'
        : ((done > 0 || inProg > 0) ? '진행중' : '계획');
    if (cur == next) return;
    try {
      final updated = await _api.updateOpsRecord(r.id, {'status': next});
      if (!mounted) return;
      _replaceRecord(updated);
    } catch (_) {
      // 자동 동기화 실패는 조용히 무시 — 다음 변경에서 재시도.
    }
  }

  Future<void> _onEdit() async {
    final result =
        await showRecordFormSheet(context, api: _api, record: _record);
    if (!mounted) return;
    if (result is ManagementRecord) {
      _replaceRecord(result);
    } else if (result == false) {
      // 폼에서 삭제됨
      Navigator.pop(context, false);
    }
  }

  Future<void> _onDelete() async {
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
    setState(() => _busy = true);
    try {
      await _api.deleteOpsRecord(_record.id);
      if (!mounted) return;
      Navigator.pop(context, false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
    }
  }

  Future<void> _onAddDisposal() async {
    final result = await showDialog<_DisposalDialogResult>(
      context: context,
      builder: (_) => const _DisposalDialog(),
    );
    if (result == null || !mounted) return;
    try {
      final updated = await _api.addAssetDisposal(
        _record.id,
        kind: result.kind,
        reason: result.reason,
        toStatus: result.toStatus,
      );
      _replaceRecord(updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('처분 기록 실패: $e')));
    }
  }

  Future<void> _onAddSubTask() async {
    final result = await showDialog<_SubTaskDialogResult>(
      context: context,
      builder: (_) => const _SubTaskDialog(),
    );
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final updated = await _api.addSubTasksBulk(
        _record.id,
        titles: result.titles,
        assignee: result.assignee,
      );
      if (!mounted) return;
      _replaceRecord(updated);
      await _maybeSyncPlanStatus(updated);
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.titles.length}개 항목 추가')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('항목 추가 실패: $e')));
    }
  }

  /// 항목 탭 → 상세 시트(상태 변경·코멘트). 시트가 반환한 record로 갱신.
  Future<void> _onOpenSubTaskDetail(SubTask t, int index1Based) async {
    final updated = await showSubTaskDetailSheet(
      context,
      api: _api,
      recordId: _record.id,
      subTask: t,
      index1Based: index1Based,
    );
    if (!mounted || updated == null) return;
    _replaceRecord(updated);
    await _maybeSyncPlanStatus(updated);
  }

  /// 드래그 후 새 순서로 reorder API 호출. 낙관적 UI는 안 함(작아서 round-trip 충분).
  Future<void> _onReorderSubTasks(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;
    final items = [..._record.subTasks];
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    final ids = items.map((s) => s.id).toList();
    try {
      final updated = await _api.reorderSubTasks(
        _record.id,
        orderedIds: ids,
      );
      if (!mounted) return;
      _replaceRecord(updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('순서 변경 실패: $e')));
    }
  }

  Future<void> _onDeleteSubTask(SubTask t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('항목 삭제'),
        content: Text('"${t.title}" 항목을 삭제할까요?'),
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
    try {
      final updated = await _api.deleteSubTask(_record.id, t.id);
      _replaceRecord(updated);
      await _maybeSyncPlanStatus(updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _dirty && result == null) {
          // 시스템 백 제스처로 닫혔을 때 부모에 dirty 알림
          // (이미 pop 됐으므로 별도 처리는 부모가 onRefresh로 보강)
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('기록 상세'),
          actions: [
            IconButton(
              tooltip: '닫기',
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context, _dirty ? true : null),
            ),
          ],
        ),
        // SelectionArea — long-press 또는 드래그로 모든 텍스트 선택·복사 가능.
        // 탭/리스트 reorder/IconButton 등 기존 인터랙션은 그대로 동작.
        body: SelectionArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            children: [
            _buildHero(),
            const SizedBox(height: AppSpacing.md),
            _buildInfoCard(),
            if (_record.content != null && _record.content!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _buildContentCard(),
            ],
            if (_record.kind == 'asset') ...[
              const SizedBox(height: AppSpacing.md),
              _buildDisposalCard(),
            ],
            if (_record.kind == 'plan') ...[
              const SizedBox(height: AppSpacing.md),
              _buildSubTaskCard(),
            ],
            const SizedBox(height: AppSpacing.xl),
            _buildActions(),
          ],
        ),
        ),
      ),
    );
  }

  // ── Hero (종류별 핵심 지표) ──
  Widget _buildHero() {
    final mlc = context.mlColors;
    final theme = _kindTheme(_record.kind, mlc);

    Widget heroBody;
    switch (_record.kind) {
      case 'finance':
        final amt = _record.amount;
        final isIn = _record.direction == 'in';
        heroBody = Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 방향성(수익/지출) 히어로 금액 — 녹/적 유지, 큰 값은 scaleDown 방어.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                amt == null ? '—' : '${isIn ? '+' : '-'}${_won(amt)}',
                maxLines: 1,
                style: TextStyle(
                  fontSize: AppTypography.displaySmall,
                  fontWeight: AppTypography.bold,
                  fontFeatures: AppTypography.tabularFigures,
                  color: isIn ? mlc.gainColor : mlc.lossColor,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_record.category} · ${_record.status ?? '미지정'}',
              style: TextStyle(
                fontSize: AppTypography.bodySmall,
                color: mlc.textSecondary,
              ),
            ),
          ],
        );
        break;
      case 'asset':
        heroBody = Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '등록번호',
                    style: AppTypography.kvLabel.copyWith(
                      color: mlc.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _record.assetNo ?? '—',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: AppTypography.headlineMedium,
                        fontWeight: AppTypography.bold,
                        fontFeatures: AppTypography.tabularFigures,
                        color: mlc.accentBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _record.amount == null
                        ? '취득가 —'
                        : '취득가 ${_won(_record.amount!)}',
                    style: TextStyle(
                      fontSize: AppTypography.bodySmall,
                      color: mlc.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            _statusChip(_record.status, theme.color, mlc),
          ],
        );
        break;
      case 'plan':
        final tasks = _record.subTasks;
        final doneCount = tasks.where((t) => t.done).length;
        final ratio = tasks.isEmpty ? 0.0 : doneCount / tasks.length;
        heroBody = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _statusChip(_record.status, theme.color, mlc),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _dDay(_record.occurredOn),
                  style: TextStyle(
                    fontSize: AppTypography.bodySmall,
                    fontWeight: AppTypography.semiBold,
                    color: mlc.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(ratio * 100).round()}%',
                  style: TextStyle(
                    fontSize: AppTypography.bodyLarge,
                    fontWeight: AppTypography.bold,
                    color: mlc.textPrimary,
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
                valueColor: AlwaysStoppedAnimation(theme.color),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              tasks.isEmpty
                  ? '체크리스트 없음'
                  : '$doneCount / ${tasks.length} 완료',
              style: TextStyle(
                fontSize: AppTypography.bodySmall,
                color: mlc.textSecondary,
              ),
            ),
          ],
        );
        break;
      case 'note':
      default:
        heroBody = Row(
          children: [
            Icon(Icons.sticky_note_2_outlined, color: theme.color, size: 28),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _record.category,
                style: TextStyle(
                  fontSize: AppTypography.headlineMedium,
                  fontWeight: AppTypography.semiBold,
                  color: mlc.textPrimary,
                ),
              ),
            ),
          ],
        );
        break;
    }

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: theme.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.badge),
                ),
                child: Text(
                  theme.label,
                  style: TextStyle(
                    fontSize: AppTypography.micro,
                    fontWeight: AppTypography.bold,
                    color: theme.color,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _record.title,
                  style: TextStyle(
                    fontSize: AppTypography.headlineMedium,
                    fontWeight: AppTypography.bold,
                    color: mlc.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          heroBody,
        ],
      ),
    );
  }

  // ── 정보 카드 (라벨/값 리스트) ──
  Widget _buildInfoCard() {
    final r = _record;
    final rows = <(String, String)>[];
    rows.add(('카테고리', r.category));
    if (r.occurredOn != null) rows.add(('발생일자', r.occurredOn!));
    if (r.status != null && r.status!.isNotEmpty) rows.add(('상태', r.status!));
    if (r.kind == 'asset') {
      rows.add(('유형', r.assetType == 'consumable' ? '소모품' : '고정자산'));
      if (r.quantity != null) rows.add(('수량', '${r.quantity}'));
      if (r.vendor != null && r.vendor!.isNotEmpty) {
        rows.add(('구매처', r.vendor!));
      }
    }
    if ((r.kind == 'finance' || r.kind == 'asset') && r.amount != null) {
      rows.add((
        r.kind == 'asset' ? '취득가' : '금액',
        '${r.direction == 'in' ? '+' : '-'}${_won(r.amount!)}',
      ));
    }
    if (r.createdAt != null) rows.add(('등록일', _shortIso(r.createdAt!)));
    if (r.updatedAt != null && r.updatedAt != r.createdAt) {
      rows.add(('최종수정', _shortIso(r.updatedAt!)));
    }

    return BentoCard(
      child: Column(
        children: rows
            .map((row) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _kv(row.$1, row.$2),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildContentCard() {
    final mlc = context.mlColors;
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '메모',
            style: AppTypography.label.copyWith(color: mlc.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _record.content ?? '',
            style: TextStyle(
              fontSize: AppTypography.bodyLarge,
              color: mlc.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── 자산: 처분/상태변경 이력 ──
  Widget _buildDisposalCard() {
    final mlc = context.mlColors;
    final history = _record.disposalHistory;
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '처분 / 상태 이력',
                style:
                    AppTypography.cardTitle.copyWith(color: mlc.textPrimary),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _busy ? null : _onAddDisposal,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('처분 기록'),
              ),
            ],
          ),
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                '이력 없음',
                style: TextStyle(
                  fontSize: AppTypography.bodySmall,
                  color: mlc.textTertiary,
                ),
              ),
            )
          else
            ...history.reversed.map((e) => _disposalRow(e, mlc)),
        ],
      ),
    );
  }

  Widget _disposalRow(DisposalEntry e, MarketLensColors mlc) {
    final tone = (e.toStatus == '폐기' || e.kind == 'disposed')
        ? mlc.dangerColor
        : (e.toStatus == '불용' || e.kind == 'unused')
            ? mlc.warningColor
            : mlc.textSecondary;
    final kindLabel = _disposalKindLabel(e);
    final by = (e.byNickname?.isNotEmpty == true)
        ? '${e.byNickname}${e.byRole != null ? '(${_roleLabel(e.byRole!)})' : ''}'
        : '—';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: AppSpacing.sm),
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${e.date ?? '—'}  ·  $kindLabel',
                  style: TextStyle(
                    fontSize: AppTypography.bodySmall,
                    fontWeight: AppTypography.semiBold,
                    color: mlc.textPrimary,
                  ),
                ),
                if ((e.reason ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    e.reason!,
                    style: TextStyle(
                      fontSize: AppTypography.bodySmall,
                      color: mlc.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  'by $by',
                  style: TextStyle(
                    fontSize: AppTypography.micro,
                    color: mlc.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _disposalKindLabel(DisposalEntry e) {
    if (e.kind == 'disposed') return '폐기';
    if (e.kind == 'unused') return '불용 처분';
    if (e.kind == 'status_change') {
      return '상태변경 ${e.fromStatus ?? '—'} → ${e.toStatus ?? '—'}';
    }
    return e.kind;
  }

  // ── 계획: 체크리스트(번호·상태칩·코멘트 배지·드래그 reorder) ──
  Widget _buildSubTaskCard() {
    final mlc = context.mlColors;
    final tasks = _record.subTasks;
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '체크리스트',
                style:
                    AppTypography.cardTitle.copyWith(color: mlc.textPrimary),
              ),
              const SizedBox(width: 6),
              if (tasks.isNotEmpty) _progressMini(tasks, mlc),
              const Spacer(),
              TextButton.icon(
                onPressed: _busy ? null : _onAddSubTask,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('항목'),
              ),
            ],
          ),
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                '항목 없음',
                style: TextStyle(
                  fontSize: AppTypography.bodySmall,
                  color: mlc.textTertiary,
                ),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: tasks.length,
              onReorder: (oldI, newI) => _onReorderSubTasks(oldI, newI),
              itemBuilder: (_, i) => _subTaskRow(tasks[i], i, mlc),
            ),
        ],
      ),
    );
  }

  Widget _progressMini(List<SubTask> tasks, MarketLensColors mlc) {
    final total = tasks.length;
    final done = tasks.where((t) => t.status == SubTaskStatus.done).length;
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

  Widget _subTaskRow(SubTask t, int idx, MarketLensColors mlc) {
    final assignee = (t.assignee?.isNotEmpty == true) ? t.assignee! : '미지정';
    final commentCount = t.comments.length;
    final stColor = _statusColor(t.status, mlc);
    final isClosed = t.status == SubTaskStatus.done ||
        t.status == SubTaskStatus.failed ||
        t.status == SubTaskStatus.blocked;
    return Container(
      key: ValueKey('subtask-${t.id}'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: InkWell(
        onTap: _busy ? null : () => _onOpenSubTaskDetail(t, idx + 1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 번호
            SizedBox(
              width: 26,
              child: Text(
                '${idx + 1}.',
                textAlign: TextAlign.center,
                style: AppTypography.label.copyWith(
                  color: mlc.textTertiary,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ),
            // 상태 칩
            Container(
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: stColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.badge),
              ),
              child: Text(
                t.status.label,
                style: TextStyle(
                  fontSize: AppTypography.micro,
                  fontWeight: AppTypography.bold,
                  color: stColor,
                ),
              ),
            ),
            // 제목 + 메타
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    style: TextStyle(
                      fontSize: AppTypography.bodyLarge,
                      color: mlc.textPrimary,
                      fontWeight: AppTypography.semiBold,
                      decoration:
                          isClosed ? TextDecoration.lineThrough : null,
                      decorationColor: mlc.textTertiary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '담당 $assignee${commentCount > 0 ? '  ·  💬 $commentCount' : ''}',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      color: mlc.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 메뉴 (삭제만 빠른 진입)
            IconButton(
              tooltip: '삭제',
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              onPressed: _busy ? null : () => _onDeleteSubTask(t),
              icon: Icon(Icons.delete_outline, color: mlc.textTertiary),
            ),
            // 드래그 핸들 — ReorderableListView가 이 child를 키로 인식하기 위해
            ReorderableDragStartListener(
              index: idx,
              child: Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Icon(Icons.drag_handle,
                    size: 18, color: mlc.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(SubTaskStatus s, MarketLensColors mlc) {
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

  // ── 하단 액션 (수정/삭제) ──
  Widget _buildActions() {
    final mlc = context.mlColors;
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _busy ? null : _onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('수정'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _onDelete,
            icon: Icon(Icons.delete_outline, size: 18, color: mlc.dangerColor),
            label: Text('삭제', style: TextStyle(color: mlc.dangerColor)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: mlc.dangerColor),
            ),
          ),
        ),
      ],
    );
  }

  // ── 작은 위젯들 ──
  Widget _kv(String k, String v) {
    final mlc = context.mlColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            k,
            style: TextStyle(
              fontSize: AppTypography.bodySmall,
              color: mlc.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            v,
            style: TextStyle(
              fontSize: AppTypography.bodyLarge,
              color: mlc.textPrimary,
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String? status, Color color, MarketLensColors mlc) {
    final text = (status == null || status.isEmpty) ? '미지정' : status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppTypography.bodySmall,
          fontWeight: AppTypography.bold,
          color: color,
        ),
      ),
    );
  }

  ({String label, Color color}) _kindTheme(String kind, MarketLensColors mlc) {
    switch (kind) {
      case 'finance':
        return (label: '재무', color: mlc.accentBlue);
      case 'asset':
        return (label: '자산', color: mlc.eventConferenceColor);
      case 'plan':
        return (label: '계획', color: mlc.warningColor);
      case 'note':
      default:
        return (label: '메모', color: mlc.neutralColor);
    }
  }

  String _roleLabel(String r) {
    switch (r) {
      case 'master':
        return 'Master';
      case 'manager':
        return 'Manager';
      case 'gold':
        return 'Gold';
      case 'regular':
        return 'Regular';
      default:
        return r;
    }
  }

  String _won(double v) {
    final neg = v < 0;
    final s = v.abs().round().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return '${neg ? '-' : ''}₩$b';
  }

  String _shortIso(String iso) {
    // 2026-06-15T14:22:01 → 2026-06-15 14:22
    final s = iso.replaceFirst('T', ' ');
    return s.length >= 16 ? s.substring(0, 16) : s;
  }

  /// 발생일(=목표일) 기준 D-Day. 과거면 D+, 오늘이면 D-Day.
  String _dDay(String? ymd) {
    if (ymd == null) return '';
    final t = DateTime.tryParse(ymd);
    if (t == null) return '';
    final today = DateTime.now();
    final t0 = DateTime(t.year, t.month, t.day);
    final today0 = DateTime(today.year, today.month, today.day);
    final diff = t0.difference(today0).inDays;
    if (diff == 0) return 'D-Day';
    if (diff > 0) return 'D-$diff';
    return 'D+${-diff}';
  }
}

// ── 처분 기록 다이얼로그 ──

class _DisposalDialogResult {
  final String kind;
  final String? reason;
  final String? toStatus;
  _DisposalDialogResult({required this.kind, this.reason, this.toStatus});
}

class _DisposalDialog extends StatefulWidget {
  const _DisposalDialog();
  @override
  State<_DisposalDialog> createState() => _DisposalDialogState();
}

class _DisposalDialogState extends State<_DisposalDialog> {
  String _kind = 'disposed'; // disposed | unused | status_change
  String _statusTo = '폐기';
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  static const _statusByKind = {
    'disposed': ['폐기'],
    'unused': ['불용'],
    'status_change': ['사용중', '대기', '폐기', '불용'],
  };

  @override
  Widget build(BuildContext context) {
    final statuses = _statusByKind[_kind]!;
    if (!statuses.contains(_statusTo)) _statusTo = statuses.first;
    return AlertDialog(
      title: const Text('처분 기록'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _kind,
              decoration: const InputDecoration(
                labelText: '종류',
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'disposed', child: Text('폐기')),
                DropdownMenuItem(value: 'unused', child: Text('불용 처분')),
                DropdownMenuItem(
                    value: 'status_change', child: Text('상태 변경만')),
              ],
              onChanged: (v) => setState(() {
                _kind = v ?? 'disposed';
                _statusTo = _statusByKind[_kind]!.first;
              }),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _statusTo,
              decoration: const InputDecoration(
                labelText: '변경할 상태',
                isDense: true,
              ),
              items: statuses
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _statusTo = v ?? statuses.first),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _reason,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '사유(선택)',
                hintText: '예: 배터리 스웰링, A/S 만료',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _DisposalDialogResult(
              kind: _kind,
              reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
              toStatus: _statusTo,
            ),
          ),
          child: const Text('기록'),
        ),
      ],
    );
  }
}

// ── 체크리스트 항목 추가 다이얼로그 (여러 줄 = 여러 항목) ──

class _SubTaskDialogResult {
  final List<String> titles;
  final String? assignee;
  _SubTaskDialogResult({required this.titles, this.assignee});
}

class _SubTaskDialog extends StatefulWidget {
  const _SubTaskDialog();
  @override
  State<_SubTaskDialog> createState() => _SubTaskDialogState();
}

class _SubTaskDialogState extends State<_SubTaskDialog> {
  final _titles = TextEditingController();
  final _assignee = TextEditingController();

  @override
  void dispose() {
    _titles.dispose();
    _assignee.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('체크리스트 추가'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titles,
              autofocus: true,
              maxLines: 6,
              minLines: 3,
              decoration: const InputDecoration(
                labelText: '항목(줄바꿈으로 여러 개)',
                hintText: '예)\n로고 시안 3종\nApp Store 스크린샷\n약관 검토',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _assignee,
              decoration: const InputDecoration(
                labelText: '공통 담당자(선택)',
                hintText: '닉네임 — 모든 항목에 동일하게 적용',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            final lines = _titles.text
                .split('\n')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
            if (lines.isEmpty) return;
            Navigator.pop(
              context,
              _SubTaskDialogResult(
                titles: lines,
                assignee: _assignee.text.trim().isEmpty
                    ? null
                    : _assignee.text.trim(),
              ),
            );
          },
          child: const Text('추가'),
        ),
      ],
    );
  }
}
