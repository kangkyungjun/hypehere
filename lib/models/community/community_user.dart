import '../../l10n/app_localizations.dart';

class CommunityUser {
  final int id;
  final String email;
  final String nickname;
  final DateTime createdAt;

  // 추가 프로필 필드 (백엔드 모델과 일치)
  final String? profilePicture;
  final String? bio;
  final List<String>? watchlistTickers;

  // MarketLens 권한 시스템
  final String role; // 'master', 'manager', 'gold', 'regular'

  // 이메일 인증 여부
  final bool isEmailVerified;

  // IAP 결제 Gold 여부 (관리자 구분용)
  final bool isIapGold;

  // 무료 체험 사용 이력 (악용 방지용)
  final bool hasUsedTrial;

  CommunityUser({
    required this.id,
    required this.email,
    required this.nickname,
    required this.createdAt,
    this.profilePicture,
    this.bio,
    this.watchlistTickers,
    this.role = 'regular', // 기본값: 일반 회원
    this.isEmailVerified = false,
    this.isIapGold = false,
    this.hasUsedTrial = false,
  });

  factory CommunityUser.fromJson(Map<String, dynamic> json) {
    return CommunityUser(
      id: json['id'] as int,
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      profilePicture: json['profile_picture'] as String?,
      bio: json['bio'] as String?,
      watchlistTickers: json['watchlist_tickers'] != null
          ? List<String>.from(json['watchlist_tickers'] as List)
          : null,
      role: json['role'] as String? ?? 'regular', // 기본값: regular
      isEmailVerified: json['is_email_verified'] as bool? ?? false,
      isIapGold: json['is_iap_gold'] as bool? ?? false,
      hasUsedTrial: json['has_used_trial'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'created_at': createdAt.toIso8601String(),
      'profile_picture': profilePicture,
      'bio': bio,
      'watchlist_tickers': watchlistTickers,
      'role': role,
      'is_email_verified': isEmailVerified,
    };
  }

  // ========================================
  // MarketLens 권한 체크 메서드
  // ========================================

  /// Master 권한 체크 (오너)
  bool get isMaster => role == 'master';

  /// Manager 이상 권한 체크 (Manager, Master)
  bool get isManagerOrAbove => role == 'master' || role == 'manager';

  /// Gold 이상 권한 체크 (Gold, Manager, Master)
  bool get isGoldOrAbove => role == 'master' || role == 'manager' || role == 'gold';

  /// 광고 제거 권한 (Gold 이상)
  bool get hasAdFreeAccess => isGoldOrAbove;

  /// 모든 게시글 삭제 권한 (Manager 이상)
  bool get canDeleteAnyPost => isManagerOrAbove;

  /// Gold로 승급 권한 (Manager 이상)
  bool get canPromoteToGold => isManagerOrAbove;

  /// Manager로 승급 권한 (Master만)
  bool get canPromoteToManager => isMaster;

  /// 사용자 관리 권한 (Manager 이상)
  bool get canManageUsers => isManagerOrAbove;

  /// 역할 표시 이름 (한글)
  String get roleDisplayName {
    switch (role) {
      case 'master':
        return 'Master';
      case 'manager':
        return 'Manager';
      case 'gold':
        return 'Gold';
      case 'regular':
      default:
        return 'Regular';
    }
  }

  /// Localized role display name
  String roleDisplayNameLocalized(AppLocalizations l10n) {
    switch (role) {
      case 'master':
        return l10n.roleMaster;
      case 'manager':
        return l10n.roleManager;
      case 'gold':
        return l10n.roleGold;
      case 'regular':
        return l10n.roleRegular;
      default:
        return l10n.roleGuest;
    }
  }
}
