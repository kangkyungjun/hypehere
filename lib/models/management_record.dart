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
