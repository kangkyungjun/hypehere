import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// l10n 커버리지 계약.
///
/// 이번 개편에서 같은 결함을 **세 번** 발견했다 — `showLess`,
/// `explore_screen`의 `'더보기 (n)'`, `ticker_intraday_chart`의 UI 문구 7건.
/// 전부 ko/en만 인라인 처리하거나 키 자체가 없어서 **ja·zh·es 사용자에게
/// 한국어나 영어가 그대로 나가고 있었다.**
///
/// 눈으로는 안 잡힌다(개발자가 ko로만 보므로). 테스트로 못 박는다.
void main() {
  const locales = ['ko', 'en', 'ja', 'zh', 'es'];

  Map<String, dynamic> arb(String lang) =>
      json.decode(File('lib/l10n/app_$lang.arb').readAsStringSync())
          as Map<String, dynamic>;

  test('모든 로케일이 같은 키 집합을 갖는다', () {
    final base = arb('ko').keys.where((k) => !k.startsWith('@')).toSet();

    final problems = <String>[];
    for (final lang in locales.where((l) => l != 'ko')) {
      final keys = arb(lang).keys.where((k) => !k.startsWith('@')).toSet();
      final missing = base.difference(keys);
      final extra = keys.difference(base);
      if (missing.isNotEmpty) {
        problems.add('$lang 누락 ${missing.length}개: '
            '${missing.take(8).join(", ")}');
      }
      if (extra.isNotEmpty) {
        problems.add('$lang 잉여 ${extra.length}개: '
            '${extra.take(8).join(", ")}');
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  /// ⚠️ 위 두 테스트는 **arb 파일만** 본다. 코드에 한글을 직접 박으면
  /// 키 집합은 멀쩡하므로 통과한다 — 실제로 `ticker_intraday_chart`에
  /// `'$dateEt · 미국 장중 09:30~16:00 ET'`가 한 줄 박혀 있었고, 바로 위
  /// 분기는 같은 뜻의 `marketHoursHint`를 쓰고 있었다. **외국인 사용자에게
  /// 한글이 그대로 나갔다.**
  test('사용자 화면 코드에 한글 하드코딩이 없다', () {
    // Master 전용 어드민은 운영자(한국어 사용자) 전용이라 제외한다.
    const exemptDirs = [
      'lib/screens/admin/',
      'lib/l10n/',
      'lib/preview_harness.dart', // 개발 전용 진입점, 배포되지 않는다
    ];
    // Master 게이트(`if (authProvider.isMaster)`) 안의 어드민 진입 메뉴.
    const exemptFiles = ['lib/screens/settings/settings_screen.dart'];

    final hangul = RegExp(r'[가-힣]');
    // Text(...) / label: / title: / hintText: 등 **사용자에게 보이는** 자리.
    final uiString = RegExp(
      r"(Text|label|title|subtitle|message|hintText|labelText|tooltip|content)"
      r"\s*[:(]\s*(const\s+)?(Text\()?'[^']*",
    );

    final offenders = <String>[];
    for (final f in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      if (exemptDirs.any((d) => f.path.startsWith(d))) continue;
      if (exemptFiles.contains(f.path)) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final l = lines[i];
        final t = l.trimLeft();
        if (t.startsWith('//') || t.startsWith('///')) continue;
        if (l.contains('debugPrint')) continue; // 로그는 사용자가 안 본다
        final m = uiString.firstMatch(l);
        if (m != null && hangul.hasMatch(m.group(0)!)) {
          offenders.add('${f.path}:${i + 1}  ${t.length > 90 ? t.substring(0, 90) : t}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'AppLocalizations를 쓸 것 — 외국인 사용자에게 한글이 나간다:\n'
          '${offenders.join("\n")}',
    );
  });

  test('번역이 비어 있거나 한국어 원문 그대로가 아니다', () {
    final ko = arb('ko');
    final hangul = RegExp(r'[가-힣]');

    // 정당한 예외
    const exempt = <String>{
      // 언어 선택 메뉴는 각 언어를 **원어로** 표기한다(한국어/English/日本語…).
      'languageKorean',
      // 문장을 조각내 링크를 끼우는 구조라, 어순에 따라 조각이 빌 수 있다.
      // 예: 일본어는 조사가 뒤에 붙어 접두가 비고 접미에 「に同意します。」가 온다.
      'eulaAgreePrefix', 'eulaAgreeMiddle', 'eulaAgreeAnd', 'eulaAgreeSuffix',
    };

    final problems = <String>[];
    for (final lang in locales.where((l) => l != 'ko')) {
      final m = arb(lang);
      for (final e in m.entries) {
        if (e.key.startsWith('@') || exempt.contains(e.key)) continue;
        final v = e.value;
        if (v is! String) continue;

        if (v.trim().isEmpty) {
          problems.add('$lang.${e.key}: 빈 문자열');
        } else if (hangul.hasMatch(v)) {
          // 한글이 남아 있으면 번역이 안 된 것이다.
          problems.add('$lang.${e.key}: 한글 잔존 "$v"');
        } else if (v == ko[e.key] && hangul.hasMatch('${ko[e.key]}')) {
          problems.add('$lang.${e.key}: ko와 동일');
        }
      }
    }
    expect(problems, isEmpty, reason: problems.take(20).join('\n'));
  });
}
