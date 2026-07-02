import 'package:flutter/material.dart';

import '../../models/management_record.dart';
import '../../services/admin_api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// SubTask 항목 상세 시트.
/// 상태 5종 칩 + 사유(failed/blocked일 때 선택 입력) + 코멘트 스레드.
///  - 상태 칩 탭 → 즉시 PATCH. failed/blocked는 사유 다이얼로그 한 단계 거침.
///  - 코멘트 전송 → POST. 본인/Master 게이트는 서버가 보장.
///  - 코멘트 long-press → 삭제 확인.
///
/// 반환값: 변경된 [ManagementRecord] 또는 null(미변경).
Future<ManagementRecord?> showSubTaskDetailSheet(
  BuildContext context, {
  required AdminApiClient api,
  required int recordId,
  required SubTask subTask,
  required int index1Based,
}) {
  return showModalBottomSheet<ManagementRecord?>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => _SubTaskDetailSheet(
      api: api,
      recordId: recordId,
      initial: subTask,
      index1Based: index1Based,
    ),
  );
}

class _SubTaskDetailSheet extends StatefulWidget {
  const _SubTaskDetailSheet({
    required this.api,
    required this.recordId,
    required this.initial,
    required this.index1Based,
  });
  final AdminApiClient api;
  final int recordId;
  final SubTask initial;
  final int index1Based;

  @override
  State<_SubTaskDetailSheet> createState() => _SubTaskDetailSheetState();
}

class _SubTaskDetailSheetState extends State<_SubTaskDetailSheet> {
  late SubTask _t = widget.initial;
  ManagementRecord? _lastUpdated;
  bool _busy = false;
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _apply(ManagementRecord r) {
    final found = r.subTasks.firstWhere(
      (s) => s.id == _t.id,
      orElse: () => _t,
    );
    setState(() {
      _lastUpdated = r;
      _t = found;
    });
  }

  /// 상태 칩 탭. failed/blocked는 사유 다이얼로그를 한 번 거친다(취소 가능).
  Future<void> _changeStatus(SubTaskStatus next) async {
    if (next == _t.status) return;
    String? note;
    if (next == SubTaskStatus.failed || next == SubTaskStatus.blocked) {
      final entered = await _askReason(
        title: next == SubTaskStatus.failed ? '실패 사유(선택)' : '보류 사유(선택)',
        initial: _t.resolutionNote ?? '',
      );
      if (entered == null) return; // 다이얼로그 취소 = 상태 변경도 취소
      note = entered;
    } else {
      note = ''; // todo/inProgress/done 으로 가면 사유 클리어
    }
    setState(() => _busy = true);
    try {
      final r = await widget.api.patchSubTask(
        widget.recordId,
        _t.id,
        status: next,
        resolutionNote: note,
      );
      if (!mounted) return;
      _apply(r);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('상태 변경 실패: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askReason({
    required String title,
    required String initial,
  }) async {
    final c = TextEditingController(text: initial);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          maxLines: 3,
          minLines: 2,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '비워두고 확인 가능',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    final r = ok == true ? c.text.trim() : null;
    c.dispose();
    return r;
  }

  Future<void> _sendComment() async {
    final body = _input.text.trim();
    if (body.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final r = await widget.api
          .addSubTaskComment(widget.recordId, _t.id, body: body);
      if (!mounted) return;
      _input.clear();
      _apply(r);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('전송 실패: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteComment(SubTaskComment c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('코멘트 삭제'),
        content: const Text('이 코멘트를 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.mlColors.dangerColor,
            ),
            onPressed: () => Navigator.pop(dctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final r = await widget.api
          .deleteSubTaskComment(widget.recordId, _t.id, c.id);
      if (!mounted) return;
      _apply(r);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mlc = context.mlColors;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _lastUpdated != null) {
          // 부모로는 build 단계 reverse popInvoked 시 직접 전달 못함 → close 핸들러에서 pop(_lastUpdated)
        }
      },
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
          ),
          // 시트 본문 텍스트(제목·사유·코멘트 본문) 전부 long-press → 복사 가능.
          // 입력창 TextField는 자체 selection이 우선이라 영향 없음.
          child: SelectionArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(mlc),
                const SizedBox(height: AppSpacing.sm),
                _statusChips(mlc),
                if (_t.resolutionNote != null &&
                    _t.resolutionNote!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '사유: ${_t.resolutionNote}',
                    style: AppTypography.label
                        .copyWith(color: mlc.textSecondary),
                  ),
                ],
                const Divider(height: AppSpacing.lg * 2),
                Text(
                  '진행 현황 · ${_t.comments.length}',
                  style:
                      AppTypography.label.copyWith(color: mlc.textTertiary),
                ),
                const SizedBox(height: AppSpacing.xs),
                _commentList(mlc),
                const SizedBox(height: AppSpacing.sm),
                _commentInput(mlc),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(MarketLensColors mlc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Text(
            '${widget.index1Based}.',
            style: AppTypography.body.copyWith(
              color: mlc.textTertiary,
              fontWeight: AppTypography.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            _t.title,
            style: TextStyle(
              fontSize: AppTypography.headlineMedium,
              fontWeight: AppTypography.bold,
              color: mlc.textPrimary,
            ),
          ),
        ),
        IconButton(
          tooltip: '닫기',
          onPressed: () => Navigator.pop(context, _lastUpdated),
          icon: const Icon(Icons.close, size: 22),
        ),
      ],
    );
  }

  Widget _statusChips(MarketLensColors mlc) {
    final entries = <(SubTaskStatus, Color)>[
      (SubTaskStatus.todo, mlc.neutralColor),
      (SubTaskStatus.inProgress, mlc.accentBlue),
      (SubTaskStatus.done, mlc.gainColor),
      (SubTaskStatus.failed, mlc.dangerColor),
      (SubTaskStatus.blocked, mlc.warningColor),
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: entries.map((e) {
        final selected = _t.status == e.$1;
        return ChoiceChip(
          label: Text(e.$1.label),
          selected: selected,
          showCheckmark: false,
          onSelected: _busy ? null : (_) => _changeStatus(e.$1),
          labelStyle: TextStyle(
            fontSize: AppTypography.bodySmall,
            fontWeight: selected ? AppTypography.bold : AppTypography.regular,
            color: selected ? e.$2 : mlc.textSecondary,
          ),
          selectedColor: e.$2.withValues(alpha: 0.14),
          side: BorderSide(
            color: selected ? e.$2 : mlc.subtleBorder,
            width: selected ? 1.2 : 1,
          ),
        );
      }).toList(),
    );
  }

  Widget _commentList(MarketLensColors mlc) {
    if (_t.comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(
          '코멘트 없음 — 첫 진행 현황을 남겨보세요.',
          style: AppTypography.label.copyWith(color: mlc.textTertiary),
        ),
      );
    }
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.36,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _t.comments.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: mlc.subtleBorder.withValues(alpha: 0.4),
        ),
        itemBuilder: (_, i) {
          final c = _t.comments[i];
          return InkWell(
            onLongPress: _busy ? null : () => _deleteComment(c),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        c.byNickname ?? '—',
                        style: AppTypography.label.copyWith(
                          color: mlc.textPrimary,
                          fontWeight: AppTypography.semiBold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _shortIso(c.at),
                        style: AppTypography.label
                            .copyWith(color: mlc.textTertiary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.body,
                    style: TextStyle(
                      fontSize: AppTypography.bodyLarge,
                      color: mlc.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _commentInput(MarketLensColors mlc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _input,
            maxLines: 4,
            minLines: 1,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: '진행 현황 한 줄 입력…',
              border: const OutlineInputBorder(),
              isDense: true,
              hintStyle: TextStyle(color: mlc.textTertiary),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        FilledButton(
          onPressed: _busy ? null : _sendComment,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
          ),
          child: const Icon(Icons.send, size: 18),
        ),
      ],
    );
  }

  static String _shortIso(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final s = iso.replaceFirst('T', ' ');
    return s.length >= 16 ? s.substring(0, 16) : s;
  }
}
