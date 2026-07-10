import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

/// 버전 인식형 업데이트 알림 쿨다운을 적용한 [Upgrader].
///
/// ## 왜 필요한가
/// 기본 `upgrader 13.x`의 재알림 억제(`isTooSoon`)는 **순수 시간 기반**이라
/// 버전을 구분하지 않는다. 그래서:
///   - (거짓 음성) 한 번 알림 뜬 뒤 `durationUntilAlertAgain`(예: 3일) 안에
///     **더 새로운 버전**이 나와도 알림이 안 뜬다. 릴리스가 잦으면 새 버전이
///     이 그림자에 자주 걸려 "새 버전 나왔는데 알림 안 옴"이 된다.
///
/// 이전엔 `UpdatePromptCooldown` 위젯이 쿨다운 안에서는 `UpgradeAlert`를
/// 위젯 트리에서 아예 제거했는데, 그러면 upgrader가 스토어 버전 조회조차 못 해
/// 위 거짓 음성을 오히려 악화시켰다.
///
/// ## 이 클래스의 동작
/// [isTooSoon]을 오버라이드해 **버전 인식형**으로 만든다:
///   - 마지막으로 알린 스토어 버전과 **다른(새) 버전**이면 → 시간과 무관하게 즉시 알림.
///   - **같은 버전**이면 → [cooldown] 동안만 억제(다이얼로그를 어떤 방식으로 닫았든).
///   - 이미 최신( 설치 ≥ 스토어 )이면 upgrader가 `isUpdateAvailable()==false`로
///     애초에 안 띄우므로 업데이트 완료자는 재알림되지 않는다.
///
/// 표시 시각/버전 기록은 [saveLastAlerted]에서 한다. upgrader는 다이얼로그가
/// **표시되는 순간**(버튼 선택 이전) 이 메서드를 호출하므로, "나중에"뿐 아니라
/// X·바깥 탭·뒤로가기 등 **모든 닫힘 방식**에서 쿨다운이 일관되게 기록된다.
class VersionAwareUpgrader extends Upgrader {
  VersionAwareUpgrader({
    super.messages,
    super.debugLogging,
    Duration cooldown = const Duration(days: 3),
  })  : _cooldown = cooldown,
        super(durationUntilAlertAgain: cooldown);

  final Duration _cooldown;

  static const String _kPromptedVersion = 'update_prompted_store_version';
  static const String _kPromptedMs = 'update_prompted_ms';

  /// 마지막으로 알림을 표시한 스토어 버전 문자열(예: "1.3.12").
  String? _promptedVersion;

  /// 마지막으로 알림을 표시한 시각.
  DateTime? _promptedAt;

  @override
  Future<bool> initialize() async {
    final ok = await super.initialize();
    final prefs = await SharedPreferences.getInstance();
    _promptedVersion = prefs.getString(_kPromptedVersion);
    final ms = prefs.getInt(_kPromptedMs);
    _promptedAt = ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
    return ok;
  }

  /// 버전 인식형 재알림 억제.
  ///
  /// upgrader는 이미 [Upgrader.isUpdateAvailable]로 "설치 < 스토어"를 확인한 뒤
  /// 이 메서드를 참조하므로, 여기서는 "이 스토어 버전을 최근에 알렸는지"만 본다.
  @override
  bool isTooSoon() {
    final store = versionInfo?.appStoreVersion?.toString();
    // 스토어 버전을 아직 모르면 upgrader 기본(시간) 판단에 맡긴다.
    if (store == null) return super.isTooSoon();
    return isTooSoonForVersion(
      storeVersion: store,
      promptedVersion: _promptedVersion,
      promptedAt: _promptedAt,
      cooldown: _cooldown,
      now: DateTime.now(),
    );
  }

  /// 버전 인식 재알림 억제의 순수 판단 로직(테스트 용이하도록 분리).
  ///
  /// 반환값 true = "너무 이르다(억제)", false = "알림 표시 허용".
  /// 전제: 호출 시점엔 이미 "설치 < 스토어"(업데이트 있음)가 성립.
  static bool isTooSoonForVersion({
    required String storeVersion,
    required String? promptedVersion,
    required DateTime? promptedAt,
    required Duration cooldown,
    required DateTime now,
  }) {
    // 마지막으로 알린 버전과 다르면(=새 릴리스) 절대 too soon 아님 → 즉시 알림.
    if (promptedVersion == null || storeVersion != promptedVersion) return false;
    // 같은 버전이면 쿨다운 시간 동안만 억제.
    if (promptedAt == null) return false;
    return now.difference(promptedAt) < cooldown;
  }

  /// 다이얼로그가 표시되는 순간 호출(모든 닫힘 방식 포함). upgrader의 기본 시간
  /// 기록을 유지하면서, 버전 인식용 상태(버전+시각)를 함께 저장한다.
  @override
  Future<bool> saveLastAlerted() async {
    final rv = await super.saveLastAlerted();
    final store = versionInfo?.appStoreVersion?.toString();
    if (store != null) {
      _promptedVersion = store;
      _promptedAt = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPromptedVersion, store);
      await prefs.setInt(_kPromptedMs, _promptedAt!.millisecondsSinceEpoch);
    }
    return rv;
  }

  /// QA·디버깅용: 버전 인식 쿨다운 초기화.
  static Future<void> resetCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPromptedVersion);
    await prefs.remove(_kPromptedMs);
  }
}
