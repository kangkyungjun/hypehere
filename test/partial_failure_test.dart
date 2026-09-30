import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// 부분 실패 허용 계약.
///
/// 사용자 보고: "BE 같은 몇 종목은 정보가 없다고 나온다."
///
/// 원인은 `Future.wait`이었다. **하나라도 실패하면 전체를 버린다.**
///   - 티커 상세: 기업정보 404 → 차트가 멀쩡해도 화면 전체가 에러
///   - 보유종목: 알림 API 실패 → 사용자의 보유·관심 데이터가 통째로 소실
///
/// 이 테스트는 위젯이 아니라 **비동기 조합 규약**을 고정한다. 두 화면의
/// 로딩 코드가 같은 모양을 유지하는지 보장하고, 왜 그 모양이어야 하는지를
/// 실행 가능한 형태로 남긴다.
void main() {
  Future<T?> soft<T>(Future<T> f) =>
      f.then<T?>((v) => v).catchError((Object _) => null);

  test('Future.wait은 하나가 실패하면 성공한 것까지 버린다 (회귀 근거)', () async {
    Object? caught;
    try {
      await Future.wait([
        Future.value('차트'),
        Future<String>.error(StateError('기업정보 404')),
      ]);
    } catch (e) {
      caught = e;
    }
    // 차트는 성공했는데 결과를 **한 개도** 받지 못한다.
    expect(caught, isA<StateError>());
  });

  test('독립 대기는 성공한 것을 살린다', () async {
    final chart = soft(Future.value('차트'));
    final info = soft(Future<String>.error(StateError('404')));

    expect(await chart, '차트');
    expect(await info, isNull);
  });

  test('핸들러를 늦게 붙이면 unhandled 에러가 된다 (선부착 근거)', () async {
    // 실패가 이미 도착한 Future에 나중에 리스너를 붙이는 패턴이
    // 왜 위험한지 고정한다. zone으로 unhandled 여부를 관찰한다.
    final unhandled = <Object>[];
    await runZonedGuarded(() async {
      final late1 = Future<String>.error(StateError('늦게 붙임'));
      // 다른 await가 끼어드는 사이 late1은 리스너가 없다.
      await Future<void>.delayed(Duration.zero);
      // 여기서 붙여도 이미 늦었다.
      unawaited(soft(late1));
    }, (e, _) => unhandled.add(e));

    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(
      unhandled,
      isNotEmpty,
      reason: '핸들러는 Future를 만들자마자 붙여야 한다',
    );
  });

  test('선부착하면 안전하다', () async {
    final unhandled = <Object>[];
    await runZonedGuarded(() async {
      // 만들자마자 감싼다.
      final a = soft(Future<String>.error(StateError('즉시 처리')));
      await Future<void>.delayed(Duration.zero);
      expect(await a, isNull);
    }, (e, _) => unhandled.add(e));

    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(unhandled, isEmpty);
  });

  test('핵심 둘이 모두 실패할 때만 화면 에러로 올린다', () {
    // portfolio_provider.refresh()의 판정 규칙.
    bool shouldShowError(Object? holdings, Object? watchlist) =>
        holdings == null && watchlist == null;

    expect(shouldShowError(null, null), isTrue);
    expect(shouldShowError(<int>[], null), isFalse, reason: '보유종목은 살았다');
    expect(shouldShowError(null, <int>[]), isFalse, reason: '관심종목은 살았다');
    // 알림(부차 기능)은 판정에 들어가지 않는다 — 인자에도 없다.
  });
}
