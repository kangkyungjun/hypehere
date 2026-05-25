import 'package:flutter/widgets.dart';

const String _separator = '|||';

const Map<String, int> _langIndex = {
  'ko': 0, 'en': 1, 'zh': 2, 'ja': 3, 'es': 4,
};

/// ||| 팩 문자열에서 locale에 맞는 텍스트 추출
String localizePacked(String raw, String languageCode) {
  if (!raw.contains(_separator)) return raw;

  final parts = raw.split(_separator);
  final idx = _langIndex[languageCode];

  // 1) 정확한 locale 매칭
  if (idx != null && idx < parts.length) {
    final v = parts[idx].trim();
    if (v.isNotEmpty) return v;
  }
  // 2) English 폴백
  if (parts.length > 1) {
    final en = parts[1].trim();
    if (en.isNotEmpty) return en;
  }
  // 3) Korean 폴백
  return parts[0].trim();
}

extension MultilingualString on String {
  String localize(String languageCode) => localizePacked(this, languageCode);
}

/// 배열 각 항목을 localize
List<String> localizeList(List<String> items, String languageCode) {
  return items.map((s) => localizePacked(s, languageCode)).toList();
}

/// BuildContext에서 언어 코드 추출 (편의 함수)
String effectiveLanguageCode(BuildContext context) {
  return Localizations.localeOf(context).languageCode;
}
