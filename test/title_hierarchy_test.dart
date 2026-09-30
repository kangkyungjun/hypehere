import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 제목 체계 계약.
///
/// 개편 전 이 앱에는 제목 스타일이 네 갈래로 갈려 있었다:
/// `AppTypography.sectionTitle` / `cardTitle` / `Theme.of(context).textTheme.title*` /
/// `fontSize:` 하드코딩. 렌더 결과는 같아도 **토큰을 다시 만질 때 절반만
/// 반영되는** 위험이 남는다 — 실제로 스펙 §3과 코드가 한 달간 어긋나 있었다.
///
/// 층위는 **두 개**다:
///   22 `sectionTitle`  — 섹션 제목(카드 **사이**). `SectionHeader`가 담당.
///   18 `cardTitle`     — 카드 제목(카드 **안**).
///
/// 15 `bodyStrong`은 제목이 아니라 카드 안 하위 그룹 라벨이다
/// (`Profitability & Growth`, `섹터 필터`). 제목 층위로 세지 않는다.
void main() {
  Iterable<File> dartFiles(String root) => Directory(root)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  test('textTheme.title* 우회가 없다 — 토큰 단일 체계', () {
    final offenders = <String>[];
    for (final f in dartFiles('lib')) {
      // main.dart는 슬롯을 **정의**하는 곳이라 예외다.
      if (f.path.endsWith('main.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'textTheme\.title(Large|Medium|Small)').hasMatch(lines[i])) {
          offenders.add('${f.path}:${i + 1}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'textTheme 슬롯 대신 AppTypography 프리셋을 쓸 것:\n'
          '  titleLarge → sectionTitle · titleMedium → cardTitle · '
          'titleSmall → bodyStrong\n${offenders.join("\n")}',
    );
  });

  test('MlCardTitle은 제거됐다 — SectionHeader와 역할 중복이었다', () {
    final offenders = <String>[];
    for (final f in dartFiles('lib')) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final l = lines[i];
        if (l.contains('MlCardTitle') && !l.trimLeft().startsWith('//')) {
          offenders.add('${f.path}:${i + 1}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: '확장 카드 헤더는 `SectionHeader(padding: EdgeInsets.zero)`를 쓴다. '
          '둘을 섞으면 같은 화면에서 한 카드만 액센트 바가 빠진다.\n'
          '${offenders.join("\n")}',
    );
  });

  test('제목에 fontSize 하드코딩이 없다', () {
    final offenders = <String>[];
    for (final f in dartFiles('lib')) {
      if (f.path.endsWith('app_typography.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'fontSize:\s*[0-9]').hasMatch(lines[i])) {
          offenders.add('${f.path}:${i + 1}  ${lines[i].trim()}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: '숫자 대신 AppTypography 토큰을 쓸 것:\n${offenders.join("\n")}',
    );
  });
}
