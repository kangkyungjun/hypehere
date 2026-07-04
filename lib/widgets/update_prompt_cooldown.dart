import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

/// 업데이트 알림(UpgradeAlert) 쿨다운 게이트.
///
/// 배경: `upgrader 13.x`는 사용자가 "나중에" 버튼을 눌렀을 때만
/// `durationUntilAlertAgain` 타이머가 기록된다. 다이얼로그를 외부 탭/뒤로
/// 제스처/X 버튼으로 닫으면 기록이 안 돼서 콜다음 콜드 스타트마다 다시 표시 →
/// "방금 업데이트했는데 또 떠" 호소의 주된 원인.
///
/// 이 위젯은 [UpgradeAlert]를 감싸 **어떤 방식으로 닫히든** 마지막 표시 시각을
/// SharedPreferences에 저장하고, [cooldown] 안이면 다음 콜드 스타트에서
/// [UpgradeAlert]를 건너뛰고 child만 렌더한다.
///
/// 호출자(예: `main.dart`)는 `Upgrader` 인스턴스의 `willDisplayUpgrade` 콜백에
/// [markPrompted]를 연결해야 한다 — 다이얼로그가 표시되는 순간 timestamp 기록.
class UpdatePromptCooldown extends StatefulWidget {
  const UpdatePromptCooldown({
    super.key,
    required this.upgrader,
    required this.child,
    this.cooldown = const Duration(days: 3),
    this.showIgnore = false,
    this.showLater = true,
    this.showReleaseNotes = false,
    this.dialogStyle = UpgradeDialogStyle.material,
  });

  final Upgrader upgrader;
  final Widget child;
  final Duration cooldown;
  final bool showIgnore;
  final bool showLater;
  final bool showReleaseNotes;
  final UpgradeDialogStyle dialogStyle;

  static const String _kLastPromptedMs = 'upgrade_prompt_last_ms';

  /// 다이얼로그가 실제로 표시되는 순간 호출 (Upgrader.willDisplayUpgrade 안에서).
  static Future<void> markPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _kLastPromptedMs,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// QA·디버깅용: 쿨다운 초기화.
  static Future<void> resetCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastPromptedMs);
  }

  @override
  State<UpdatePromptCooldown> createState() => _UpdatePromptCooldownState();
}

class _UpdatePromptCooldownState extends State<UpdatePromptCooldown> {
  /// null = SharedPreferences 로딩 중, true = UpgradeAlert 활성, false = 게이트로 건너뜀.
  bool? _allow;

  @override
  void initState() {
    super.initState();
    _checkCooldown();
  }

  Future<void> _checkCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(UpdatePromptCooldown._kLastPromptedMs);
    bool allow;
    if (last == null) {
      allow = true;
    } else {
      final elapsed = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(last),
      );
      allow = elapsed >= widget.cooldown;
    }
    if (!mounted) return;
    setState(() => _allow = allow);
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중이거나 쿨다운 내면 UpgradeAlert를 아예 빌드하지 않음 — 다이얼로그 표시 X.
    if (_allow != true) return widget.child;
    return UpgradeAlert(
      upgrader: widget.upgrader,
      showIgnore: widget.showIgnore,
      showLater: widget.showLater,
      showReleaseNotes: widget.showReleaseNotes,
      dialogStyle: widget.dialogStyle,
      child: widget.child,
    );
  }
}
