import 'package:flutter_test/flutter_test.dart';
import 'package:marketlens/models/ticker_change.dart';

/// 티커 변경 맵 해소 계약 (S6).
///
/// 데이터는 2026-10-02에 서버에서 실제로 받은 10건을 그대로 쓴다.
void main() {
  /// `GET /api/v1/tickers/changes` 실제 응답 (2026-10-02, count=10).
  final realResponse = {
    'count': 10,
    'changes': [
      {'old': 'ANSS', 'new': null, 'reason': 'delisted', 'last_traded_date': null, 'detected_at': '2026-10-01T06:52:58'},
      {'old': 'AVB', 'new': null, 'reason': 'delisted', 'last_traded_date': '2026-08-24', 'detected_at': '2026-10-01T06:52:58'},
      {'old': 'BFB', 'new': 'BF-B', 'reason': 'renamed', 'last_traded_date': null, 'detected_at': '2026-10-01T06:52:58'},
      {'old': 'BK', 'new': 'BNY', 'reason': 'renamed', 'last_traded_date': '2026-07-02', 'detected_at': '2026-10-01T06:52:58'},
      {'old': 'BRKB', 'new': 'BRK-B', 'reason': 'renamed', 'last_traded_date': null, 'detected_at': '2026-10-01T06:52:58'},
      {'old': 'CTRA', 'new': null, 'reason': 'delisted', 'last_traded_date': '2026-05-07', 'detected_at': '2026-10-01T06:52:58'},
      {'old': 'EA', 'new': null, 'reason': 'delisted', 'last_traded_date': '2026-08-10', 'detected_at': '2026-10-01T06:52:58'},
      {'old': 'EQR', 'new': null, 'reason': 'delisted', 'last_traded_date': '2026-08-21', 'detected_at': '2026-10-01T06:52:58'},
      {'old': 'HOLX', 'new': null, 'reason': 'delisted', 'last_traded_date': '2026-04-07', 'detected_at': '2026-10-01T06:52:58'},
      {'old': 'SATS', 'new': null, 'reason': 'delisted', 'last_traded_date': '2026-07-02', 'detected_at': '2026-10-01T06:52:58'},
    ],
  };

  group('파싱', () {
    test('실제 응답 10건을 읽는다', () {
      final map = TickerChangeMap.fromJson(realResponse);
      expect(map.length, 10);
      expect(map.isEmpty, isFalse);
    });

    test('모르는 reason은 unknown으로 두고 터지지 않는다', () {
      // 서버가 reason을 enum이 아닌 평문으로 두기로 했다. 새 사유 때문에
      // 파싱이 터지면 변경 맵 **전체**를 못 읽게 된다.
      final map = TickerChangeMap.fromJson({
        'changes': [
          {'old': 'XYZ', 'new': 'ABC', 'reason': 'merged'},
        ],
      });
      final r = map.resolve('XYZ');
      expect(r.reason, TickerChangeReason.unknown);
      expect(r.shouldNotify, isFalse, reason: '모르는 사유로는 아무 말도 하지 않는다');
    });

    test('빈 응답도 읽는다', () {
      expect(TickerChangeMap.fromJson({'changes': []}).isEmpty, isTrue);
      expect(TickerChangeMap.fromJson(const {}).isEmpty, isTrue);
    });
  });

  group('개명 해소', () {
    late TickerChangeMap map;
    setUp(() => map = TickerChangeMap.fromJson(realResponse));

    test('BK → BNY, 사용자에게 알린다', () {
      final r = map.resolve('BK');
      expect(r.ticker, 'BNY');
      expect(r.moved, isTrue);
      expect(r.reason, TickerChangeReason.renamed);
      expect(r.spellingOnly, isFalse);
      expect(r.shouldNotify, isTrue);
      expect(r.change!.lastTradedDate, DateTime(2026, 7, 2));
      expect(r.chain, ['BK', 'BNY']);
    });

    test('BRKB → BRK-B 는 표기 변경 — 조용히 따른다', () {
      // 같은 회사의 같은 주식이고 구분자만 다르다. "종목이 변경되었습니다"로
      // 알리면 사용자는 무슨 일이 일어난 줄 안다.
      final r = map.resolve('BRKB');
      expect(r.ticker, 'BRK-B');
      expect(r.moved, isTrue, reason: '심볼은 바뀐다 — 서버 표기를 따라야 한다');
      expect(r.spellingOnly, isTrue);
      expect(r.shouldNotify, isFalse, reason: '알리지 않는다');
    });

    test('BFB → BF-B 도 표기 변경', () {
      final r = map.resolve('BFB');
      expect(r.ticker, 'BF-B');
      expect(r.spellingOnly, isTrue);
      expect(r.shouldNotify, isFalse);
    });

    test('BRK.B 로 들고 있어도 BRKB 항목을 찾는다', () {
      // 사용자가 야후 표기로 저장했을 수 있다.
      final r = map.resolve('BRK.B');
      expect(r.ticker, 'BRK-B');
      expect(r.spellingOnly, isTrue);
    });

    test('BRK-B 는 자기 자신을 가리키지 않는다', () {
      // ⚠️ 함정: `BRK-B`를 정규화하면 `BRKB`이고, 그게 바로 `BRKB → BRK-B`
      // 항목의 **옛 심볼**이다. 그대로 따라가면 제자리를 돈다.
      final r = map.resolve('BRK-B');
      expect(r.ticker, 'BRK-B');
      expect(r.spellingOnly, isTrue);
      expect(r.shouldNotify, isFalse);
      expect(r.chain.length, lessThanOrEqualTo(2),
          reason: '무한히 길어지면 자기 참조를 못 막은 것이다');
    });
  });

  group('상장폐지', () {
    late TickerChangeMap map;
    setUp(() => map = TickerChangeMap.fromJson(realResponse));

    test('HOLX — 후속 없음, 알린다', () {
      final r = map.resolve('HOLX');
      expect(r.ticker, 'HOLX', reason: '옮겨 갈 곳이 없으므로 심볼은 그대로다');
      expect(r.moved, isFalse);
      expect(r.isDelisted, isTrue);
      expect(r.shouldNotify, isTrue);
      expect(r.change!.lastTradedDate, DateTime(2026, 4, 7));
    });

    test('ANSS — 마지막 거래일이 null이어도 상장폐지로 읽는다', () {
      final r = map.resolve('ANSS');
      expect(r.isDelisted, isTrue);
      expect(r.change!.lastTradedDate, isNull);
      expect(r.shouldNotify, isTrue);
    });

    test('delisted 7건 전부 후속이 없다', () {
      const delisted = ['ANSS', 'AVB', 'CTRA', 'EA', 'EQR', 'HOLX', 'SATS'];
      for (final t in delisted) {
        final r = map.resolve(t);
        expect(r.isDelisted, isTrue, reason: t);
        expect(r.change!.newTicker, isNull, reason: t);
      }
    });
  });

  group('변경 없음', () {
    late TickerChangeMap map;
    setUp(() => map = TickerChangeMap.fromJson(realResponse));

    test('AAPL 은 그대로', () {
      final r = map.resolve('AAPL');
      expect(r.ticker, 'AAPL');
      expect(r.moved, isFalse);
      expect(r.shouldNotify, isFalse);
      expect(r.change, isNull);
      expect(r.chain, ['AAPL']);
    });

    test('소문자·공백도 받는다', () {
      expect(map.resolve('  bk  ').ticker, 'BNY');
      expect(map.resolve('aapl').ticker, 'AAPL');
    });

    test('빈 입력은 그대로', () {
      expect(map.resolve('').ticker, '');
      expect(map.resolve('   ').ticker, '');
    });

    test('빈 맵에서는 아무것도 안 바뀐다', () {
      expect(TickerChangeMap.empty.resolve('BK').ticker, 'BK');
      expect(TickerChangeMap.empty.resolve('BK').shouldNotify, isFalse);
    });
  });

  group('체인과 순환', () {
    test('A → B → C 를 끝까지 따라간다', () {
      final map = TickerChangeMap.fromJson({
        'changes': [
          {'old': 'AAA', 'new': 'BBB', 'reason': 'renamed'},
          {'old': 'BBB', 'new': 'CCC', 'reason': 'renamed'},
        ],
      });
      final r = map.resolve('AAA');
      expect(r.ticker, 'CCC');
      expect(r.chain, ['AAA', 'BBB', 'CCC']);
      expect(r.shouldNotify, isTrue);
    });

    test('A → B, B → A 순환에서 멈춘다', () {
      // 서버가 순환을 막지 않는다. 데이터가 잘못돼도 앱은 멈추지 않아야 한다.
      final map = TickerChangeMap.fromJson({
        'changes': [
          {'old': 'AAA', 'new': 'BBB', 'reason': 'renamed'},
          {'old': 'BBB', 'new': 'AAA', 'reason': 'renamed'},
        ],
      });
      final r = map.resolve('AAA');
      expect(r.chain.length, lessThanOrEqualTo(11));
      expect(r.ticker, isNotEmpty);
    });

    test('renamed 인데 new 가 비면 제자리에 둔다', () {
      // 서버가 422로 막지만 막연히 믿지 않는다.
      final map = TickerChangeMap.fromJson({
        'changes': [
          {'old': 'AAA', 'new': null, 'reason': 'renamed'},
        ],
      });
      final r = map.resolve('AAA');
      expect(r.ticker, 'AAA');
      expect(r.moved, isFalse);
    });
  });
}
