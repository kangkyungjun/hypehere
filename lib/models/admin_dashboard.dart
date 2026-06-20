// 어드민 대시보드(Master 전용) 응답 모델.
// GET /api/v1/admin/dashboard/summary, /users 와 1:1.

class AdminUsers {
  final int total, android, ios, newToday;
  final int dau, dauAndroid, dauIos;
  final int wau, wauAndroid, wauIos;
  final int mau;
  final double stickiness;

  const AdminUsers({
    required this.total,
    required this.android,
    required this.ios,
    required this.newToday,
    required this.dau,
    required this.dauAndroid,
    required this.dauIos,
    required this.wau,
    required this.wauAndroid,
    required this.wauIos,
    required this.mau,
    required this.stickiness,
  });

  factory AdminUsers.fromJson(Map<String, dynamic> j) => AdminUsers(
    total: (j['total'] as num?)?.toInt() ?? 0,
    android: (j['android'] as num?)?.toInt() ?? 0,
    ios: (j['ios'] as num?)?.toInt() ?? 0,
    newToday: (j['new_today'] as num?)?.toInt() ?? 0,
    dau: (j['dau'] as num?)?.toInt() ?? 0,
    dauAndroid: (j['dau_android'] as num?)?.toInt() ?? 0,
    dauIos: (j['dau_ios'] as num?)?.toInt() ?? 0,
    wau: (j['wau'] as num?)?.toInt() ?? 0,
    wauAndroid: (j['wau_android'] as num?)?.toInt() ?? 0,
    wauIos: (j['wau_ios'] as num?)?.toInt() ?? 0,
    mau: (j['mau'] as num?)?.toInt() ?? 0,
    stickiness: (j['stickiness'] as num?)?.toDouble() ?? 0.0,
  );
}

class AdminDownloads {
  final int total, android, ios, today;
  const AdminDownloads({
    required this.total,
    required this.android,
    required this.ios,
    required this.today,
  });
  factory AdminDownloads.fromJson(Map<String, dynamic> j) => AdminDownloads(
    total: (j['total'] as num?)?.toInt() ?? 0,
    android: (j['android'] as num?)?.toInt() ?? 0,
    ios: (j['ios'] as num?)?.toInt() ?? 0,
    today: (j['today'] as num?)?.toInt() ?? 0,
  );
}

class AdminAdmob {
  final double revenueTodayUsd, ecpm, revenueMtdUsd;
  final int impressionsToday;
  const AdminAdmob({
    required this.revenueTodayUsd,
    required this.ecpm,
    required this.revenueMtdUsd,
    required this.impressionsToday,
  });
  factory AdminAdmob.fromJson(Map<String, dynamic> j) => AdminAdmob(
    revenueTodayUsd: (j['revenue_today_usd'] as num?)?.toDouble() ?? 0.0,
    ecpm: (j['ecpm'] as num?)?.toDouble() ?? 0.0,
    revenueMtdUsd: (j['revenue_mtd_usd'] as num?)?.toDouble() ?? 0.0,
    impressionsToday: (j['impressions_today'] as num?)?.toInt() ?? 0,
  );
}

class AdminSummary {
  final String asOf;
  final AdminUsers users;
  final AdminDownloads downloads;
  final AdminAdmob admob;

  const AdminSummary({
    required this.asOf,
    required this.users,
    required this.downloads,
    required this.admob,
  });

  factory AdminSummary.fromJson(Map<String, dynamic> j) => AdminSummary(
    asOf: j['as_of'] as String? ?? '',
    users: AdminUsers.fromJson((j['users'] as Map?)?.cast() ?? const {}),
    downloads: AdminDownloads.fromJson(
      (j['downloads'] as Map?)?.cast() ?? const {},
    ),
    admob: AdminAdmob.fromJson((j['admob'] as Map?)?.cast() ?? const {}),
  );
}

/// /users 시계열 한 점.
class AdminUserPoint {
  final String date;
  final int dau, dauAndroid, dauIos, wau, wauAndroid, wauIos, mau, newUsers;
  final double stickiness;

  const AdminUserPoint({
    required this.date,
    required this.dau,
    required this.dauAndroid,
    required this.dauIos,
    required this.wau,
    required this.wauAndroid,
    required this.wauIos,
    required this.mau,
    required this.newUsers,
    required this.stickiness,
  });

  factory AdminUserPoint.fromJson(Map<String, dynamic> j) => AdminUserPoint(
    date: j['date'] as String? ?? '',
    dau: (j['dau'] as num?)?.toInt() ?? 0,
    dauAndroid: (j['dau_android'] as num?)?.toInt() ?? 0,
    dauIos: (j['dau_ios'] as num?)?.toInt() ?? 0,
    wau: (j['wau'] as num?)?.toInt() ?? 0,
    wauAndroid: (j['wau_android'] as num?)?.toInt() ?? 0,
    wauIos: (j['wau_ios'] as num?)?.toInt() ?? 0,
    mau: (j['mau'] as num?)?.toInt() ?? 0,
    newUsers: (j['new_users'] as num?)?.toInt() ?? 0,
    stickiness: (j['stickiness'] as num?)?.toDouble() ?? 0.0,
  );
}
