import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 언어 설정 관리 Provider
///
/// - null이면 시스템 기본 언어를 따름
/// - SharedPreferences로 사용자 선택 영속화
class LocaleProvider with ChangeNotifier {
  static const String _prefKey = 'app_locale';

  Locale? _locale;

  Locale? get locale => _locale;

  /// 저장된 로케일 로드 (앱 시작 시 호출)
  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey);
    if (code != null) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  /// 로케일 수동 설정
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, locale.languageCode);
    notifyListeners();
  }

  /// 시스템 기본값으로 복원
  Future<void> clearLocale() async {
    _locale = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    notifyListeners();
  }
}
