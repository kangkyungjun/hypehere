import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marketlens/utils/ticker_query.dart';

/// 티커 검색어 정규화 계약 + 지수 구성 가정 금지 계약.
///
/// 파이프라인 측 요청(2026-10-01)의 ⑤·② 대응.
void main() {
  group('클래스주 표기 흡수 (⑤)', () {
    test('세 표기가 같은 키로 정규화된다', () {
      for (final v in ['BRK-B', 'BRK.B', 'BRKB', 'brk b', ' brk.b ']) {
        expect(normalizeTicker(v), 'BRKB', reason: v);
      }
      expect(normalizeTicker('BF-B'), 'BFB');
    });

    test('원본을 먼저 시도한다', () {
      // 서버가 이미 정규화를 한다면 첫 질의에서 끝나야 한다.
      expect(tickerQueryVariants('BRK-B').first, 'BRK-B');
      expect(tickerQueryVariants('AAPL').first, 'AAPL');
    });

    test('구분자가 있으면 다른 구분자 표기도 만든다', () {
      final dot = tickerQueryVariants('BRK.B');
      expect(dot, containsAll(['BRK.B', 'BRK-B', 'BRKB']));

      final hyphen = tickerQueryVariants('BRK-B');
      expect(hyphen, containsAll(['BRK-B', 'BRK.B', 'BRKB']));
    });

    test('구분자 없는 4글자는 변형하지 않는다 — 일반 티커와 구분 불가', () {
      // `NVDA`·`TSLA`의 끝 글자를 클래스 문자로 보면
      // `NVD-A`·`TSL-A` 같은 쓰레기 질의가 나간다.
      expect(tickerQueryVariants('AAPL'), ['AAPL']);
      expect(tickerQueryVariants('NVDA'), ['NVDA']);
      expect(tickerQueryVariants('TSLA'), ['TSLA']);
      // `BRKB`도 마찬가지다 — 이 케이스는 서버 정규화(S3)가 맡는다.
      expect(tickerQueryVariants('BRKB'), ['BRKB']);
    });

    test('회사명 검색은 건드리지 않는다', () {
      // 의미 없는 변형 질의로 서버를 두 번 때리지 않는다.
      expect(tickerQueryVariants('애플'), ['애플']);
      expect(tickerQueryVariants('apple inc'), ['apple inc']);
      expect(looksLikeTicker('애플'), isFalse);
      expect(looksLikeTicker('apple inc'), isFalse);
      expect(looksLikeTicker('BRK-B'), isTrue);
    });

    test('빈 입력은 빈 결과', () {
      expect(tickerQueryVariants(''), isEmpty);
      expect(tickerQueryVariants('   '), isEmpty);
    });
  });

  /// ② 지수 구성은 **수시로 바뀐다**. 2026-10-01 기준 503/101/30이고
  /// 파이프라인은 "개수를 코드에 고정하지 말라"고 명시했다.
  ///
  /// 현재 앱은 지수 **코드**(`SP500`·`NASDAQ100`·`DOW30`)만 들고 서버에
  /// 넘기므로 안전하다. 이 테스트는 **그 상태를 유지**시킨다.
  test('지수별 종목 수를 코드에 고정하지 않는다 (②)', () {
    final offenders = <String>[];
    final indexCode = RegExp(r"'(SP500|NASDAQ100|DOW30)'");
    // 지수 코드가 등장하는 줄 ±3줄에 500/100/30이 숫자로 나오면 의심.
    final count = RegExp(r'\b(500|100|30|503|101)\b');

    for (final f in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (!indexCode.hasMatch(lines[i])) continue;
        for (var j = i; j <= i + 3 && j < lines.length; j++) {
          final l = lines[j];
          final t = l.trimLeft();
          if (t.startsWith('//')) continue;
          // 'S&P 500'·'NASDAQ 100' 같은 **라벨 문자열**은 개수 가정이 아니다.
          final withoutLabels =
              l.replaceAll(RegExp(r"'[^']*'"), '').replaceAll('"', '');
          if (count.hasMatch(withoutLabels)) {
            offenders.add('${f.path}:${j + 1}  ${t.length > 80 ? t.substring(0, 80) : t}');
          }
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: '지수 구성은 수시로 바뀐다(현재 503/101/30). 개수를 가정하지 말 것:\n'
          '${offenders.join("\n")}',
    );
  });
}
