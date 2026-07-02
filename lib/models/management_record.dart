// 경영·운영 관리 기록 (Master 전용). 서버 /admin/ops/* 와 1:1.

class ManagementRecord {
  final int id;
  final String kind; // finance | plan | note | asset
  final String category;
  final String title;
  final String? content;
  final double? amount;
  final String currency;
  final String? direction; // in | out
  final String? occurredOn; // YYYY-MM-DD
  final String? status;
  final String? assetNo;
  final String? assetType; // fixed | consumable
  final int? quantity;
  final String? vendor;
  final List<DisposalEntry> disposalHistory; // 자산 처분/상태변경 누적
  final List<SubTask> subTasks; // 계획 체크리스트
  final String? createdAt;
  final String? updatedAt;

  const ManagementRecord({
    required this.id,
    required this.kind,
    required this.category,
    required this.title,
    this.content,
    this.amount,
    this.currency = 'KRW',
    this.direction,
    this.occurredOn,
    this.status,
    this.assetNo,
    this.assetType,
    this.quantity,
    this.vendor,
    this.disposalHistory = const [],
    this.subTasks = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory ManagementRecord.fromJson(Map<String, dynamic> j) => ManagementRecord(
    id: (j['id'] as num).toInt(),
    kind: j['kind'] as String? ?? 'note',
    category: j['category'] as String? ?? '기타',
    title: j['title'] as String? ?? '',
    content: j['content'] as String?,
    amount: (j['amount'] as num?)?.toDouble(),
    currency: j['currency'] as String? ?? 'KRW',
    direction: j['direction'] as String?,
    occurredOn: (j['occurred_on'] as String?)?.split('T').first,
    status: j['status'] as String?,
    assetNo: j['asset_no'] as String?,
    assetType: j['asset_type'] as String?,
    quantity: (j['quantity'] as num?)?.toInt(),
    vendor: j['vendor'] as String?,
    disposalHistory: ((j['disposal_history'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DisposalEntry.fromJson)
        .toList(),
    subTasks: ((j['sub_tasks'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SubTask.fromJson)
        .toList(),
    createdAt: j['created_at'] as String?,
    updatedAt: j['updated_at'] as String?,
  );
}

/// 자산 처분/상태변경 이력 1건 (서버가 누적).
class DisposalEntry {
  final String kind; // disposed | unused | status_change
  final String? date; // YYYY-MM-DD
  final String? reason;
  final String? fromStatus;
  final String? toStatus;
  final int? byUserId;
  final String? byNickname;
  final String? byRole;
  final String? at; // ISO8601

  const DisposalEntry({
    required this.kind,
    this.date,
    this.reason,
    this.fromStatus,
    this.toStatus,
    this.byUserId,
    this.byNickname,
    this.byRole,
    this.at,
  });

  factory DisposalEntry.fromJson(Map<String, dynamic> j) => DisposalEntry(
    kind: j['kind'] as String? ?? 'disposed',
    date: j['date'] as String?,
    reason: j['reason'] as String?,
    fromStatus: j['from_status'] as String?,
    toStatus: j['to_status'] as String?,
    byUserId: (j['by_user_id'] as num?)?.toInt(),
    byNickname: j['by_nickname'] as String?,
    byRole: j['by_role'] as String?,
    at: j['at'] as String?,
  );
}

/// SubTask 상태 5종. 'todo'(대기) · 'in_progress'(진행중) · 'done'(완료)
/// · 'failed'(실패) · 'blocked'(보류/불가능).
enum SubTaskStatus { todo, inProgress, done, failed, blocked }

extension SubTaskStatusX on SubTaskStatus {
  String get wire {
    switch (this) {
      case SubTaskStatus.todo:
        return 'todo';
      case SubTaskStatus.inProgress:
        return 'in_progress';
      case SubTaskStatus.done:
        return 'done';
      case SubTaskStatus.failed:
        return 'failed';
      case SubTaskStatus.blocked:
        return 'blocked';
    }
  }

  String get label {
    switch (this) {
      case SubTaskStatus.todo:
        return '대기';
      case SubTaskStatus.inProgress:
        return '진행중';
      case SubTaskStatus.done:
        return '완료';
      case SubTaskStatus.failed:
        return '실패';
      case SubTaskStatus.blocked:
        return '보류';
    }
  }

  static SubTaskStatus parse(String? wire, {bool? legacyDone}) {
    switch (wire) {
      case 'todo':
        return SubTaskStatus.todo;
      case 'in_progress':
        return SubTaskStatus.inProgress;
      case 'done':
        return SubTaskStatus.done;
      case 'failed':
        return SubTaskStatus.failed;
      case 'blocked':
        return SubTaskStatus.blocked;
    }
    // 구버전(서버가 status 없이 done만 줄 때) 호환.
    return (legacyDone == true) ? SubTaskStatus.done : SubTaskStatus.todo;
  }
}

/// 계획 체크리스트 항목 (작성자·처리자 스냅샷 + 코멘트 스레드).
/// 서버 sub_tasks JSONB 항목 1건과 1:1.
///  - `done` 필드는 구버전 호환용. `status==done` 과 항상 동기.
///  - `resolutionNote`는 status=failed|blocked일 때 사유(선택).
///  - `comments`는 시간순 코멘트 리스트(스레드).
class SubTask {
  final int id;
  final String title;
  final SubTaskStatus status;
  final bool done; // legacy: status==done
  final String? assignee;
  final String? resolutionNote;
  final List<SubTaskComment> comments;
  final int? createdById;
  final String? createdByNickname;
  final String? createdByRole;
  final String? createdAt;
  final int? doneById;
  final String? doneByNickname;
  final String? doneByRole;
  final String? doneAt;

  const SubTask({
    required this.id,
    required this.title,
    required this.status,
    required this.done,
    this.assignee,
    this.resolutionNote,
    this.comments = const [],
    this.createdById,
    this.createdByNickname,
    this.createdByRole,
    this.createdAt,
    this.doneById,
    this.doneByNickname,
    this.doneByRole,
    this.doneAt,
  });

  factory SubTask.fromJson(Map<String, dynamic> j) {
    final legacyDone = j['done'] == true;
    final status = SubTaskStatusX.parse(
      j['status'] as String?,
      legacyDone: legacyDone,
    );
    return SubTask(
      id: (j['id'] as num?)?.toInt() ?? 0,
      title: j['title'] as String? ?? '',
      status: status,
      done: status == SubTaskStatus.done,
      assignee: j['assignee'] as String?,
      resolutionNote: j['resolution_note'] as String?,
      comments: ((j['comments'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SubTaskComment.fromJson)
          .toList(),
      createdById: (j['created_by_id'] as num?)?.toInt(),
      createdByNickname: j['created_by_nickname'] as String?,
      createdByRole: j['created_by_role'] as String?,
      createdAt: j['created_at'] as String?,
      doneById: (j['done_by_id'] as num?)?.toInt(),
      doneByNickname: j['done_by_nickname'] as String?,
      doneByRole: j['done_by_role'] as String?,
      doneAt: j['done_at'] as String?,
    );
  }
}

/// SubTask 코멘트 1건(진행 현황 스레드). 본인 또는 Master만 삭제 가능(서버 가드).
class SubTaskComment {
  final int id;
  final String body;
  final int? byUserId;
  final String? byNickname;
  final String? byRole;
  final String? at; // ISO8601

  const SubTaskComment({
    required this.id,
    required this.body,
    this.byUserId,
    this.byNickname,
    this.byRole,
    this.at,
  });

  factory SubTaskComment.fromJson(Map<String, dynamic> j) => SubTaskComment(
        id: (j['id'] as num?)?.toInt() ?? 0,
        body: j['body'] as String? ?? '',
        byUserId: (j['by_user_id'] as num?)?.toInt(),
        byNickname: j['by_nickname'] as String?,
        byRole: j['by_role'] as String?,
        at: j['at'] as String?,
      );
}

class OpsSummary {
  final String month;
  final double income, expense, dividend, net;
  const OpsSummary({
    required this.month,
    required this.income,
    required this.expense,
    required this.dividend,
    required this.net,
  });
  factory OpsSummary.fromJson(Map<String, dynamic> j) => OpsSummary(
    month: j['month'] as String? ?? '',
    income: (j['income'] as num?)?.toDouble() ?? 0,
    expense: (j['expense'] as num?)?.toDouble() ?? 0,
    dividend: (j['dividend'] as num?)?.toDouble() ?? 0,
    net: (j['net'] as num?)?.toDouble() ?? 0,
  );
}

class OpsMonthlyPoint {
  final String month; // YYYY-MM
  final double income, expense, dividend, net;
  const OpsMonthlyPoint({
    required this.month,
    required this.income,
    required this.expense,
    required this.dividend,
    required this.net,
  });
  factory OpsMonthlyPoint.fromJson(Map<String, dynamic> j) => OpsMonthlyPoint(
    month: j['month'] as String? ?? '',
    income: (j['income'] as num?)?.toDouble() ?? 0,
    expense: (j['expense'] as num?)?.toDouble() ?? 0,
    dividend: (j['dividend'] as num?)?.toDouble() ?? 0,
    net: (j['net'] as num?)?.toDouble() ?? 0,
  );
}

/// 카테고리별 합산 1건 (월별 P&L 세부).
class CategoryAmount {
  final String category;
  final double amount;
  final double share; // 0.0 ~ 1.0
  const CategoryAmount({
    required this.category,
    required this.amount,
    required this.share,
  });
  factory CategoryAmount.fromJson(Map<String, dynamic> j) => CategoryAmount(
    category: j['category'] as String? ?? '기타',
    amount: (j['amount'] as num?)?.toDouble() ?? 0,
    share: (j['share'] as num?)?.toDouble() ?? 0,
  );
}

/// 카테고리 집계 응답 (수익/지출 그룹).
class CategoryBreakdown {
  final String month; // YYYY-MM
  final List<CategoryAmount> income;
  final List<CategoryAmount> expense;
  final double dividend;
  const CategoryBreakdown({
    required this.month,
    required this.income,
    required this.expense,
    required this.dividend,
  });
  factory CategoryBreakdown.fromJson(Map<String, dynamic> j) => CategoryBreakdown(
    month: j['month'] as String? ?? '',
    income: ((j['income'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CategoryAmount.fromJson)
        .toList(),
    expense: ((j['expense'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CategoryAmount.fromJson)
        .toList(),
    dividend: (j['dividend'] as num?)?.toDouble() ?? 0,
  );
}

/// 사용자 권한 분포 통계 (관리자 패널 상단 카드).
class UserStats {
  final int total;
  final int master;
  final int manager;
  final int gold;
  final int regular;
  const UserStats({
    required this.total,
    required this.master,
    required this.manager,
    required this.gold,
    required this.regular,
  });
  factory UserStats.fromJson(Map<String, dynamic> j) => UserStats(
    total: (j['total'] as num?)?.toInt() ?? 0,
    master: (j['master'] as num?)?.toInt() ?? 0,
    manager: (j['manager'] as num?)?.toInt() ?? 0,
    gold: (j['gold'] as num?)?.toInt() ?? 0,
    regular: (j['regular'] as num?)?.toInt() ?? 0,
  );
}
